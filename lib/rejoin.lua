-- Rejoin (crash-relaunch resume): fast-forwards through the player's own
-- buffered RLOG events for the still-active run via the same bootstrap/
-- driver machinery "My Replays" uses (lib/playback_launch.lua/
-- lib/playback_handlers.lua), then hands off to live play by rejoining the
-- real lobby instead of ending in a "replay finished" toast. Opponent
-- catch-up (whatever they did while this player was disconnected) is NOT
-- triggered manually here -- it already fires automatically once
-- MPAPI.join_lobby reconnects: the server's grace-period cancel pushes a
-- replay-tail (grace-period.service.ts's pushReplayCatchUp), and
-- pvp_api/reconnect_tail.lua already applies it off that same
-- connection-state event chain, unrelated to this file.
--
-- Takes `active` (MPAPI.replay.get_active_run's own response shape --
-- {runId, lobbyCode, modId, events}) rather than fetching by run_id itself:
-- an ACTIVE run has no DB-persisted matchRunLogs row yet (only written at
-- finalize), so MPAPI.replay.get(run_id) 403s "not a participant" for a
-- genuinely active run's own participant -- confirmed live. `events` is
-- already this player's own buffered stream (server-side getTail against
-- the live in-memory buffer), so no second fetch is needed at all.
function PVP._launch_rejoin(active)
	local conn = MPAPI.get_connection()
	local my_id = conn and conn.player_id

	local manifest = nil
	local timeline = {}
	for _, ev in ipairs(active.events or {}) do
		if ev.opcode == 'manifest' then manifest = ev.args end
		timeline[#timeline + 1] = { t = ev.t, player_id = my_id, opcode = ev.opcode, args = ev.args }
	end
	if not manifest then
		MPAPI.sendWarnMessage('[rejoin] no manifest event in active run ' .. tostring(active.runId))
		return
	end

	PVP._start_playback(manifest, function()
		local driver = MPAPI.playback.new_driver(timeline, {
			mod_id = 'pvp',
			pov_player_id = my_id,
			on_complete = function()
				-- PVP.pvp_join_lobby (not the bare MPAPI.join_lobby primitive):
				-- also runs PVP.setup_lobby_mirror, the same reason
				-- pvp_api/flow.lua's own "Leave Queue & Continue" path re-enters
				-- this function rather than calling MPAPI.join_lobby directly
				-- (see that file's comment) -- needed so PvP's own opponent
				-- mirror/UI wiring is live again, not just the bare MQTT
				-- subscription.
				PVP.pvp_join_lobby(active.lobbyCode)
				local lobby = MPAPI.get_current_lobby()
				-- Opt out of on_lobby_connected's "match formed while practicing,
				-- exit the run" behavior (api/mod_registry/focus.lua) -- we're
				-- reconnecting to the SAME run we just fast-forwarded, not
				-- discovering a new one; must be set before the async connect
				-- callback fires. Confirmed live: without this, rejoin silently
				-- exited the just-restored run back to the main menu.
				if lobby then lobby._skip_run_exit_on_connect = true end
			end,
		})
		driver:finish()
		driver:play()
	end)
end

MPAPI.playback.register_rejoin(PVP.id, PVP._launch_rejoin)
