-- Lobby create/join/start flow + lobby-access enum shared by private lobbies and
-- matchmaking (see queue.lua). All heavy lifting is in the API + PVP's run flow.

PVP.LobbyAccess = {
	PRIVATE = "private",
	PRACTICE = "practice",
	RANKED = "ranked",
	CASUAL = "casual",
	RANKED_PREFIX = "ranked:",
}

-- Host-authored shared lobby metadata. `gamemode`/`ruleset` are MPAPI's own content
-- keys (e.g. "gamemode_mp_attrition" / "ruleset_mp_chocolate_ranked") so MPAPI.ApplyBans/
-- MPAPI.get_active_gamemode() resolve directly to the banned_*-bearing object, no
-- translation needed. `queue_mode` carries the separate API/queue/bridge key (e.g.
-- "pvp_chocolate") that the matchmaking taxonomy, ban_pick draft, and per-lobby
-- MPAPI.GameModes[...] instance (forfeit handling) still need.
function PVP.pvp_lobby_metadata(gamemode_key, kind)
	local def = PVP.PVP_GAMEMODES[gamemode_key] or PVP.PVP_GAMEMODES.pvp_chocolate
	return {
		gamemode = def.gamemode,
		ruleset = def.ruleset,
		queue_mode = gamemode_key,
		kind = kind or PVP.LobbyAccess.PRIVATE,
		deck = PVP.LOBBY.config.back or "Red Deck",
		stake = tostring(PVP.LOBBY.config.stake or 1),
		starting_lives = PVP.LOBBY.config.starting_lives or 4,
		pvp_start_round = PVP.LOBBY.config.pvp_start_round or 2,
	}
end

function PVP.pvp_create_private_lobby(gamemode_key)
	gamemode_key = gamemode_key or PVP.GamemodeKey.PVP_CHOCOLATE
	-- Block creating a lobby while in matchmaking. The replay re-enters THIS
	-- function (not MPAPI.create_lobby) so "Leave Queue & Continue" runs the full
	-- setup -- setup_lobby_mirror + the CONNECTED UI transition below. Replaying
	-- the API primitive would allocate the lobby server-side but leave the client
	-- stranded on the menu.
	if MPAPI.matchmaking.guard_queued(function() return PVP.pvp_create_private_lobby(gamemode_key) end) then
		return
	end
	local gm = MPAPI.GameModes[gamemode_key]
	local max_p = (gm and gm.get_max_players and gm:get_max_players(MPAPI.LobbyType and MPAPI.LobbyType.PRIVATE or "private")) or 2
	local lobby = MPAPI.create_lobby(PVP.id, { max_players = max_p })
	if not lobby then
		sendWarnMessage("pvp_create_private_lobby: failed to create lobby", "MULTIPLAYER")
		return
	end
	PVP._pvp_kind = PVP.LobbyAccess.PRIVATE
	PVP._pvp_gamemode = gamemode_key
	PVP.setup_lobby_mirror(lobby)
	lobby:on(MPAPI.LobbyEvent.CONNECTED, function()
		if lobby.is_host then
			lobby:set_metadata(PVP.pvp_lobby_metadata(gamemode_key, PVP.LobbyAccess.PRIVATE))
		end
		if love and love.system and love.system.setClipboardText then
			pcall(love.system.setClipboardText, lobby.code)
		end
		MPAPI.refresh_current_view()
	end)
end

-- (Ready system + lobby button handlers live in ui/pvp_lobby.lua.)

function PVP.pvp_join_lobby(code)
	if not code or code == "" then
		return
	end
	code = tostring(code):gsub("%s", "")
	-- Block joining while in matchmaking. The replay re-enters THIS function (not
	-- MPAPI.join_lobby) so "Leave Queue & Continue" runs the full setup --
	-- setup_lobby_mirror + its CONNECTED UI transition. Replaying the API
	-- primitive would join server-side (the host sees you) but leave your client
	-- stranded on the PvP menu.
	if MPAPI.matchmaking.guard_queued(function() return PVP.pvp_join_lobby(code) end) then
		return
	end
	local lobby = MPAPI.join_lobby(PVP.id, code)
	if not lobby then
		sendWarnMessage("pvp_join_lobby: failed to join " .. tostring(code), "MULTIPLAYER")
		return
	end
	PVP._pvp_kind = PVP.LobbyAccess.PRIVATE
	PVP.setup_lobby_mirror(lobby)
end

-- Host-only: attach a per-run gamemode instance (for forfeit handling + the API's
-- inert blind hooks) then trigger PVP's run-start, which broadcasts pvp_start_game.
function PVP.pvp_start_match()
	local lobby = MPAPI.get_current_lobby()
	if not lobby or not lobby.is_host then
		return
	end
	if #lobby:get_players() < 2 then
		PVP.UI.UTILS.overlay_message("Waiting for an opponent...")
		return
	end
	local queue_mode = (lobby:get_metadata() or {}).queue_mode or PVP._pvp_gamemode or PVP.GamemodeKey.PVP_CHOCOLATE
	local gm_def = MPAPI.GameModes[queue_mode]
	if gm_def and gm_def.new_instance then
		lobby._gamemode_instance = gm_def:new_instance()
	end
	-- referee_reset runs host-side inside the pvp_start_game handler (loopback).
	PVP.ACTIONS.start_game()
end

-- The single leave-lobby teardown path (the legacy G.FUNCS.lobby_leave was folded in
-- here). Leaves the API lobby and resets the PVP-side state the in-game leave needs:
-- clears modifiers + the version-mismatch latch and returns to the menu. Callers: the
-- lobby view, the shortcuts menu, the end screen, and the join-failure bailout.
function PVP.pvp_leave_lobby()
	local lobby = MPAPI.get_current_lobby()
	if lobby then
		lobby:leave()
	end
	PVP.LOBBY.connected = false
	PVP.LOBBY.code = nil
	PVP.CURRENT_LOBBY = nil
	MPAPI.MODIFIERS = {}
	PVP._version_mismatch_shown = false
	if G.STATE ~= G.STATES.MENU then
		G.STATE = G.STATES.MENU
	end
	if PVP.UI and PVP.UI.update_connection_status then
		PVP.UI.update_connection_status()
	end
end

-- Create-lobby click (main menu). Join / ready / start / leave handlers live in the
-- menu + lobby UI files (ui/pvp_main_menu.lua, ui/pvp_lobby.lua).
G.FUNCS.mp_pvp_create_lobby = function(e)
	PVP.pvp_create_private_lobby(PVP.GamemodeKey.PVP_CHOCOLATE)
end
