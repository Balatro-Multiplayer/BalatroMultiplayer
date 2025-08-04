local function create_player_info_row(player, player_type, text_scale)
	if not player or not player.username then
		return nil
	end

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
					ref_table = player,
					ref_value = "username",
					shadow = true,
					scale = text_scale * 0.8,
					colour = G.C.UI.TEXT_LIGHT,
				},
			},
			{
				n = G.UIT.B,
				config = {
					w = 0.1,
					h = 0.1,
				},
			},
			player.hash and UIBox_button({
				id = player_type .. "_hash",
				button = "view_" .. player_type .. "_hash",
				label = { player.hash },
				minw = 0.75,
				minh = 0.3,
				scale = 0.25,
				shadow = false,
				colour = G.C.PURPLE,
				col = true,
			}) or nil,
		},
	}
end

function MP.UI.create_players_section(text_scale)
	return {
		n = G.UIT.C,
		config = {
			align = "tm",
			minw = 2.65,
		},
		nodes = {
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
			create_player_info_row(MP.LOBBY.host, "host", text_scale),
			create_player_info_row(MP.LOBBY.guest, "guest", text_scale),
		},
	}
end
