-- MPAPI transport for MP.RLOG (lib/replay_log.lua): replaces the legacy
-- Client.send({action="streamLogLines"/"submitLogHashes"}) calls, which
-- pvp_api/net.lua's router now silently drops (both are unlisted there --
-- "owned by the API now, or replay-stream features deferred for the port").
--
-- One event per broadcast, not batched: this is deliberately per-line, not
-- per-25-lines/2-seconds like the old stream, so a spectator (once built) is
-- literally watching each log line arrive as it happens, not a periodic
-- catch-up dump. `args` carries either the positional action-args table (an
-- array, mirrors the local carbon line's own tokens) or, for the reserved
-- framing opcodes "manifest"/"end"/"chk", the frame's own dict payload --
-- MPAPI's action-param validation only checks `type(value) == "table"`, so
-- both shapes satisfy the same schema without a second ActionType.
--
-- on_receive is currently a no-op: the real consumers are the server-side
-- buffering client (buffers for matchRunLogs) and, later, spectators -- a
-- fellow PLAYER's own client has nothing to do with an opponent's replay-log
-- event today. Loaded inside MPAPI.on_loaded (see core.lua's pvp_api load),
-- so this ActionType is tagged to this mod like every other one in pvp_api/.
MP.RLOG_EVENT_ACTION = MPAPI.ActionType({
	key = "game_log_event",
	parameters = {
		{ key = "t", type = "number", required = true },
		{ key = "opcode", type = "string", required = true },
		{ key = "args", type = "table", required = false },
	},
	on_receive = function(_at, from, params) end,
})

-- Normalizes MP.RLOG.record's flexible args shape (nil | scalar | array/dict
-- table) into what game_log_event's `args` param actually needs: nil (omitted
-- entirely, since it's optional) or a table. A bare scalar (e.g. pack_skip's
-- literal `0`) gets wrapped as a single-element array so it still round-trips.
local function normalize_args(args)
	if args == nil then return nil end
	if type(args) == "table" then return args end
	return { args }
end

-- Broadcasts one event live. No-ops cleanly with no lobby (e.g. practice mode,
-- or the headless test harness) -- the local carbon/human text lines this
-- pairs with (lib/replay_log.lua) are unaffected either way.
function MP.RLOG.broadcast_event(t, opcode, args)
	local lobby = MPAPI.get_current_lobby()
	if not lobby then return end
	lobby:action(MP.RLOG_EVENT_ACTION):broadcast({ t = t, opcode = opcode, args = normalize_args(args) })
end
