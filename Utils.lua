G.MULTIPLAYER.UTILS = {}

-- Credit to Henrik Ilgen (https://stackoverflow.com/a/6081639)
function G.MULTIPLAYER.UTILS.serialize_table(val, name, skipnewlines, depth)
	skipnewlines = skipnewlines or false
	depth = depth or 0

	local tmp = string.rep(" ", depth)

	if name then
		tmp = tmp .. name .. " = "
	end

	if type(val) == "table" then
		tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

		for k, v in pairs(val) do
			tmp = tmp
				.. Utils.serialize_table(v, k, skipnewlines, depth + 1)
				.. ","
				.. (not skipnewlines and "\n" or "")
		end

		tmp = tmp .. string.rep(" ", depth) .. "}"
	elseif type(val) == "number" then
		tmp = tmp .. tostring(val)
	elseif type(val) == "string" then
		tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp .. (val and "true" or "false")
	else
		tmp = tmp .. '"[inserializeable datatype:' .. type(val) .. ']"'
	end

	return tmp
end

-- Credit to Steamo (https://github.com/Steamopollys/Steamodded/blob/main/core/core.lua)
function G.MULTIPLAYER.UTILS.wrapText(text, maxChars)
	local wrappedText = ""
	local currentLineLength = 0

	for word in text:gmatch("%S+") do
		if currentLineLength + #word <= maxChars then
			wrappedText = wrappedText .. word .. " "
			currentLineLength = currentLineLength + #word + 1
		else
			wrappedText = wrappedText .. "\n" .. word .. " "
			currentLineLength = #word + 1
		end
	end

	return wrappedText
end

function G.MULTIPLAYER.UTILS.save_username(text)
	G.MULTIPLAYER.set_username(text)
	SMODS.Mods["VirtualizedMultiplayer"].config.username = text
end

function G.MULTIPLAYER.UTILS.get_username()
	return SMODS.Mods["VirtualizedMultiplayer"].config.username
end

function G.MULTIPLAYER.UTILS.string_split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

function G.MULTIPLAYER.UTILS.copy_to_clipboard(text)
	if G.F_LOCAL_CLIPBOARD then
		G.CLIPBOARD = text
	else
		love.system.setClipboardText(text)
	end
end

function G.MULTIPLAYER.UTILS.get_from_clipboard()
	if G.F_LOCAL_CLIPBOARD then
		return G.F_LOCAL_CLIPBOARD
	else
		return love.system.getClipboardText()
	end
end

function G.MULTIPLAYER.UTILS.overlay_message(message)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{
					n = G.UIT.C,
					config = {
						padding = 0.2,
						align = "cm",
					},
					nodes = {
						{
							n = G.UIT.R,
							config = {
								padding = 0.2,
								align = "cm",
							},
							nodes = {
								{
									n = G.UIT.T,
									config = {
										scale = 0.8,
										shadow = true,
										text = "MULTIPLAYER",
										colour = G.C.UI.TEXT_LIGHT,
									},
								},
							},
						},
						{
							n = G.UIT.R,
							config = {
								padding = 0.1,
								align = "cm",
							},
							nodes = {
								{
									n = G.UIT.T,
									config = {
										scale = 0.6,
										shadow = true,
										text = message,
										colour = G.C.UI.TEXT_LIGHT,
									},
								},
							},
						},
					},
				},
			},
		}),
	})
end

function G.MULTIPLAYER.UTILS.get_joker(key)
	if not G.jokers then
		return nil
	end
	for i = 1, #G.jokers.cards do
		if G.jokers.cards[i].ability.name == key then
			return G.jokers.cards[i]
		end
	end
	return nil
end

function G.MULTIPLAYER.UTILS.get_non_phantom_jokers()
	if not G.jokers or not G.jokers.cards then
		return {}
	end
	local jokers = {}
	for _, v in ipairs(G.jokers.cards) do
		if v.ability.set == "Joker" and (not v.edition or v.edition.type ~= "mp_phantom") then
			table.insert(jokers, v)
		end
	end
	return jokers
end
