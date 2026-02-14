function MP.UI.create_credits_tab()
	local scale = 0.75
	return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 6,
			r = 0.1,
			minw = 6,
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			MP.UI.UTILS.create_row({ padding = 0.2, align = "cm" }, {
				MP.UI.UTILS.create_text_node(localize("k_created_by"), {
					scale = scale * 0.8,
					colour = G.C.UI.TEXT_LIGHT,
				}),
				MP.UI.UTILS.create_text_node("Virtualized", {
					scale = scale * 0.8,
					colour = G.C.DARK_EDITION,
				}),
			}),
			MP.UI.UTILS.create_row({ align = "cm", padding = 0 }, {
				MP.UI.UTILS.create_text_node(localize("k_major_contributors"), {
					scale = scale * 0.8,
					colour = G.C.UI.TEXT_LIGHT,
				}),
			}),
			MP.UI.UTILS.create_row({ align = "cm", padding = 0.2 }, {
				MP.UI.UTILS.create_text_node(
					localize({
						type = "variable",
						key = "k_credits_list",
						vars = { "TGMM, Senfinbrare, CUexter, Brawmario, Divvy, Andy, Steph," },
					}),
					{
						scale = scale * 0.8,
						colour = G.C.RED,
					}
				),
			}),
			MP.UI.UTILS.create_row({ align = "cm", padding = 0 }, {
				UIBox_button({
					minw = 3.85,
					button = "bmp_github",
					label = { localize("b_github_project") },
				}),
			}),
			MP.UI.UTILS.create_row({ align = "cm", padding = 0 }, {
				UIBox_button({
					minw = 3.85 * 2,
					button = "bmp_discord",
					label = { localize("b_mp_discord") },
				}),
			}),
		},
	}
end
