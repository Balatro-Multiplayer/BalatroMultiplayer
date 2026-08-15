function G.FUNCS.mp_open_update_docs(e)
	love.system.openURL("https://balatromp.com/docs/getting-started/installation")
end

local function build_version_mismatch_modal(mismatches)
	local rows = {
		MP.UI.UTILS.create_row({ align = "cm", padding = 0.1 }, {
			MP.UI.UTILS.create_text_node("VERSION MISMATCH", {
				scale = 0.8,
				colour = G.C.RED,
			}),
		}),
		MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
			MP.UI.UTILS.create_text_node("You and your opponent have mismatched mod", {
				scale = 0.4,
				colour = G.C.UI.TEXT_LIGHT,
			}),
		}),
		MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
			MP.UI.UTILS.create_text_node("versions. Seeds, shops and jokers will", {
				scale = 0.4,
				colour = G.C.UI.TEXT_LIGHT,
			}),
		}),
		MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, {
			MP.UI.UTILS.create_text_node("desync - matches may break.", {
				scale = 0.4,
				colour = G.C.UI.TEXT_LIGHT,
			}),
		}),
	}

	-- One row per mismatched mod: "<Mod> -  You: x   Them: y"
	for _, m in ipairs(mismatches) do
		table.insert(
			rows,
			MP.UI.UTILS.create_row({ align = "cm", padding = 0.1 }, {
				MP.UI.UTILS.create_text_node(m.mod .. " -", {
					scale = 0.4,
					colour = G.C.UI.TEXT_LIGHT,
				}),
				MP.UI.UTILS.create_blank(0.2, 0.1),
				MP.UI.UTILS.create_text_node("You: " .. tostring(m.our), {
					scale = 0.4,
					colour = G.C.BLUE,
				}),
				MP.UI.UTILS.create_blank(0.3, 0.1),
				MP.UI.UTILS.create_text_node("Them: " .. tostring(m.their), {
					scale = 0.4,
					colour = G.C.ORANGE,
				}),
			})
		)
	end

	table.insert(
		rows,
		MP.UI.UTILS.create_row({ align = "cm", padding = 0.12 }, {
			MP.UI.UTILS.create_text_node("Update so you both match before playing.", {
				scale = 0.4,
				colour = G.C.UI.TEXT_LIGHT,
			}),
		})
	)
	table.insert(
		rows,
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
		})
	)

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			no_back = true,
			contents = {
				MP.UI.UTILS.create_column({ align = "cm", padding = 0.15 }, rows),
			},
		}),
	})
end

-- Show the mismatch modal once per lobby (latched on MP._version_mismatch_shown, re-armed on
-- lobby leave / when the mismatch clears). Returns true iff it built the modal this call, which
-- the guest's ready-up uses to intercept the first ready press.
function MP.UI.show_version_mismatch_if_needed()
	if MP._version_mismatch_shown then return false end
	if G.screenwipe or G.OVERLAY_MENU then return false end
	local mismatches = MP.UTILS.version_mismatches()
	if #mismatches == 0 then return false end
	build_version_mismatch_modal(mismatches)
	MP._version_mismatch_shown = true
	return true
end

-- Host trigger: poll while settled in the lobby. (The guest's join transition can't be reliably
-- detected, so the guest triggers off its ready button instead - see lobby.lua:lobby_ready_up.)
local mismatch_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	mismatch_update_ref(self, dt)

	if not MP.LOBBY.code or not MP.LOBBY.is_host then return end
	if G.STAGE ~= G.STAGES.MAIN_MENU then return end
	MP.UI.show_version_mismatch_if_needed()
end
