function G.UIDEF.gamemode_selection_options()
	MP.LOBBY.config.gamemode = "gamemode_mp_attrition"

	local default_gamemode_area = UIBox({
		definition = G.UIDEF.gamemode_info("attrition"),
		config = { align = "cm" },
	})

	local gamemode_buttons_data = {
		{
			name = "k_battle",
			buttons = {
				{ button_id = "attrition_gamemode_button", button_localize_key = "k_attrition" },
				{ button_id = "showdown_gamemode_button", button_localize_key = "k_showdown" },
			},
		},
		{
			name = "k_challenge",
			buttons = {
				{ button_id = "survival_gamemode_button", button_localize_key = "k_survival" },
			},
		},
	}

	return MP.UI.Main_Lobby_Options(
		"gamemode_area",
		default_gamemode_area,
		"change_gamemode_selection",
		gamemode_buttons_data
	)
end

function G.FUNCS.change_gamemode_selection(e)
	MP.UI.Change_Main_Lobby_Options(
		e,
		"gamemode_area",
		G.UIDEF.gamemode_info,
		"attrition_gamemode_button",
		function(gamemode_name)
			MP.LOBBY.config.gamemode = "gamemode_mp_" .. gamemode_name
		end
	)
end

function G.UIDEF.gamemode_info(gamemode_name)
	local gamemode = MP.Gamemodes["gamemode_mp_" .. gamemode_name]

	local gamemode_info_tabs = UIBox({
		definition = G.UIDEF.gamemode_tabs(gamemode),
		config = { align = "cm" },
	})

	return {
		n = G.UIT.ROOT,
		config = { align = "tm", minh = 8, maxh = 8, minw = 11, maxw = 11, colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "tm", padding = 0.2, r = 0.1, colour = G.C.BLACK },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.O, config = { object = gamemode_info_tabs } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{
								n = G.UIT.R,
								config = {
									id = "start_lobby_button",
									button = "start_lobby",
									align = "cm",
									padding = 0.05,
									r = 0.1,
									minw = 8,
									minh = 0.8,
									colour = G.C.BLUE,
									hover = true,
									shadow = true,
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = localize("b_create_lobby"),
											scale = 0.5,
											colour = G.C.UI.TEXT_LIGHT,
										},
									},
								},
							},
						},
					},
				},
			},
		},
	}
end

function G.UIDEF.gamemode_tabs(gamemode)
	local default_tabs = UIBox({
		definition = G.UIDEF.lobby_setup_tabs_definition(gamemode, "info", 1, false),
		config = { align = "cm", tab_type = "info", chosen_tab = 1 },
	})

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.L_BLACK, r = 0.1 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "tm", colour = G.C.GREY, r = 0.1 },
						nodes = {
							{ n = G.UIT.O, config = { object = default_tabs } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "bm", padding = 0.05 },
						nodes = {
							create_option_cycle({
								options = { localize("k_info"), localize("k_bans"), localize("k_reworks") },
								current_option = 1,
								opt_callback = "gamemode_switch_tabs",
								opt_args = { ui = default_tabs, gamemode = gamemode },
								w = 5,
								colour = G.C.ORANGE,
								cycle_shoulders = false,
							}),
						},
					},
				},
			},
		},
	}
end

function G.FUNCS.gamemode_switch_tabs(args)
	if not args or not args.cycle_config then return end
	local callback_args = args.cycle_config.opt_args

	local tabs_object = callback_args.ui
	local tabs_wrap = tabs_object.parent

	local active_tab = tabs_wrap.UIBox:get_UIE_by_ID("gamemode_active_tab")
	local active_tab_idx = active_tab and active_tab.config.tab_idx or 1

	local tab_type = (args.to_key == 2 and "banned") or (args.to_key == 3 and "rework") or "info"
	local def = G.UIDEF.lobby_setup_tabs_definition(callback_args.gamemode, tab_type, active_tab_idx, false)

	tabs_object.config.tab_type = tab_type
	MP.LOBBY.config.gamemode = callback_args.gamemode.key
	MP.LOBBY.gamemode_preview = (tab_type == "rework")

	tabs_wrap.config.object:remove()
	tabs_wrap.config.object = UIBox({
		definition = def,
		config = { align = "cm", parent = tabs_wrap },
	})

	tabs_wrap.UIBox:recalculate()
end

