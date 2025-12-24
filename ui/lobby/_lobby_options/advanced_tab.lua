local function send_lobby_options(value)
	MP.ACTIONS.lobby_options()
end

function G.FUNCS.custom_seed_overlay(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_custom_seed_overlay(),
	})
end

function G.FUNCS.custom_seed_reset(e)
	MP.LOBBY.config.custom_seed = "random"
	send_lobby_options()
end

function toggle_different_seeds()
	G.FUNCS.lobby_options()
	send_lobby_options()
end

function G.FUNCS.display_custom_seed(e)
	local display = MP.LOBBY.config.custom_seed == "random" and localize("k_random") or MP.LOBBY.config.custom_seed
	if display ~= e.children[1].config.text then
		e.children[2].config.text = display
		e.UIBox:recalculate(true)
	end
end

function G.UIDEF.create_UIBox_custom_seed_overlay()
	return create_UIBox_generic_options({
		back_func = "lobby_options",
		contents = {
			{
				n = G.UIT.R,
				config = { align = "cm", colour = G.C.CLEAR },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", minw = 0.1 },
						nodes = {
							create_text_input({
								max_length = 8,
								all_caps = true,
								ref_table = MP.LOBBY,
								ref_value = "temp_seed",
								prompt_text = localize("k_enter_seed"),
								keyboard_offset = 4,
								callback = function(val)
									MP.LOBBY.config.custom_seed = MP.LOBBY.temp_seed
									send_lobby_options()
								end,
							}),
							{
								n = G.UIT.B,
								config = { w = 0.1, h = 0.1 },
							},
							{
								n = G.UIT.T,
								config = {
									scale = 0.3,
									text = localize("k_enter_to_save"),
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					},
				},
			},
		},
	})
end

local function create_custom_seed_section()
	if MP.LOBBY.config.different_seeds then return { n = G.UIT.B, config = { w = 0.1, h = 0.1 } } end

	return {
		n = G.UIT.R,
		config = { padding = 0, align = "cr" },
		nodes = {
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
				},
				nodes = {
					{
						n = G.UIT.C,
						config = {
							padding = 0,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.R,
								config = {
									padding = 0.2,
									align = "cr",
									func = "display_custom_seed",
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											scale = 0.45,
											text = localize("k_current_seed"),
											colour = G.C.UI.TEXT_LIGHT,
										},
									},
									{
										n = G.UIT.T,
										config = {
											scale = 0.45,
											text = MP.LOBBY.config.custom_seed,
											colour = G.C.UI.TEXT_LIGHT,
										},
									},
								},
							},
							{
								n = G.UIT.R,
								config = {
									padding = 0.2,
									align = "cr",
								},
								nodes = {
									MP.UI.Disableable_Button({
										id = "custom_seed_overlay",
										button = "custom_seed_overlay",
										colour = G.C.BLUE,
										minw = 3.65,
										minh = 0.6,
										label = {
											localize("b_set_custom_seed"),
										},
										disabled_text = {
											localize("b_set_custom_seed"),
										},
										scale = 0.45,
										col = true,
										enabled_ref_table = MP.LOBBY,
										enabled_ref_value = "is_host",
									}),
									{
										n = G.UIT.B,
										config = {
											w = 0.1,
											h = 0.1,
										},
									},
									MP.UI.Disableable_Button({
										id = "custom_seed_reset",
										button = "custom_seed_reset",
										colour = G.C.RED,
										minw = 1.65,
										minh = 0.6,
										label = {
											localize("b_reset"),
										},
										disabled_text = {
											localize("b_reset"),
										},
										scale = 0.45,
										col = true,
										enabled_ref_table = MP.LOBBY,
										enabled_ref_value = "is_host",
									}),
								},
							},
						},
					},
				},
			},
		},
	}
end

function MP.UI.create_advanced_options_tab()
	return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 4,
			r = 0.1,
			minw = 10,
			align = "tm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			create_lobby_option_toggle("preview_disabled_toggle", "b_opts_disable_preview", "preview_disabled"),
			create_lobby_option_toggle("order_toggle", "b_opts_the_order", "the_order"),
			MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" and create_lobby_option_toggle(
				"legacy_smallworld_toggle",
				"b_opts_legacy_smallworld",
				"legacy_smallworld"
			) or nil,
			create_lobby_option_toggle(
				"different_seeds_toggle",
				"b_opts_diff_seeds",
				"different_seeds",
				toggle_different_seeds
			),
			create_custom_seed_section(),
		},
	}
end
