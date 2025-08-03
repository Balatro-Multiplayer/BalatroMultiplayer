local Disableable_Button = MP.UI.Disableable_Button

-- Component for main start/ready button in lobby
function MP.UI.create_lobby_main_button(text_scale)
	if MP.LOBBY.is_host then
		return Disableable_Button({
			id = "lobby_menu_start",
			button = "lobby_start_game",
			colour = G.C.BLUE,
			minw = 3.65,
			minh = 1.55,
			label = { localize("b_start") },
			disabled_text = MP.LOBBY.guest.username and localize("b_wait_for_guest_ready")
				or localize("b_wait_for_players"),
			scale = text_scale * 2,
			col = true,
			enabled_ref_table = MP.LOBBY,
			enabled_ref_value = "ready_to_start",
		})
	else
		return UIBox_button({
			id = "lobby_menu_start",
			button = "lobby_ready_up",
			colour = MP.LOBBY.ready_to_start and G.C.GREEN or G.C.RED,
			minw = 3.65,
			minh = 1.55,
			label = { MP.LOBBY.ready_to_start and localize("b_unready") or localize("b_ready") },
			scale = text_scale * 2,
			col = true,
		})
	end
end
