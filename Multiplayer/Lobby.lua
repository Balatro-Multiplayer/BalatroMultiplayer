--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD LOBBY-------------------------

local Utils = require "Utils"

G.MULTIPLAYER = {}

G.LOBBY = {
	connected = false,
	temp_code = "",
	code = nil,
	type = "",
	config = {},
	username = "Guest",
	host = {},
	guest = {},
	is_host = false,
}

G.MULTIPLAYER_GAME = {
	ready_blind = false,
	ready_blind_text = "Ready",
}

START_NO_ACHIEVEMENT_VALUE = true
local init_mods_ref = initMods
function initMods()
	init_mods_ref()
	START_NO_ACHIEVEMENT_VALUE = G.F_NO_ACHIEVEMENTS
end

function G.MULTIPLAYER.update_connection_status()
	if G.LOBBY.connected then
		-- Disable achievements when connected to server
		G.F_NO_ACHIEVEMENTS = true
	else
		-- Restore them when disconnected
		G.F_NO_ACHIEVEMENTS = START_NO_ACHIEVEMENT_VALUE
	end

	-- Game does not have locatization, and therefore does not support steam_display, status, or text right now, but we can hope
	-- steam_player_group and steam_player_group_size is functional
	if G.LOBBY.code then
		G.STEAM.friends.setRichPresence('steam_display', '#FullStatus')
		G.STEAM.friends.setRichPresence('status', '#FullStatus')
		G.STEAM.friends.setRichPresence('text', 'In Multiplayer Lobby')
		G.STEAM.friends.setRichPresence('steam_player_group', G.LOBBY.code)
		G.STEAM.friends.setRichPresence('steam_player_group_size', G.LOBBY.guest.username and '2' or '1')
	else 
		G.STEAM.friends.setRichPresence('steam_display', '#FullStatus')
		G.STEAM.friends.setRichPresence('status', '#FullStatus')
		G.STEAM.friends.setRichPresence('text', 'Using Multiplayer Mod')
		G.STEAM.friends.setRichPresence('steam_player_group', '')
		G.STEAM.friends.setRichPresence('steam_player_group_size', '')
	end

	if G.HUD_connection_status then
		G.HUD_connection_status:remove()
	end
	G.HUD_connection_status = G.UIDEF.get_connection_status_ui()
end

local gameMainMenuRef = Game.main_menu
---@diagnostic disable-next-line: duplicate-set-field
function Game:main_menu(change_context)
	G.MULTIPLAYER.update_connection_status()
	gameMainMenuRef(self, change_context)
end

function G.FUNCS.copy_to_clipboard(e)
	Utils.copy_to_clipboard(G.LOBBY.code)
end

function G.FUNCS.reconnect(e)
	G.MULTIPLAYER.connect()
	G.FUNCS:exit_overlay_menu()
end

function G.MULTIPLAYER.update_player_usernames()
	if G.LOBBY.code then
		if G.MAIN_MENU_UI then
			G.MAIN_MENU_UI:remove()
		end

		G.FUNCS.display_lobby_main_menu_UI()
	end
end

----------------------------------------------
------------MOD LOBBY END---------------------
