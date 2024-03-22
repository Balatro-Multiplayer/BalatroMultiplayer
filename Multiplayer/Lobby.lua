--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD LOBBY-------------------------

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
	enemy = {
		score = 0,
		hands = 4,
	},
}

G.MULTIPLAYER_GAME = {
	ready_blind = false,
	ready_blind_text = "Ready",
	processed_round_done = false,
	lives = 3,
}

PREV_ACHIEVEMENT_VALUE = true
function G.MULTIPLAYER.update_connection_status()
	-- Save the previous value of the achievement flag
	PREV_ACHIEVEMENT_VALUE = G.F_NO_ACHIEVEMENTS
	if G.LOBBY.connected and G.LOBBY.code then
		-- Disable achievements when connected to server
		G.F_NO_ACHIEVEMENTS = true
	else
		-- Restore them when disconnected
		G.F_NO_ACHIEVEMENTS = PREV_ACHIEVEMENT_VALUE
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
