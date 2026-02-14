function G.UIDEF.confirmation_dialog()
	return create_UIBox_generic_options({
		back_func = "options",
		contents = {
			MP.UI.UTILS.create_row({ align = "cm", padding = 0 }, {
				MP.UI.UTILS.create_row({ align = "cm", padding = 0.5 }, {
					MP.UI.UTILS.create_text_node(localize("k_are_you_sure"), {
						scale = 0.6,
						colour = G.C.UI.TEXT_LIGHT,
					}),
				}),
				UIBox_button({
					label = { localize("k_yes") },
					button = "confirmation_dialog_yes",
					minw = 5,
				}),
			}),
		},
	})
end

do
	local confirm_selection_callback = nil

	function G.FUNCS.confirm_selection(callback)
		confirm_selection_callback = callback
		G.FUNCS.overlay_menu({
			definition = G.UIDEF.confirmation_dialog(),
		})
	end

	function G.FUNCS.confirmation_dialog_yes()
		G.FUNCS.exit_overlay_menu()
		if confirm_selection_callback then
			confirm_selection_callback()
			confirm_selection_callback = nil
		end
	end
end
