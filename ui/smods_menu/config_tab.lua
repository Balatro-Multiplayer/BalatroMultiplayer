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
		},
	}
	return ret
end
