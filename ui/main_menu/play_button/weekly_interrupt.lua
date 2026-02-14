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

