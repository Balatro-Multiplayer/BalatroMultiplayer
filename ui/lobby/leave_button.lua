-- Component for leave button in lobby
function MP.UI.create_lobby_leave_button(text_scale)
	return UIBox_button({
		id = "lobby_menu_leave",
		button = "lobby_leave",
		colour = G.C.RED,
		minw = 3.65,
		minh = 1.55,
		label = { localize("b_leave") },
		scale = text_scale * 1.5,
		col = true,
	})
end
