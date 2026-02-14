local function create_player_info_row(player, player_type, text_scale)
	if not player or not player.username then return nil end

	return MP.UI.UTILS.create_row({ padding = 0.1, align = "cm" }, {
		MP.UI.UTILS.create_text_node(nil, {
			ref_table = player,
			ref_value = "username",
			scale = text_scale * 0.8,
			colour = G.C.UI.TEXT_LIGHT,
		}),
		MP.UI.UTILS.create_blank(0.1, 0.1),
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
	})
end

function MP.UI.create_players_section(text_scale)
	return MP.UI.UTILS.create_column({ align = "tm", minw = 2.65 }, {
		MP.UI.UTILS.create_row({ align = "cm", padding = 0.15 }, {
			MP.UI.UTILS.create_text_node(localize("k_connect_player"), {
				scale = text_scale * 0.8,
				colour = G.C.UI.TEXT_LIGHT,
			}),
		}),
		create_player_info_row(MP.LOBBY.host, "host", text_scale),
		create_player_info_row(MP.LOBBY.guest, "guest", text_scale),
	})
end
