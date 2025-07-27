local function create_main_lobby_options_title(info_area_id)
	local title_colour = mix_colours(G.C.RED, G.C.BLACK, 0.6)
	local title = "ERROR"

	if info_area_id == "ruleset_area" then
		title_colour = mix_colours(G.C.BLUE, G.C.BLACK, 0.6)
		title = localize("k_rulesets")
	end

	if info_area_id == "gamemode_area" then
		title_colour = mix_colours(G.C.ORANGE, G.C.BLACK, 0.6)
		title = localize("k_gamemodes")
	end

	if title == "ERROR" then
		return nil
	end

	return {
		n = G.UIT.R,
		config = { id = 'ruleset_name', align = "cm", padding = 0.07 },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", r = 0.1, outline = 1, outline_colour = title_colour, colour = darken(title_colour, 0.3), minw = 2.9, emboss = 0.1, padding = 0.07, line_emboss = 1 },
				nodes = {
					{ n = G.UIT.O, config = { object = DynaText({ string = title, colours = { G.C.WHITE }, shadow = true, float = true, y_offset = -4, scale = 0.45, maxw = 2.8 }) } },
				}
			},
		}
	}
end

function MP.UI.Main_Lobby_Options(info_area_id, default_info_area, button_func, buttons_data)
	local buttons = {
		create_main_lobby_options_title(info_area_id)
	}
	for idx, data in ipairs(buttons_data) do
		local col = data.button_col or G.C.RED
		if data.button_id == "weekly_ruleset_button" then -- putting the logic here because whatever
			if (not MP.LOBBY.config.weekly) or (MP.LOBBY.config.weekly ~= MP.LOBBY.fetched_weekly) then
				col = G.C.DARK_EDITION
			end
		end
		local button = UIBox_button({ id = data.button_id, col = true, chosen = (idx == 1 and "vert" or false), label = { localize(data.button_localize_key) }, button =
		button_func, colour = col, minw = 4, scale = 0.4, minh = 0.6 })
		buttons[#buttons + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = { button } }
	end

	return create_UIBox_generic_options({
		back_func = "play_options",
		contents = {
			{ n = G.UIT.C, config = { align = "tm", minh = 8, minw = 4 }, nodes = buttons },
			{
				n = G.UIT.C,
				config = { align = "cm", minh = 8, maxh = 8, minw = 11 },
				nodes = {
					{ n = G.UIT.O, config = { id = info_area_id, object = default_info_area } }
				}
			}
		}
	})
end

function MP.UI.Change_Main_Lobby_Options(e, info_area_id, info_area_func, default_button_id, update_lobby_config_func)
	if not G.OVERLAY_MENU then return end

	local info_area = G.OVERLAY_MENU:get_UIE_by_ID(info_area_id)
	if not info_area then return end

	-- Switch 'chosen' status from the previously-chosen button to this one:
	if info_area.config.prev_chosen then
		info_area.config.prev_chosen.config.chosen = nil
	else -- The previously-chosen button should be the default one here:
		local default_button = G.OVERLAY_MENU:get_UIE_by_ID(default_button_id)
		if default_button then default_button.config.chosen = nil end
	end
	e.config.chosen = "vert" -- Special setting to show 'chosen' indicator on the side

	local info_obj_name = string.match(e.config.id, "([^_]+)")
	update_lobby_config_func(info_obj_name)

	if info_area.config.object then info_area.config.object:remove() end
	info_area.config.object = UIBox({
		definition = info_area_func(info_obj_name),
		config = { align = "cm", parent = info_area }
	})

	info_area.config.object:recalculate()

	info_area.config.prev_chosen = e
end
