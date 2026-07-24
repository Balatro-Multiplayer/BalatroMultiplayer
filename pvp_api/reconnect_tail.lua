-- §22.5: reconnect tail-replay.
--
-- Display-only catch-up for the OPPONENT's HUD state after this client's own
-- network reconnect -- NOT a rebuild of this client's own game state, which
-- is assumed to have stayed intact throughout (a mere MQTT/network drop, not
-- a crash; MPAPI/MQTT-level reconnect already handles that case today). What
-- this covers: while disconnected, this client missed any pvp_log_event
-- broadcasts the opponent sent, so its view of the opponent's score/hands is
-- stale until the opponent's next live sync. The server pushes the missed
-- events over MQTT (player/{id}/replay-tail, see connection.lua's
-- _handle_player_notification) the instant it detects this client is back --
-- no REST pull needed -- and this applies them once it's safe to do so.
--
-- Deliberately NOT routed through the referee/nemesis-blind live-sync
-- pipeline (objects/blinds/nemesis.lua's `receive`) -- that path expects a
-- full sync payload (score, handsLeft, skips, lives together) and is designed
-- for one-shot live transitions; the buffered hand_result carbon event only
-- carries {score, hands_left} (see pvp_api/net.lua). Writes directly to the
-- same PVP.GAME.enemy.* fields `receive` writes instead. skips/lives are a
-- known, accepted gap -- bounded to the grace-period window and
-- self-correcting via the opponent's next live sync (see the design plan).
PVP.RECONNECT_TAIL = PVP.RECONNECT_TAIL or {}

-- Pushed tails received so far, keyed by the opponent player id they belong
-- to -- may arrive before or after the lobby's own player_reconnected event,
-- so this just accumulates until on_checkpoint drains whatever's pending.
PVP.RECONNECT_TAIL._received_tails = PVP.RECONNECT_TAIL._received_tails or {}

-- At most one pending catch-up -- a second reconnect before the first drains
-- just replaces it.
local pending_opponent_id = nil

local function apply_hand_result(ev)
	local args = ev.args or {}
	local score_str, hands_left = args[1], args[2]

	if score_str ~= nil then
		local score = PVP.INSANE_INT.from_string(tostring(score_str))
		-- .score (not just .real_score) is what blind_hud.lua's score_text
		-- actually renders from -- set both so the visible number, not just
		-- comparisons like highest_score, catches up. An instant snap (no
		-- easing event, unlike nemesis.lua's live-sync animation) is fine here:
		-- this is a one-time catch-up after a gap, not an incremental update.
		PVP.GAME.enemy.score = score
		PVP.GAME.enemy.real_score = score
		if PVP.INSANE_INT.greater_than(score, PVP.GAME.enemy.highest_score) then
			PVP.GAME.enemy.highest_score = score
		end
	end

	if hands_left ~= nil then
		PVP.GAME.enemy.hands = tonumber(hands_left) or PVP.GAME.enemy.hands
	end

	-- We've now heard from the opponent (even if only via the buffered tail,
	-- not a live sync) -- unmask their hands/score same as a real receive().
	PVP.GAME.enemy.info_received = true
end

local function apply_tail(opponent_id, events)
	local last_t = PVP.RLOG._last_seen_t[opponent_id] or 0
	for _, ev in ipairs(events or {}) do
		if ev.opcode == "hand_result" then
			apply_hand_result(ev)
		end
		if ev.t and ev.t > last_t then
			last_t = ev.t
		end
	end
	PVP.RLOG._last_seen_t[opponent_id] = last_t
	if PVP.UI and PVP.UI.juice_up_pvp_hud then
		pcall(PVP.UI.juice_up_pvp_hud)
	end
end

-- Called via MPAPI.on_connection_state_change (registered below) the moment
-- the server pushes a §22.5 catch-up over MQTT -- may arrive before or after
-- PLAYER_RECONNECTED, so this only stores; on_checkpoint decides when it's
-- safe to actually apply.
function PVP.RECONNECT_TAIL.receive_pushed_tails(tails)
	for _, tail in ipairs(tails or {}) do
		PVP.RECONNECT_TAIL._received_tails[tail.playerId] = tail.events
	end
end

-- Called from PLAYER_RECONNECTED when THIS client is the one that just
-- reconnected (see pvp_api/lobby_bridge.lua). Never applies inline -- always
-- queues for the next confirmed-safe checkpoint (PVP.RECONNECT_TAIL.on_checkpoint,
-- called from the select_blind/cash_out hooks), since "reconnect just
-- happened" carries no guarantee about what's currently animating on screen.
function PVP.RECONNECT_TAIL.catch_up(opponent_id)
	if not opponent_id then return end
	pending_opponent_id = opponent_id
end

-- Called from the two confirmed-safe checkpoint hooks (select_blind,
-- cash_out -- see ui/game/functions.lua / overrides/game.lua). A third
-- checkpoint ("pack resolved") has no confirmed discrete hook in this repo
-- (base-game Lua, not visible here) -- not added; a mid-pack reconnect simply
-- waits for the next select_blind/cash_out, never applies mid-pack. If the
-- server's push hasn't arrived yet by the time this fires, there's simply
-- nothing to apply this checkpoint -- it's harmless: whatever's missed stays
-- pending in _received_tails until it does arrive (or the next reconnect
-- replaces pending_opponent_id entirely).
function PVP.RECONNECT_TAIL.on_checkpoint()
	if not pending_opponent_id then return end
	local opponent_id = pending_opponent_id
	pending_opponent_id = nil
	local events = PVP.RECONNECT_TAIL._received_tails[opponent_id]
	PVP.RECONNECT_TAIL._received_tails[opponent_id] = nil
	if events then
		apply_tail(opponent_id, events)
	end
end

MPAPI.on_connection_state_change(function(new_state, context)
	if context and context.replay_tail then
		PVP.RECONNECT_TAIL.receive_pushed_tails(context.replay_tail.tails)
	end
end)
