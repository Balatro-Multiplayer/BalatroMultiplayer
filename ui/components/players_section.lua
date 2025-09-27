local function create_player_info_row(player, text_scale)
	if not player or not player.name then return nil end

	return {
		n = G.UIT.R,
		config = {
			padding = 0.1,
			align = "cm",
		},
		nodes = {
			{
				n = G.UIT.T,
				config = {
					text = player.name,
					shadow = true,
					scale = text_scale * 0.8,
					colour = G.C.UI.TEXT_LIGHT,
				},
			},
		},
	}
end

function MP.UI.create_players_section(text_scale)
	local nodes = {
		{
			n = G.UIT.R,
			config = {
				padding = 0.15,
				align = "cm",
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = localize("k_connect_player"),
						shadow = true,
						scale = text_scale * 0.8,
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		},
	}

    if MP.LOBBY.players then
        for _, player_data in ipairs(MP.LOBBY.players) do
            table.insert(nodes, create_player_info_row(player_data, text_scale))
        end
    end

	return {
		n = G.UIT.C,
		config = {
			align = "tm",
			minw = 2.65,
		},
		nodes = nodes,
	}
end