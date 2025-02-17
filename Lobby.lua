G.LOBBY = {
	connected = false,
	temp_code = "",
	temp_seed = "",
	code = nil,
	type = "",
	config = {
		gold_on_life_loss = true,
		no_gold_on_round_loss = false,
		death_on_round_loss = true,
		different_seeds = false,
		starting_lives = 5,
		showdown_starting_antes = 3,
		gamemode = "attrition",
		custom_seed = "random",
		different_decks = false,
		back = "Red Deck",
		sleeve = "sleeve_casl_none",
		stake = 1,
		multiplayer_jokers = true,
	},
	deck = {
		back = "Red Deck",
		sleeve = "sleeve_casl_none",
		stake = 1,
	},
	username = G.MULTIPLAYER.UTILS.get_username(),
	host = {},
	guest = {},
	is_host = false,
}

G.MULTIPLAYER_GAME = {
	ready_blind = false,
	ready_blind_text = G.localization.misc.dictionary["ready"] or "Ready",
	processed_round_done = false,
	lives = 0,
	loaded_ante = 0,
	loading_blinds = false,
	comeback_bonus_given = true,
	comeback_bonus = 0,
	end_pvp = false,
	enemy = {
		score = 0,
		score_text = "0",
		hands = 4,
		location = "Selecting a Blind",
		skips = 0,
	},
	location = "loc_selecting",
	next_blind_context = nil,
	ante_key = tostring(math.random()),
	antes_keyed = {},
	prevent_eval = false,
}

function reset_game_states()
	sendDebugMessage("Resetting game states", "MULTIPLAYER")
	G.MULTIPLAYER_GAME = {
		ready_blind = false,
		ready_blind_text = G.localization.misc.dictionary["ready"] or "Ready",
		processed_round_done = false,
		lives = 0,
		loaded_ante = 0,
		loading_blinds = false,
		comeback_bonus_given = true,
		comeback_bonus = 0,
		end_pvp = false,
		enemy = {
			score = 0,
			score_text = "0",
			hands = 4,
			location = "Selecting a Blind",
			skips = 0,
		},
		location = "loc_selecting",
		next_blind_context = nil,
		ante_key = tostring(math.random()),
		antes_keyed = {},
		prevent_eval = false,
	}
end

function reset_gamemode_modifiers()
	G.LOBBY.config.starting_lives = G.LOBBY.type == "showdown" and 2 or 5
	G.LOBBY.config.showdown_starting_antes = 3
end

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

	-- Game does not have locatization, and therefore does not support steam_display, status, or text right now, but we can hope
	-- steam_player_group and steam_player_group_size is functional
	--if G.LOBBY.code then
	--	G.STEAM.friends.setRichPresence("steam_display", "#FullStatus")
	--	G.STEAM.friends.setRichPresence("status", "#FullStatus")
	--	G.STEAM.friends.setRichPresence("text", "In Multiplayer Lobby")
	--	G.STEAM.friends.setRichPresence("steam_player_group", G.LOBBY.code)
	--	G.STEAM.friends.setRichPresence("steam_player_group_size", G.LOBBY.guest.username and "2" or "1")
	--else
	--	G.STEAM.friends.setRichPresence("steam_display", "#FullStatus")
	--	G.STEAM.friends.setRichPresence("status", "#FullStatus")
	--	G.STEAM.friends.setRichPresence("text", "Using Multiplayer Mod")
	--	G.STEAM.friends.setRichPresence("steam_player_group", "")
	--	G.STEAM.friends.setRichPresence("steam_player_group_size", "")
	--end

	if G.HUD_connection_status then
		G.HUD_connection_status:remove()
	end
	if G.STAGE == G.STAGES.MAIN_MENU then
		G.HUD_connection_status = G.UIDEF.get_connection_status_ui()
	end
end

local gameMainMenuRef = Game.main_menu
---@diagnostic disable-next-line: duplicate-set-field
function Game:main_menu(change_context)
	G.MULTIPLAYER.update_connection_status()
	gameMainMenuRef(self, change_context)
end

function G.FUNCS.copy_to_clipboard(e)
	G.MULTIPLAYER.UTILS.copy_to_clipboard(G.LOBBY.code)
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

--[[
	There doesn't seem to be any other way to fix the wipe crashes than copying and manipulating the whole function
]]

G.FUNCS.wipe_off = function()
	G.E_MANAGER:add_event(Event({
		no_delete = true,
		func = function()
			delay(0.3)
			if not G.screenwipe then
				return true
			end
			G.screenwipe.children.particles.max = 0
			G.E_MANAGER:add_event(Event({
				trigger = "ease",
				no_delete = true,
				blockable = false,
				blocking = false,
				timer = "REAL",
				ref_table = G.screenwipe.colours.black,
				ref_value = 4,
				ease_to = 0,
				delay = 0.3,
				func = function(t)
					return t
				end,
			}))
			G.E_MANAGER:add_event(Event({
				trigger = "ease",
				no_delete = true,
				blockable = false,
				blocking = false,
				timer = "REAL",
				ref_table = G.screenwipe.colours.white,
				ref_value = 4,
				ease_to = 0,
				delay = 0.3,
				func = function(t)
					return t
				end,
			}))
			return true
		end,
	}))
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.55,
		no_delete = true,
		blocking = false,
		timer = "REAL",
		func = function()
			if not G.screenwipe then
				return true
			end
			if G.screenwipecard then
				G.screenwipecard:start_dissolve({ G.C.BLACK, G.C.ORANGE, G.C.GOLD, G.C.RED })
			end
			if G.screenwipe:get_UIE_by_ID("text") then
				for k, v in ipairs(G.screenwipe:get_UIE_by_ID("text").children) do
					v.children[1].config.object:pop_out(4)
				end
			end
			return true
		end,
	}))
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 1.1,
		no_delete = true,
		blocking = false,
		timer = "REAL",
		func = function()
			if not G.screenwipe then
				return true
			end
			G.screenwipe.children.particles:remove()
			G.screenwipe:remove()
			G.screenwipe.children.particles = nil
			G.screenwipe = nil
			G.screenwipecard = nil
			return true
		end,
	}))
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 1.2,
		no_delete = true,
		blocking = true,
		timer = "REAL",
		func = function()
			return true
		end,
	}))
end
