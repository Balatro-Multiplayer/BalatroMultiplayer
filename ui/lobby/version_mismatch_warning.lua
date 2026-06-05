function G.FUNCS.mp_open_update_docs(e)
	love.system.openURL("https://balatromp.com/docs/getting-started/installation")
end

function MP.UI.show_version_mismatch_warning(our_version, their_version)
	if MP._version_mismatch_shown then return end

	MP._version_mismatch_shown = true

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			no_back = true,
			contents = {
				MP.UI.UTILS.create_column({ align = "cm", padding = 0.15 }, {
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.1 }, {
						MP.UI.UTILS.create_text_node("VERSION MISMATCH", {
							scale = 0.8,
							colour = G.C.RED,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
						MP.UI.UTILS.create_text_node("You and your opponent are on different", {
							scale = 0.4,
							colour = G.C.UI.TEXT_LIGHT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
						MP.UI.UTILS.create_text_node("Multiplayer versions. Seeds, shops and", {
							scale = 0.4,
							colour = G.C.UI.TEXT_LIGHT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
						MP.UI.UTILS.create_text_node("jokers will desync - matches may break.", {
							scale = 0.4,
							colour = G.C.UI.TEXT_LIGHT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.12 }, {
						MP.UI.UTILS.create_text_node("You: " .. tostring(our_version), {
							scale = 0.45,
							colour = G.C.BLUE,
						}),
						MP.UI.UTILS.create_blank(0.4, 0.1),
						MP.UI.UTILS.create_text_node("Them: " .. tostring(their_version), {
							scale = 0.45,
							colour = G.C.ORANGE,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
						MP.UI.UTILS.create_text_node("Update so you both match before playing.", {
							scale = 0.4,
							colour = G.C.UI.TEXT_LIGHT,
						}),
					}),
					MP.UI.UTILS.create_row({ align = "cm", padding = 0.15 }, {
						UIBox_button({
							label = { "How to update" },
							button = "mp_open_update_docs",
							colour = HEX("72A5F2"),
							minw = 4.2,
							scale = 0.5,
							col = true,
						}),
						MP.UI.UTILS.create_blank(0.25, 0.1),
						UIBox_button({
							label = { "Continue anyway" },
							button = "exit_overlay_menu",
							colour = G.C.RED,
							minw = 3.4,
							scale = 0.5,
							col = true,
						}),
					}),
				}),
			},
		}),
	})
end

-- Detection happens in action_lobbyInfo, but the guest's lobbyInfo can land mid
-- join->menu transition, so show from the update loop once the lobby stage is ready.
local _vmw_update = Game.update
function Game:update(dt)
	_vmw_update(self, dt)
	local m = MP._version_mismatch
	if m and not MP._version_mismatch_shown and MP.LOBBY.code and G.STAGE == G.STAGES.MAIN_MENU then
		MP.UI.show_version_mismatch_warning(m.our, m.their)
	end
end
