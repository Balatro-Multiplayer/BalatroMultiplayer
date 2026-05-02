function MP.UI.CreateRulesetInfoMenu(config)
	local has_mp_content = config.multiplayer_content and "k_yes" or "k_no"
	local has_mp_color = config.multiplayer_content and G.C.GREEN or G.C.RED
	local forces_lobby = config.forced_lobby_options and "k_yes" or "k_no"
	local forces_lobby_color = config.forced_lobby_options and G.C.GREEN or G.C.RED
	local forces_gamemode_text = config.forced_gamemode_text or "k_no"
	local forces_gamemode_color = config.forced_gamemode_text and G.C.GREEN or G.C.RED

	return {
		{
			n = G.UIT.R,
			config = {
				align = "tm",
			},
			nodes = {
				MP.UI.BackgroundGrouping(localize("k_has_multiplayer_content"), {
					{
						n = G.UIT.T,
						config = {
							text = localize(has_mp_content),
							scale = 0.8,
							colour = has_mp_color,
						},
					},
				}, { col = true, text_scale = 0.6 }),
				{
					n = G.UIT.C,
					config = {
						minw = 0.1,
						minh = 0.1,
					},
				},
				MP.UI.BackgroundGrouping(localize("k_forces_lobby_options"), {
					{
						n = G.UIT.T,
						config = {
							text = localize(forces_lobby),
							scale = 0.8,
							colour = forces_lobby_color,
						},
					},
				}, { col = true, text_scale = 0.6 }),
				{
					n = G.UIT.C,
					config = {
						minw = 0.1,
						minh = 0.1,
					},
				},
				MP.UI.BackgroundGrouping(localize("k_forces_gamemode"), {
					{
						n = G.UIT.T,
						config = {
							text = localize(forces_gamemode_text),
							scale = 0.8,
							colour = forces_gamemode_color,
						},
					},
				}, { col = true, text_scale = 0.6 }),
			},
		},
		{
			n = G.UIT.R,
			config = {
				minw = 0.05,
				minh = 0.05,
			},
		},
		{
			n = G.UIT.R,
			config = {
				align = "cl",
				padding = 0.1,
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = localize(config.description_key),
						scale = 0.6,
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		},
	}
end
