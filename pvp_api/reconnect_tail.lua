-- Phase 9: reconnect tail-replay.
--
-- Display-only catch-up for the OPPONENT's HUD state after this client's own
-- network reconnect -- NOT a rebuild of this client's own game state, which
-- is assumed to have stayed intact throughout (a mere MQTT/network drop, not
-- a crash; MPAPI/MQTT-level reconnect already handles that case today). What
-- this covers: while disconnected, this client missed any game_log_event
-- broadcasts the opponent sent -- MQTT doesn't backlog non-retained topic
-- messages -- so its view of the opponent's score/hands is stale until the
-- opponent's next live sync. This fetches and applies the missed events once
-- it's safe to do so, via MPAPI.replay.get_tail (Phase 9.1) reading the
-- server's live buffer.
--
-- Deliberately NOT routed through the referee/nemesis-blind live-sync
-- pipeline (objects/blinds/nemesis.lua's `receive`) -- that path expects a
-- full sync payload (score, handsLeft, skips, lives together) and is designed
-- for one-shot live transitions; the buffered hand_result carbon event only
-- carries {score, hands_left} (see pvp_api/net.lua). Writes directly to the
-- same MP.GAME.enemy.* fields `receive` writes instead. skips/lives are a
-- known, accepted gap -- bounded to the grace-period window and
-- self-correcting via the opponent's next live sync (see the design plan).
MP.RECONNECT_TAIL = MP.RECONNECT_TAIL or {}

-- At most one pending catch-up -- a second reconnect before the first drains
-- just replaces it; fetch_and_apply always asks since the last APPLIED `t`
-- (MP.RLOG._last_seen_t), so nothing is lost by collapsing to one.
local pending_opponent_id = nil

local function apply_hand_result(ev)
	local args = ev.args or {}
	local score_str, hands_left = args[1], args[2]

	if score_str ~= nil then
		local score = MP.INSANE_INT.from_string(tostring(score_str))
		-- .score (not just .real_score) is what blind_hud.lua's score_text
		-- actually renders from -- set both so the visible number, not just
		-- comparisons like highest_score, catches up. An instant snap (no
		-- easing event, unlike nemesis.lua's live-sync animation) is fine here:
		-- this is a one-time catch-up after a gap, not an incremental update.
		MP.GAME.enemy.score = score
		MP.GAME.enemy.real_score = score
		if MP.INSANE_INT.greater_than(score, MP.GAME.enemy.highest_score) then
			MP.GAME.enemy.highest_score = score
		end
	end

	if hands_left ~= nil then
		MP.GAME.enemy.hands = tonumber(hands_left) or MP.GAME.enemy.hands
	end

	-- We've now heard from the opponent (even if only via the buffered tail,
	-- not a live sync) -- unmask their hands/score same as a real receive().
	MP.GAME.enemy.info_received = true
end

local function apply_tail(opponent_id, events)
	local last_t = MP.RLOG._last_seen_t[opponent_id] or 0
	for _, ev in ipairs(events or {}) do
		if ev.opcode == "hand_result" then
			apply_hand_result(ev)
		end
		if ev.t and ev.t > last_t then
			last_t = ev.t
		end
	end
	MP.RLOG._last_seen_t[opponent_id] = last_t
	if MP.UI and MP.UI.juice_up_pvp_hud then
		pcall(MP.UI.juice_up_pvp_hud)
	end
end

local function fetch_and_apply(opponent_id)
	local since_t = MP.RLOG._last_seen_t[opponent_id] or 0
	MPAPI.replay.get_tail(MP.LOBBY.code, opponent_id, since_t, function(err, data)
		if err or not data or not data.events then
			sendWarnMessage("RECONNECT_TAIL: get_tail failed: " .. tostring(err), "MULTIPLAYER")
			return
		end
		apply_tail(opponent_id, data.events)
	end)
end

-- Called from PLAYER_RECONNECTED when THIS client is the one that just
-- reconnected (see pvp_api/lobby_bridge.lua). Never applies inline -- always
-- queues for the next confirmed-safe checkpoint (MP.RECONNECT_TAIL.on_checkpoint,
-- called from the select_blind/cash_out hooks), since "reconnect just
-- happened" carries no guarantee about what's currently animating on screen.
function MP.RECONNECT_TAIL.catch_up(opponent_id)
	if not opponent_id then return end
	pending_opponent_id = opponent_id
end

-- Called from the two confirmed-safe checkpoint hooks (select_blind,
-- cash_out -- see ui/game/functions.lua / overrides/game.lua). A third
-- checkpoint ("pack resolved") has no confirmed discrete hook in this repo
-- (base-game Lua, not visible here) -- not added; a mid-pack reconnect simply
-- waits for the next select_blind/cash_out, never applies mid-pack.
function MP.RECONNECT_TAIL.on_checkpoint()
	if not pending_opponent_id then return end
	local opponent_id = pending_opponent_id
	pending_opponent_id = nil
	fetch_and_apply(opponent_id)
end
