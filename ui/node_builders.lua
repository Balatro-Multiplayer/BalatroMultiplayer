PVP.UI.UTILS = {}

-- Creates a text node
function PVP.UI.UTILS.create_text_node(text, config)
	config = config or {}
	config.text = text
	return { n = G.UIT.T, config = config }
end

-- Creates a row container
function PVP.UI.UTILS.create_row(config, nodes)
	config = config or {}
	return { n = G.UIT.R, config = config, nodes = nodes or {} }
end

-- Creates a column container
function PVP.UI.UTILS.create_column(config, nodes)
	config = config or {}
	return { n = G.UIT.C, config = config, nodes = nodes or {} }
end

-- Creates a DynaText object
function PVP.UI.UTILS.create_dynatext(string_or_table, config)
	config = config or {}
	config.string = string_or_table
	return DynaText(config)
end

-- Creates a blank spacer
function PVP.UI.UTILS.create_blank(w, h)
	return { n = G.UIT.B, config = { w = w, h = h } }
end

-- Creates a container with object
function PVP.UI.UTILS.create_object_node(object, config)
	config = config or {}
	config.object = object
	return { n = G.UIT.O, config = config }
end

--- Overlay with a DynaText countdown timer
--- @param message string Static message lines (newline-separated)
--- @param countdown_table table Table with a "display" key that gets updated externally
--- @param no_back boolean If true, disables back/esc buttons
function PVP.UI.UTILS.overlay_message_countdown(message, countdown_table, no_back)
	G.SETTINGS.paused = true
	local message_table = PVP.UTILS.string_split(message, "\n")
	local message_ui = {
		PVP.UI.UTILS.create_row({ align = "cm", padding = 0.2 }, {
			PVP.UI.UTILS.create_text_node("MULTIPLAYER", {
				scale = 0.8,
				colour = G.C.UI.TEXT_LIGHT,
			}),
		}),
	}

	for _, v in ipairs(message_table) do
		table.insert(
			message_ui,
			PVP.UI.UTILS.create_row({ align = "cm", padding = 0.1 }, {
				PVP.UI.UTILS.create_text_node(v, {
					scale = 0.6,
					colour = G.C.UI.TEXT_LIGHT,
				}),
			})
		)
	end

	-- Countdown row using DynaText with ref_table for live updates
	table.insert(
		message_ui,
		PVP.UI.UTILS.create_row({ align = "cm", padding = 0.2 }, {
			PVP.UI.UTILS.create_object_node(DynaText({
				string = { { ref_table = countdown_table, ref_value = "display" } },
				colours = { G.C.UI.TEXT_LIGHT },
				shadow = true,
				silent = true,
				scale = 0.7,
				pop_in = 0,
			})),
		})
	)

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			no_back = no_back,
			no_esc = no_back,
			contents = {
				PVP.UI.UTILS.create_column({ align = "cm", padding = 0.2 }, message_ui),
			},
		}),
	})
end

-- Overlay message function (moved from misc/utils.lua)
function PVP.UI.UTILS.overlay_message(message, no_back)
	G.SETTINGS.paused = true
	local message_table = PVP.UTILS.string_split(message, "\n")
	local message_ui = {
		PVP.UI.UTILS.create_row({ align = "cm", padding = 0.2 }, {
			PVP.UI.UTILS.create_text_node("MULTIPLAYER", {
				scale = 0.8,
				colour = G.C.UI.TEXT_LIGHT,
			}),
		}),
	}

	for _, v in ipairs(message_table) do
		table.insert(
			message_ui,
			PVP.UI.UTILS.create_row({ align = "cm", padding = 0.1 }, {
				PVP.UI.UTILS.create_text_node(v, {
					scale = 0.6,
					colour = G.C.UI.TEXT_LIGHT,
				}),
			})
		)
	end

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			no_back = no_back,
			no_esc = no_back,
			contents = {
				PVP.UI.UTILS.create_column({ align = "cm", padding = 0.2 }, message_ui),
			},
		}),
	})
end
