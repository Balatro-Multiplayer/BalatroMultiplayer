function G.FUNCS.mp_open_install_docs(e)
	love.system.openURL("https://balatromp.com/docs/getting-started/installation")
end

function MP.UI.show_dev_build_warning()
	if MP._dev_warning_shown then return end
	if MP.EXPERIMENTAL.suppress_dev_warning then return end

	local version = SMODS.Mods["Multiplayer"].version or ""
	if not version:match("~DEV$") then return end

	MP._dev_warning_shown = true

	G.SETTINGS.paused = true
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			no_back = true,
			no_esc = true,
			contents = {
				MP.UI.UTILS.create_column({ align = "cm", padding = 0.15 }, {
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.1 }, {
						MP.UI.UTILS.create_text_node("MULTIPLAYER", {
							scale = 0.8,
							colour = G.C.UI.TEXT_LIGHT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.05 }, {
						MP.UI.UTILS.create_text_node("Hand of cards, off the workbench - " .. version, {
							scale = 0.55,
							colour = G.C.MULT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
						MP.UI.UTILS.create_text_node("You're playing a dev build - jokers may misbehave.", {
							scale = 0.4,
							colour = G.C.UI.TEXT_LIGHT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
						MP.UI.UTILS.create_text_node("Ranked is locked. You may desync your nemesis.", {
							scale = 0.4,
							colour = G.C.UI.TEXT_LIGHT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
						MP.UI.UTILS.create_text_node("For a clean shuffle, get the launcher below.", {
							scale = 0.4,
							colour = G.C.UI.TEXT_LIGHT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.15 }, {
						UIBox_button({
							label = { "Grab the launcher" },
							button = "mp_open_install_docs",
							colour = HEX("72A5F2"),
							minw = 4.2,
							scale = 0.5,
							col = true,
						}),
						MP.UI.UTILS.create_blank(0.25, 0.1),
						UIBox_button({
							label = { "OK, I'll risk it" },
							button = "exit_overlay_menu",
							colour = G.C.RED,
							minw = 3.2,
							scale = 0.5,
							col = true,
						}),
					}),
				}),
			},
		}),
	})
end
