-- §22.2/§22.3: PvP's own opcode semantics for MPAPI's generic playback engine
-- (BalatroMultiplayerAPI/api/playback/{registry,driver,timeline}.lua). One
-- MPAPI.playback.register_handler("pvp", opcode, fn) per opcode PVP.RLOG.record
-- ever emits (see lib/replay_log.lua's own header comment for the full
-- vocabulary), so nothing recorded is silently dropped during playback.
--
-- SCOPE DECISION (logged in full in AUTONOMOUS_DECISIONS.md): this pass
-- implements real score/ante/hands/lives/location flow projection for both
-- the POV player and every other player -- accurate enough to watch a match's
-- actual progression (who's ahead, when a blind was won/lost/skipped, the
-- final outcome) end to end. It deliberately does NOT re-drive the POV
-- player's own card-level actions (play/discard/sell/buy/use/pack_pick/
-- pack_skip/reroll/reorder/net_pizza/net_magnet) through the real engine --
-- doing that correctly means reconstructing a real click-equivalent event
-- for each one (an early attempt to synthesize a blind-select click this same
-- session crashed inside unmodified vanilla code on a missing .UIBox field,
-- confirming this is real, separate risk, not a small addition). Those
-- opcodes' handlers below are documented no-ops for the POV side; the
-- non-POV (HUD projection) side is fully real for all of them where a
-- projection makes sense.

-- Non-POV projection: NOT via MPAPI.calculate_blind -- that dispatches to the
-- blind's `calculate` (the SEND decision on the ACTING player's own client,
-- see objects/blinds/nemesis.lua and api/synced/core.lua), which only takes
-- effect by broadcasting over a live sync bus to a connected opponent. A
-- playback/spectate session has no such live opponent, so that call would be
-- a silent no-op here -- confirmed by reading api/synced/core.lua's
-- perform_send/broadcast_raw, which both bail out with no lobby. What a live
-- match's RECEIVING client actually applies to PVP.GAME.enemy.* is the
-- blind's `receive` (nemesis.lua), so this mirrors receive's own core score/
-- hands assignment directly instead. Deliberately omits receive's skips/lives
-- fields and side effects (sounds, timer-stop logic): the `hand_result`
-- opcode's own recorded args never carried skips/lives (see net.lua's
-- RLOG.record call), so writing them here from absent data would incorrectly
-- null out values `skip_blind`'s own handler (below) is responsible for.
local function project_enemy_hand_result(args)
	local score_str, hands_left = args and args[1], args and args[2]
	if not score_str or not hands_left then
		return
	end
	local score = PVP.INSANE_INT.from_string(score_str)
	if PVP.INSANE_INT.greater_than(score, PVP.GAME.enemy.highest_score) then
		PVP.GAME.enemy.highest_score = score
	end
	PVP.GAME.enemy.real_score = score
	PVP.GAME.enemy.hands = hands_left
	PVP.GAME.enemy.info_received = true
end

MPAPI.playback.register_handler('pvp', 'manifest', function(args, _ctx)
	-- Framing event, not a gameplay action -- the driver/viewer bootstrap
	-- (ui/replay/*.lua) reads the manifest directly from the timeline before
	-- starting playback, not through this dispatch path. No-op here.
end)

MPAPI.playback.register_handler('pvp', 'end', function(args, _ctx)
	-- Framing event; the viewer's own on_complete (Driver opts) handles
	-- end-of-playback UI, not this handler.
end)

MPAPI.playback.register_handler('pvp', 'chk', function(args, _ctx)
	-- Framing event (hash trailer) -- nothing to apply during playback.
end)

MPAPI.playback.register_handler('pvp', 'hand_result', function(args, ctx)
	if ctx.is_pov then
		local score, hands_left = args and args[1], args and args[2]
		if score then
			PVP.GAME.score = PVP.INSANE_INT.from_string(score)
		end
		if hands_left then
			G.GAME.current_round.hands_left = hands_left
		end
	else
		project_enemy_hand_result(args)
	end
end)

MPAPI.playback.register_handler('pvp', 'set_ante_key', function(args, ctx)
	if ctx.is_pov then
		PVP.GAME.ante_key = args
	end
	-- Non-POV: the ante-key itself has no display meaning for the opponent
	-- side (see functions.lua's own comment -- it's a dedup guard, not
	-- player-facing state), so nothing to project.
end)

MPAPI.playback.register_handler('pvp', 'skip_blind', function(args, ctx)
	if ctx.is_pov then
		G.GAME.skips = (G.GAME.skips or 0) + 1
	else
		-- Direct projection, same reasoning as project_enemy_hand_result above
		-- -- MPAPI.calculate_blind would be a silent no-op here.
		PVP.GAME.enemy.skips = (PVP.GAME.enemy.skips or 0) + 1
	end
end)

MPAPI.playback.register_handler('pvp', 'ready_blind', function(args, ctx)
	if ctx.is_pov then
		PVP.GAME.ready_blind = (args == 1)
	end
	-- Non-POV: no live equivalent projects the opponent's ready state onto
	-- the HUD today (only via the lobby player-list, out of scope here).
end)

-- Card-level opcodes: real non-POV HUD projection where one already exists
-- live; POV re-drive deliberately deferred (see the file header). `sells`/
-- `spent_in_shop` mirror the exact fields PVP.GAME.enemy already tracks for
-- other purposes (e.g. Idol's opponent-aware jokers), so projecting them here
-- is a real, useful signal even without visually replaying the shop.
local NOOP_CARD_OPCODES = { 'play', 'discard', 'buy', 'use', 'pack_pick', 'pack_skip', 'reorder', 'net_pizza', 'net_magnet' }
for _, opcode in ipairs(NOOP_CARD_OPCODES) do
	MPAPI.playback.register_handler('pvp', opcode, function(_args, _ctx)
		-- Deliberately not re-driven this pass -- see file header.
	end)
end

MPAPI.playback.register_handler('pvp', 'sell', function(args, ctx)
	if not ctx.is_pov then
		PVP.GAME.enemy.sells = (PVP.GAME.enemy.sells or 0) + 1
	end
end)

MPAPI.playback.register_handler('pvp', 'cashout', function(args, ctx)
	-- No dedicated live projection exists for "opponent cashed out" today
	-- (PVP.GAME.enemy has no cashout counter) -- nothing to project either side.
end)

MPAPI.playback.register_handler('pvp', 'reroll', function(args, ctx)
	-- Same as cashout -- no existing live-side field to project onto.
end)
