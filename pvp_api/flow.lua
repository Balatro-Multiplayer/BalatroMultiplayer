-- Lobby create/join/start flow + lobby-kind enum shared by private lobbies and
-- matchmaking (see queue.lua). All heavy lifting is in the API + MP's run flow.

MP.LobbyKind = {
	PRIVATE = "private",
	PRACTICE = "practice",
	RANKED = "ranked",
	CASUAL = "casual",
	RANKED_PREFIX = "ranked:",
}

-- Host-authored shared lobby metadata. `gamemode`/`ruleset` are MPAPI's own content
-- keys (e.g. "gamemode_mp_attrition" / "ruleset_mp_standard_ranked") so MPAPI.ApplyBans/
-- MPAPI.get_active_gamemode() resolve directly to the banned_*-bearing object, no
-- translation needed. `queue_mode` carries the separate API/queue/bridge key (e.g.
-- "pvp_standard") that the matchmaking taxonomy, ban_pick draft, and per-lobby
-- MPAPI.GameModes[...] instance (forfeit handling) still need.
function MP.pvp_lobby_metadata(gamemode_key, kind)
	local def = MP.PVP_GAMEMODES[gamemode_key] or MP.PVP_GAMEMODES.pvp_standard
	return {
		gamemode = def.gamemode,
		ruleset = def.ruleset,
		queue_mode = gamemode_key,
		kind = kind or MP.LobbyKind.PRIVATE,
		deck = MP.LOBBY.config.back or "Red Deck",
		stake = tostring(MP.LOBBY.config.stake or 1),
		starting_lives = MP.LOBBY.config.starting_lives or 4,
		pvp_start_round = MP.LOBBY.config.pvp_start_round or 2,
		-- reset_lobby_config defaults cocktail to "" (never synced); a lobby created
		-- without ever opening the cocktail edit overlay would otherwise ship an empty
		-- pool to the guest (and to the host's own copy_host_deck at run start) -- fall
		-- back to the host's own saved preference so it always carries a real value.
		cocktail = MP.CocktailConfig.resolve(MP.LOBBY.config.cocktail, MP.config.cocktail),
		sleeve = MP.LOBBY.config.sleeve or "sleeve_casl_none",
		challenge = MP.LOBBY.config.challenge or "",
	}
end

function MP.pvp_create_private_lobby(gamemode_key)
	gamemode_key = gamemode_key or MP.GamemodeKey.PVP_STANDARD
	-- Block creating a lobby while in matchmaking. The replay re-enters THIS
	-- function (not MPAPI.create_lobby) so "Leave Queue & Continue" runs the full
	-- setup -- setup_lobby_mirror + the CONNECTED UI transition below. Replaying
	-- the API primitive would allocate the lobby server-side but leave the client
	-- stranded on the menu.
	if MPAPI.matchmaking.guard_queued(function() return MP.pvp_create_private_lobby(gamemode_key) end) then
		return
	end
	local gm = MPAPI.GameModes[gamemode_key]
	local max_p = (gm and gm.get_max_players and gm:get_max_players(MPAPI.LobbyType and MPAPI.LobbyType.PRIVATE or "private")) or 2
	local lobby = MPAPI.create_lobby(MP.id, { max_players = max_p })
	if not lobby then
		sendWarnMessage("pvp_create_private_lobby: failed to create lobby", "MULTIPLAYER")
		return
	end
	MP._pvp_kind = MP.LobbyKind.PRIVATE
	MP._pvp_gamemode = gamemode_key
	MP.setup_lobby_mirror(lobby)
	lobby:on(MPAPI.LobbyEvent.CONNECTED, function()
		if lobby.is_host then
			lobby:set_metadata(MP.pvp_lobby_metadata(gamemode_key, MP.LobbyKind.PRIVATE))
		end
		if love and love.system and love.system.setClipboardText then
			pcall(love.system.setClipboardText, lobby.code)
		end
		MPAPI.refresh_current_view()
	end)
end

-- (Ready system + lobby button handlers live in ui/pvp_lobby.lua.)

function MP.pvp_join_lobby(code)
	if not code or code == "" then
		return
	end
	code = tostring(code):gsub("%s", "")
	-- Block joining while in matchmaking. The replay re-enters THIS function (not
	-- MPAPI.join_lobby) so "Leave Queue & Continue" runs the full setup --
	-- setup_lobby_mirror + its CONNECTED UI transition. Replaying the API
	-- primitive would join server-side (the host sees you) but leave your client
	-- stranded on the PvP menu.
	if MPAPI.matchmaking.guard_queued(function() return MP.pvp_join_lobby(code) end) then
		return
	end
	local lobby = MPAPI.join_lobby(MP.id, code)
	if not lobby then
		sendWarnMessage("pvp_join_lobby: failed to join " .. tostring(code), "MULTIPLAYER")
		return
	end
	MP._pvp_kind = MP.LobbyKind.PRIVATE
	MP.setup_lobby_mirror(lobby)
end

-- Host-only: attach a per-run gamemode instance (for forfeit handling + the API's
-- inert blind hooks) then trigger MP's run-start, which broadcasts pvp_start_game.
function MP.pvp_start_match()
	local lobby = MPAPI.get_current_lobby()
	if not lobby or not lobby.is_host then
		return
	end
	if #lobby:get_players() < 2 then
		MP.UI.UTILS.overlay_message("Waiting for an opponent...")
		return
	end
	local queue_mode = (lobby:get_metadata() or {}).queue_mode or MP._pvp_gamemode or MP.GamemodeKey.PVP_STANDARD
	local gm_def = MPAPI.GameModes[queue_mode]
	if gm_def and gm_def.new_instance then
		lobby._gamemode_instance = gm_def:new_instance()
	end
	-- referee_reset runs host-side inside the pvp_start_game handler (loopback).
	MP.ACTIONS.start_game()
end

-- The single leave-lobby teardown path (the legacy G.FUNCS.lobby_leave was folded in
-- here). Leaves the API lobby and resets the MP-side state the in-game leave needs:
-- clears modifiers + the version-mismatch latch and returns to the menu. Callers: the
-- lobby view, the shortcuts menu, the end screen, and the join-failure bailout.
function MP.pvp_leave_lobby()
	local lobby = MPAPI.get_current_lobby()
	if lobby then
		lobby:leave()
	end
	MP.LOBBY.connected = false
	MP.LOBBY.code = nil
	MP.CURRENT_LOBBY = nil
	MPAPI.MODIFIERS = {}
	-- Match-scoped cocktail composition must not leak into the next lobby/match.
	MP._match_cocktail = nil
	MP._version_mismatch_shown = false
	if G.STATE ~= G.STATES.MENU then
		G.STATE = G.STATES.MENU
	end
	if MP.UI and MP.UI.update_connection_status then
		MP.UI.update_connection_status()
	end
end

-- Create-lobby click (main menu). Join / ready / start / leave handlers live in the
-- menu + lobby UI files (ui/pvp_main_menu.lua, ui/pvp_lobby.lua).
G.FUNCS.mp_pvp_create_lobby = function(e)
	MP.pvp_create_private_lobby(MP.GamemodeKey.PVP_STANDARD)
end
