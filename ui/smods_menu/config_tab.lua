function MP.UI.create_config_tab()
	local ret = {
		n = G.UIT.ROOT,
		config = {
			r = 0.1,
			minw = 5,
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
            {
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
                    on_demand_tooltip = {
						text = localize("k_automatic_pvp_timer_description"),
					},
				},
				nodes = {
					create_toggle({
						id = "multiplayer_automatic_pvp_timer",
						label = localize("k_automatic_pvp_timer"),
						ref_table = SMODS.Mods["Multiplayer"].config,
						ref_value = "automatic_pvp_timer",
					}),
				},
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
					on_demand_tooltip = {
						text = {
							localize("k_preview_integration_desc"),
							localize("k_preview_credit"),
						},
					},
				},
				nodes = {
					create_toggle({
						id = "fantoms_preview_integration_toggle",
						label = localize("b_preview_integration"),
						ref_table = SMODS.Mods["Multiplayer"].config.integrations,
						ref_value = "Preview",
					}),
				},
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_preview_credit"),
							shadow = true,
							scale = 0.375,
							colour = G.C.UI.TEXT_INACTIVE,
						},
					},
					{
						n = G.UIT.B,
						config = {
							w = 0.1,
							h = 0.1,
						},
					},
					{
						n = G.UIT.T,
						config = {
							text = localize("k_requires_restart"),
							shadow = true,
							scale = 0.375,
							colour = G.C.UI.TEXT_INACTIVE,
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
					on_demand_tooltip = {
						text = {
							localize("k_applies_singleplayer_vanilla_rulesets"),
						},
					},
				},
				nodes = {
					create_toggle({
						id = "singleplayer_hide_content_toggle",
						label = localize("k_hide_mp_content"),
						ref_table = SMODS.Mods["Multiplayer"].config,
						ref_value = "hide_mp_content",
					}),
				},
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0.1,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm" },
						nodes = {
							create_option_cycle({
								label = localize("k_timer_sfx"),
								w = 4,
								scale = 0.8,
								options = localize("ml_mp_timersfx_opt"),
								opt_callback = "mp_change_timersfx",
								current_option = SMODS.Mods["Multiplayer"].config.timersfx or 1,
							}),
						},
					},
				},
			},
            {
				n = G.UIT.R,
				config = {
					padding = 0.1,
					align = "cm",
				},
				nodes = {
					 UIBox_button({
                        button = "mp_open_log_parser",
                        label = { localize("b_open_log_parser") },
                        minw = 3,
                        maxw = 3,
                        minh = 0.8,
                        maxh = 0.8,
                        col = true,
                        colour = G.C.CHIPS,
                    }),
                    UIBox_button({
                        id = "from_game_won",
                        button = "mp_get_lovely_log_file",
                        label = { localize("b_get_log_file") },
                        minw = 3,
                        maxw = 3,
                        minh = 0.8,
                        maxh = 0.8,
                        col = true,
                        colour = G.C.CHIPS,
                    }),
				},
			},
		},
	}
	return ret
end
