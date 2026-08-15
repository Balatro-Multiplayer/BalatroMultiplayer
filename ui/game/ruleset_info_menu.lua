-- Render a localized string with {C:colour}...{} tags and \n line breaks as a
-- stack of UIT rows. loc_parse_string returns nil on empty input, so blank
-- lines are emitted as spacers without going through it.
local function parse_colored_lines(str, scale)
	scale = scale or 0.6
	local rows = {}
	for line in (str .. "\n"):gmatch("(.-)\n") do
		if line == "" then
			rows[#rows + 1] = { n = G.UIT.R, config = { minh = 0.15 } }
		else
			local segments = {}
			for _, seg in ipairs(loc_parse_string(line)) do
				local text = seg.strings[1]
				if type(text) == "string" and text ~= "" then
					segments[#segments + 1] = {
						n = G.UIT.T,
						config = {
							text = text,
							scale = scale,
							colour = loc_colour(seg.control.C, G.C.UI.TEXT_LIGHT),
						},
					}
				end
			end
			rows[#rows + 1] = { n = G.UIT.R, config = { align = "cl" }, nodes = segments }
		end
	end
	return rows
end

function MP.UI.CreateRulesetInfoMenu(config)
	local has_mp_content = config.multiplayer_content and "k_yes" or "k_no"
	local has_mp_color = config.multiplayer_content and G.C.GREEN or G.C.RED
	local forces_lobby = config.forced_lobby_options and "k_yes" or "k_no"
	local forces_lobby_color = config.forced_lobby_options and G.C.GREEN or G.C.RED
	local forces_gamemode_text = config.forced_gamemode_text or "k_no"
	local forces_gamemode_color = config.forced_gamemode_text and G.C.GREEN or G.C.RED

	local rows = {
		{
			n = G.UIT.R,
			config = {
				align = "tm",
			},
			nodes = {
				MP.UI.BackgroundGrouping(localize("k_has_multiplayer_content"), {
					{
						n = G.UIT.T,
						config = {
							text = localize(has_mp_content),
							scale = 0.8,
							colour = has_mp_color,
						},
					},
				}, { col = true, text_scale = 0.6 }),
				{
					n = G.UIT.C,
					config = {
						minw = 0.1,
						minh = 0.1,
					},
				},
				MP.UI.BackgroundGrouping(localize("k_forces_lobby_options"), {
					{
						n = G.UIT.T,
						config = {
							text = localize(forces_lobby),
							scale = 0.8,
							colour = forces_lobby_color,
						},
					},
				}, { col = true, text_scale = 0.6 }),
				{
					n = G.UIT.C,
					config = {
						minw = 0.1,
						minh = 0.1,
					},
				},
				MP.UI.BackgroundGrouping(localize("k_forces_gamemode"), {
					{
						n = G.UIT.T,
						config = {
							text = localize(forces_gamemode_text),
							scale = 0.8,
							colour = forces_gamemode_color,
						},
					},
				}, { col = true, text_scale = 0.6 }),
			},
		},
		{
			n = G.UIT.R,
			config = {
				minw = 0.05,
				minh = 0.05,
			},
		},
	}

	rows[#rows + 1] = {
		n = G.UIT.R,
		config = {
			align = "cl",
			padding = 0.1,
		},
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cl" },
				nodes = parse_colored_lines(localize(config.description_key), 0.6),
			},
		},
	}

	if config.stickers and #config.stickers > 0 then
		local sticker_nodes = {}
		for _, key in ipairs(config.stickers) do
			local sticker_obj = SMODS.Stickers and SMODS.Stickers["mp_sticker_" .. key]
			if sticker_obj then
				local atlas = G.ASSET_ATLAS[sticker_obj.atlas]
				if atlas then
					local sprite = Sprite(0, 0, 0.55, 0.74, atlas, sticker_obj.pos or { x = 0, y = 0 })
					sticker_nodes[#sticker_nodes + 1] = {
						n = G.UIT.C,
						config = { align = "cm", padding = 0.05 },
						nodes = {
							{
								n = G.UIT.R,
								config = { align = "cm" },
								nodes = { { n = G.UIT.O, config = { object = sprite } } },
							},
							{
								n = G.UIT.R,
								config = { align = "cm", padding = 0.02 },
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = localize{ type = "name_text", set = "Other", key = "mp_sticker_" .. key },
											scale = 0.3,
											colour = sticker_obj.badge_colour or G.C.UI.TEXT_LIGHT,
										},
									},
								},
							},
						},
					}
				end
			end
		end
		if #sticker_nodes > 0 then
			rows[#rows + 1] = {
				n = G.UIT.R,
				config = { align = "cr" },
				nodes = {
					MP.UI.BackgroundGrouping(localize("k_may_roll_stickers"), {
						{ n = G.UIT.R, config = { align = "cm" }, nodes = sticker_nodes },
					}, { text_scale = 0.4 }),
				},
			}
		end
	end

	return rows
end
