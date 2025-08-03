-- Component for view/copy code buttons in lobby
function MP.UI.create_lobby_code_buttons(text_scale)
	return {
		n = G.UIT.C,
		config = {
			align = "cm",
		},
		nodes = {
			UIBox_button({
				button = "view_code",
				colour = G.C.PALE_GREEN,
				minw = 2.15,
				minh = 0.65,
				label = { localize("b_view_code") },
				scale = text_scale * 1.2,
			}),
			MP.UI.create_spacer(0.1, true),
			UIBox_button({
				button = "copy_to_clipboard",
				colour = G.C.PERISHABLE,
				minw = 2.15,
				minh = 0.65,
				label = { localize("b_copy_code") },
				scale = text_scale,
			}),
		},
	}
end
