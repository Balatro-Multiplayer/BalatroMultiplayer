-- Lobby view, copied from the Speedrunning mod's ui/lobby (buttons/view/controls/
-- code/ready) and rewired to PvP. Private lobbies: host gets START + LOBBY OPTIONS,
-- guests get a READY toggle; both get deck/code panels + LEAVE. Matchmaking lobbies:
-- a status panel; the run auto-starts once all clients are ready.

MP.lobby = MP.lobby or { buttons = {} }
MP.lobby.ready = MP.lobby.ready or MPAPI.ReadyTracker()
-- Unanimous seed-change vote tracker (pause menu -> pvp_seed_vote); see pvp_api/run_actions.lua.
MP.lobby.seed_votes = MP.lobby.seed_votes or MPAPI.VoteTracker()

function MP.get_lobby_kind()
	return MP._pvp_kind
end

function MP.is_matchmaking()
	return MP._pvp_kind == MP.LobbyKind.RANKED or MP._pvp_kind == MP.LobbyKind.CASUAL
end

function MP.signal_ready(ready)
	local lobby = MP.lobby.ref
	if not lobby then
		return
	end
	lobby:action(MPAPI.ActionTypes["pvp_player_ready"]):broadcast({ ready = ready and true or false })
end

function MP.start_ready_resync()
	if not MP.is_matchmaking() then
		return
	end
	MP._ready_resync_stop = MPAPI.ready_resync({
		send = function()
			MP.signal_ready(true)
		end,
		should_continue = function()
			return MP.lobby.ref ~= nil and MP.is_matchmaking()
		end,
	})
end

function MP.stop_ready_resync()
	if MP._ready_resync_stop then
		MP._ready_resync_stop()
		MP._ready_resync_stop = nil
	end
end

function MP.reset_ready_state()
	local b = MP.lobby.buttons
	MP.lobby.ready:reset()
	MP.lobby.local_ready = false
	MP.lobby.start_broadcasted = false
	if b.ready_args then
		b.ready_args.label = { localize("b_ready_cap") }
		b.ready_args.colour = G.C.GREEN
	end
	if b.ready then
		b.ready:update()
	end
	if b.start_game then
		b.start_game:update()
	end
end

-- Host-only: record a player's ready state and react.
function MP.set_player_ready(player_id, ready)
	local lobby = MP.lobby.ref
	if not lobby or not lobby.is_host then
		return
	end
	MP.lobby.ready:set(player_id, ready)
	if MP.is_matchmaking() then
		MP.maybe_autostart()
	elseif MP.lobby.buttons.start_game then
		MP.lobby.buttons.start_game:update()
	end
end

-- Host-only matchmaking auto-start: once all clients are ready, start exactly once.
function MP.maybe_autostart()
	local L = MP.lobby
	if L.start_broadcasted or not L.ref or not L.ref.is_host or not MP.is_matchmaking() then
		return
	end
	if #L.ref:get_players() < 2 or not L.ready:all_ready() then
		return
	end
	L.start_broadcasted = true
	MP.pvp_start_match()
end

G.FUNCS.mp_pvp_toggle_ready = function()
	local L = MP.lobby
	L.local_ready = not L.local_ready
	if L.buttons.ready_args and L.buttons.ready then
		L.buttons.ready_args.label = { L.local_ready and localize("b_unready_cap") or localize("b_ready_cap") }
		L.buttons.ready_args.colour = L.local_ready and G.C.ORANGE or G.C.GREEN
		L.buttons.ready:update()
	end
	MP.signal_ready(L.local_ready)
end
