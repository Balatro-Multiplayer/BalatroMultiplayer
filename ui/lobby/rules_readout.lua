-- A read-only view of the run configuration shared by host and guest.
-- No editor draft, custom ruleset identity, or extra wire state is needed.
function MP.UI.lobby_rules_lines()
	local config = MP.LOBBY.config
	local short = (config.ruleset or ""):gsub("^ruleset_mp_", "")
	local base_label = short == "experimental" and "k_experimental_standard" or ("k_" .. short)
	local gamemode = (config.gamemode or ""):gsub("^gamemode_mp_", "")
	local lines = {
		"Base: " .. localize(base_label),
		"Gamemode: " .. localize("k_" .. gamemode),
		"MP Jokers + Asteroid: " .. (MP.multiplayer_jokers_enabled() and "On" or "Off"),
		"Lobby timer: " .. (config.timer and "On" or "Off"),
	}
	for _, label in ipairs(MP.UI.selected_modifier_labels()) do
		lines[#lines + 1] = label
	end
	return lines
end

local function rules_definition(lines)
	local columns = {}
	-- Keep the full wall's selections visible without a tall, clipped overlay.
	for i, line in ipairs(lines) do
		local column = math.floor((i - 1) / 12) + 1
		if not columns[column] then
			columns[column] = { n = G.UIT.C, config = { align = "tl", padding = 0.12, minw = 4.8 }, nodes = {} }
		end
		local rows = columns[column].nodes
		rows[#rows + 1] = {
			n = G.UIT.R,
			config = { align = "cl", minh = 0.4, maxw = 4.8 },
			nodes = { { n = G.UIT.T, config = { text = line, scale = 0.32, colour = G.C.UI.TEXT_LIGHT } } },
		}
	end
	return { n = G.UIT.ROOT, config = { align = "cm", colour = G.C.CLEAR }, nodes = columns }
end

-- Rebuild only when the displayed configuration changes. This also handles a
-- host changing an existing lobby option while the guest has View Rules open.
G.FUNCS.mp_lobby_rules_sync = function(e)
	local lines = MP.UI.lobby_rules_lines()
	local signature = table.concat(lines, "\n")
	if e.config.ref_table.signature == signature then return end
	e.config.ref_table.signature = signature
	e.config.object:remove()
	e.config.object = UIBox({
		definition = rules_definition(lines),
		config = { align = "cm", parent = e },
	})
	e.UIBox:recalculate()
end

G.FUNCS.mp_view_lobby_rules = function()
	local lines = MP.UI.lobby_rules_lines()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{
					n = G.UIT.R,
					config = { align = "cm" },
					nodes = {
						{ n = G.UIT.T, config = { text = "View Rules", scale = 0.6, colour = G.C.UI.TEXT_LIGHT } },
					},
				},
				{
					n = G.UIT.R,
					config = { align = "cm" },
					nodes = {
						{
							n = G.UIT.O,
							config = {
								object = UIBox({ definition = rules_definition(lines), config = { align = "cm" } }),
								ref_table = { signature = table.concat(lines, "\n") },
								func = "mp_lobby_rules_sync",
							},
						},
					},
				},
			},
		}),
	})
end
