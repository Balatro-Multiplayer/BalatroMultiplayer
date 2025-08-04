-- Utility functions for UI components

function MP.UI.create_spacer(size, row)
	size = size or 0.2

	return row and {
		n = G.UIT.R,
		config = {
			align = "cm",
			minh = size,
		},
		nodes = {},
	} or {
		n = row and G.UIT.R or G.UIT.C,
		config = {
			align = "cm",
			minw = size,
		},
		nodes = {},
	}
end

function MP.UI.confirmation_dialog(callback)
        G._confirm_callback = callback
        G.FUNCS.overlay_menu({
                definition = create_UIBox_generic_options({
                        no_back = true,
                        contents = {
                                {
                                        n = G.UIT.C,
                                        config = {
                                                align = "cm",
                                                padding = 0.2,
                                                minw = 6,
                                                minh = 3,
                                        },
                                        nodes = {
                                                {
                                                        n = G.UIT.T,
                                                        config = {
                                                                text = localize("k_are_you_sure"),
                                                                scale = 0.6,
                                                                shadow = true,
                                                                colour = G.C.UI.TEXT_LIGHT,
                                                        },
                                                },
                                                {
                                                        n = G.UIT.B,
                                                        config = { align = "cm", padding = 0.1 },
                                                        nodes = {
                                                                UIBox_button({ label = { localize("k_yes") }, button = "generic_confirm_yes", minw = 2.5 }),
                                                                UIBox_button({ label = { localize("k_no") }, button = "exit_overlay_menu", minw = 2.5 }),
                                                        },
                                                },
                                        },
                                },
                        },
                }),
        })
end


function G.FUNCS.confirm_selection(callback)
       G._confirm_callback = callback
       G.FUNCS.overlay_menu({
               definition = MP.UI.confirmation_dialog(),
       })
end

function G.FUNCS.confirmation_yes()
        G.FUNCS.exit_overlay_menu()
        if G._confirm_callback then
                G._confirm_callback()
                G._confirm_callback = nil
        end
end