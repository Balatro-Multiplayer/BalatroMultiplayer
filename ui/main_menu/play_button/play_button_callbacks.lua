-- Singleplayer ruleset state (parallels MP.LOBBY.config.ruleset for multiplayer)
MP.SP = { ruleset = nil }

function G.FUNCS.setup_run_singleplayer(e)
	G.SETTINGS.paused = true
	MP.LOBBY.config.ruleset = nil
	MP.LOBBY.config.gamemode = nil
	MP.SP.ruleset = nil

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_options("sp"),
	})
end

function G.FUNCS.start_sp_run(e)
	G.FUNCS.exit_overlay_menu()
	G.FUNCS.setup_run(e)
end

function G.FUNCS.start_vanilla_sp(e)
	MP.LOBBY.config.ruleset = nil
	MP.LOBBY.config.gamemode = nil
	MP.SP.ruleset = nil
	G.FUNCS.setup_run(e)
end

function G.FUNCS.play_options(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.override_main_menu_play_button(),
	})
end

function G.FUNCS.create_lobby(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_options("mp"),
	})
end

function G.FUNCS.select_gamemode(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.gamemode_selection_options(),
	})
end

function G.FUNCS.join_lobby(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_join_lobby_button(),
	})
	local text_input = G.OVERLAY_MENU:get_UIE_by_ID("text_input")
	G.FUNCS.select_text_input(text_input)
end

function G.FUNCS.weekly_interrupt(e)
	if (not MP.LOBBY.config.weekly) or (MP.LOBBY.config.weekly ~= MP.LOBBY.fetched_weekly) then
		G.SETTINGS.paused = true

		G.FUNCS.overlay_menu({
			definition = G.UIDEF.weekly_interrupt(not not MP.LOBBY.config.weekly),
		})
		return true
	end
	return false
end

function G.FUNCS.set_weekly(e)
	SMODS.Mods["Multiplayer"].config.weekly = MP.LOBBY.fetched_weekly
	SMODS.save_mod_config(SMODS.Mods["Multiplayer"])
	SMODS.restart_game() -- idk if this works well...
end

function G.FUNCS.skip_tutorial(e)
	G.SETTINGS.tutorial_complete = true
	G.SETTINGS.tutorial_progress = nil
	G.FUNCS.play_options(e)
end

function G.FUNCS.join_from_clipboard(e)
	local paste = MP.UTILS.get_from_clipboard()
	if not paste then return end
	MP.LOBBY.temp_code = string.sub(string.upper(paste:gsub("[^%a]", "")), 1, 5) -- cursed
	MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
end

function G.FUNCS.start_lobby(e)
	G.SETTINGS.paused = false

	MP.reset_lobby_config(true)

	MP.LOBBY.config.multiplayer_jokers = MP.Rulesets[MP.LOBBY.config.ruleset].multiplayer_content

	MP.LOBBY.config.forced_config = MP.Rulesets[MP.LOBBY.config.ruleset].force_lobby_options()

	if MP.LOBBY.config.gamemode == "gamemode_mp_survival" then
		MP.LOBBY.config.starting_lives = 1
		MP.LOBBY.config.disable_live_and_timer_hud = true
	else
		MP.LOBBY.config.disable_live_and_timer_hud = false
	end

	-- Check if the current gamemode is valid. If it's not, default to attrition.
	local gamemode_check = false
	for k, _ in pairs(MP.Gamemodes) do
		if k == MP.LOBBY.config.gamemode then gamemode_check = true end
	end
	MP.LOBBY.config.gamemode = gamemode_check and MP.LOBBY.config.gamemode or "gamemode_mp_attrition"

	MP.LOBBY.config.cocktail = SMODS.Mods["Multiplayer"].config.cocktail

	MP.ACTIONS.create_lobby(string.sub(MP.LOBBY.config.gamemode, 13))
	G.FUNCS.exit_overlay_menu()
end

function G.FUNCS.join_game_submit(e)
	G.FUNCS.exit_overlay_menu()
	MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
end

function G.FUNCS.join_game_paste(e)
	MP.LOBBY.temp_code = MP.UTILS.get_from_clipboard()
	MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
	G.FUNCS.exit_overlay_menu()
end

-- Creating forced gamemode buttons for each gamemode, since I am not sure how to pass variables through button presses
for gamemode, _ in pairs(MP.Gamemodes) do
	G.FUNCS["force_" .. gamemode] = function(e)
		MP.LOBBY.config.gamemode = gamemode
		G.FUNCS.start_lobby(e)
	end
end
