function G.UIDEF.create_UIBox_join_lobby_button()
	return (
		create_UIBox_generic_options({
			back_func = "play_options",
			contents = {
				{
					n = G.UIT.R,
					config = {
						padding = 0,
						align = "cm",
					},
					nodes = {
						{
							n = G.UIT.R,
							config = {
								padding = 0.5,
								align = "cm",
							},
							nodes = {
								create_text_input({
									w = 4,
									h = 1,
									max_length = 5,
									all_caps = true,
									prompt_text = localize("k_enter_lobby_code"),
									ref_table = MP.LOBBY,
									ref_value = "temp_code",
									extended_corpus = false,
									keyboard_offset = 1,
									keyboard_offset = 4,
									minw = 5,
									callback = function(val)
										MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
									end,
								}),
							},
						},
					},
				},
			},
		})
	)
end

function G.UIDEF.override_main_menu_play_button()
	if not G.SETTINGS.tutorial_complete or G.SETTINGS.tutorial_progress ~= nil then
		return (
			create_UIBox_generic_options({
				contents = {
					UIBox_button({
						label = { localize("b_singleplayer") },
						colour = G.C.BLUE,
						button = "setup_run_singleplayer",
						minw = 5,
					}),
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.5,
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = localize("k_tutorial_not_complete"),
									colour = G.C.UI.TEXT_LIGHT,
									scale = 0.45,
								},
							},
						},
					},
					UIBox_button({
						label = { localize("b_skip_tutorial") },
						colour = G.C.RED,
						button = "skip_tutorial",
						minw = 5,
					}),
				},
			})
		)
	end

	return (
		create_UIBox_generic_options({
			contents = {
				UIBox_button({
					label = { localize("b_singleplayer") },
					colour = G.C.BLUE,
					button = "setup_run_singleplayer",
					minw = 5,
				}),
				MP.LOBBY.connected and UIBox_button({
					label = { localize("b_create_lobby") },
					colour = G.C.GREEN,
					button = "create_lobby",
					minw = 5,
				}) or nil,
				MP.LOBBY.connected and UIBox_button({
					label = { localize("b_join_lobby") },
					colour = G.C.RED,
					button = "join_lobby",
					minw = 5,
					minh = 0.7,
				}) or nil,
				MP.LOBBY.connected and UIBox_button({
					label = { localize("b_join_lobby_clipboard") },
					colour = G.C.PURPLE,
					button = "join_from_clipboard",
					minw = 5,
					minh = 0.7,
				}) or nil,
				not MP.LOBBY.connected and UIBox_button({
					label = { localize("b_reconnect") },
					colour = G.C.RED,
					button = "reconnect",
					minw = 5,
				}) or nil,
			},
		})
	)
end

function G.UIDEF.weekly_interrupt(loaded)
	return (
		create_UIBox_generic_options({
			back_func = "create_lobby",
			contents = {
				{
					n = G.UIT.R,
					config = {
						align = "cm",
						padding = 0.1,
					},
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = "A new weekly ruleset is available!",
								colour = G.C.UI.TEXT_LIGHT,
								scale = 0.45,
							},
						},
					},
				},
				{
					n = G.UIT.R,
					config = {
						align = "cm",
						padding = 0.2,
					},
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_currently_colon")
									.. localize("k_weekly_" .. MP.LOBBY.fetched_weekly), -- bad loc but ok
								colour = darken(G.C.UI.TEXT_LIGHT, 0.2),
								scale = 0.35,
							},
						},
					},
				},
				UIBox_button({
					label = { localize("k_sync_locally") },
					colour = G.C.DARK_EDITION,
					button = "set_weekly",
					minw = 5,
				}),
			},
		})
	)
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
		definition = G.UIDEF.ruleset_selection_options(),
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
	MP.LOBBY.temp_code = string.sub(string.upper(paste:gsub("[^%a]", "")), 1, 5) -- cursed
	MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
end

-- Modify play button to take you to mode select first
local create_UIBox_main_menu_buttonsRef = create_UIBox_main_menu_buttons
---@diagnostic disable-next-line: lowercase-global
function create_UIBox_main_menu_buttons()
	local menu = create_UIBox_main_menu_buttonsRef()
	menu.nodes[1].nodes[1].nodes[1].nodes[1].config.button = "play_options"
	return menu
end
