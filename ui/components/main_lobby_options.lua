function MP.UI.Main_Lobby_Options(info_area_id, default_info_area, button_func, buttons_data)
	local buttons = {}
	for idx, data in ipairs(buttons_data) do
		local button = UIBox_button({id = data.button_id, col = true, chosen = (idx == 1 and "vert" or false), label = {localize(data.button_localize_key)}, button = button_func, colour = G.C.RED, minw = 4, scale = 0.4, minh = 0.6})
		buttons[#buttons+1] = {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={button}}
	end

	return create_UIBox_generic_options({back_func = "play_options", contents = {
		{n=G.UIT.C, config={align = "tm", minh = 8, minw = 4}, nodes=buttons},
		{n=G.UIT.C, config={align = "cm", minh = 8, maxh = 8, minw = 11}, nodes={
			{n=G.UIT.O, config={id = info_area_id, object = default_info_area}}
		}}
	}})
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
		 config = {align = "cm", parent = info_area}
	})

	info_area.config.object:recalculate()

	info_area.config.prev_chosen = e
end
