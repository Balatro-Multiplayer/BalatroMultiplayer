MP.load_mp_dir("ui/main_menu") -- while we extract stuff

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

MP.SP = {}
function G.FUNCS.setup_run_singleplayer(e)
	G.SETTINGS.paused = true
	MP.LOBBY.config.ruleset = nil
	MP.SP.ruleset = nil
	-- MP.SP.ruleset = "ruleset_mp_smallworld"
	MP.LOBBY.config.gamemode = nil

	G.SETTINGS.paused = true
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.sp_ruleset_selection_options(),
	})
	-- TODO i think this will come later ackshually!!
	-- G.FUNCS.setup_run(e)
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

-- Modify play button to take you to mode select first
local create_UIBox_main_menu_buttonsRef = create_UIBox_main_menu_buttons
---@diagnostic disable-next-line: lowercase-global
function create_UIBox_main_menu_buttons()
	local menu = create_UIBox_main_menu_buttonsRef()
	menu.nodes[1].nodes[1].nodes[1].nodes[1].config.button = "play_options"
	return menu
end

G.FUNCS.wipe_off = function()
	G.E_MANAGER:add_event(Event({
		no_delete = true,
		func = function()
			delay(0.3)
			if not G.screenwipe then return true end
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
			if not G.screenwipe then return true end
			if G.screenwipecard then G.screenwipecard:start_dissolve({ G.C.BLACK, G.C.ORANGE, G.C.GOLD, G.C.RED }) end
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
			if not G.screenwipe then return true end
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
