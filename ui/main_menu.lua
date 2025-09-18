MP.load_mp_dir("ui/main_menu") -- while we extract stuff

-- TODO: extracted some gnarly business logic here that doesn't belong in UI layer
-- this stuff actually configures game state and starts lobbies
-- should prob live in lobby_setup.lua or something, these are just bridges from button clicks

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
