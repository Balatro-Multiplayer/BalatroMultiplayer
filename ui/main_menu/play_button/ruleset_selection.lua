function G.UIDEF.ruleset_selection_options(mode)
	mode = mode or "mp"
	MP.LOBBY.fetched_weekly = "smallworld" -- temp

	-- SP defaults to vanilla, MP defaults to ranked
	local default_ruleset = "standard_ranked"
	local default_button = default_ruleset .. "_ruleset_button"

	if mode == "sp" then
		MP.SP.ruleset = "ruleset_mp_" .. default_ruleset
	else
		MP.LOBBY.config.ruleset = "ruleset_mp_" .. default_ruleset
	end
	MP.LoadReworks(default_ruleset)

	local default_ruleset_area = UIBox({
		definition = G.UIDEF.ruleset_info(default_ruleset, mode),
		config = { align = "cm" },
	})

	local ruleset_buttons_data = {
		{
			name = "k_matchmaking",
			buttons = {
				{ button_id = "standard_ranked_ruleset_button", button_localize_key = "k_standard_ranked" },
				{ button_id = "legacy_ranked_ruleset_button", button_localize_key = "k_legacy_ranked" },
				{ button_id = "smallworld_ruleset_button", button_localize_key = "k_smallworld" },
				{ button_id = "sandbox_ruleset_button", button_localize_key = "k_sandbox" },
			},
		},
		{
			name = "k_custom",
			buttons = {
				{ button_id = "blitz_ruleset_button", button_localize_key = "k_blitz" },
				{ button_id = "traditional_ruleset_button", button_localize_key = "k_traditional" },
				{ button_id = "vanilla_ruleset_button", button_localize_key = "k_vanilla" },
				{ button_id = "badlatro_ruleset_button", button_localize_key = "k_badlatro" },
				{ button_id = "speedlatro_ruleset_button", button_localize_key = "k_speedlatro" },
			},
		},
		{
			name = "k_tournament",
			buttons = {
				{ button_id = "majorleague_ruleset_button", button_localize_key = "k_majorleague" },
				{ button_id = "minorleague_ruleset_button", button_localize_key = "k_minorleague" },
			},
		},
	}

	MP.UI.ruleset_selection_mode = mode

	return MP.UI.Main_Lobby_Options(
		"ruleset_area",
		default_ruleset_area,
		"change_ruleset_selection",
		ruleset_buttons_data
	)
end

function G.FUNCS.change_ruleset_selection(e)
	local mode = MP.UI.ruleset_selection_mode or "mp"

	if e.config.id == "weekly_ruleset_button" then
		if G.FUNCS.weekly_interrupt(e) then return end
	end

	-- this currently doesn't work properly
	-- local default_button = mode == "sp" and "vanilla_ruleset_button" or "standard_ranked_ruleset_button"
	local default_button = "standard_ranked_ruleset_button"

	MP.UI.Change_Main_Lobby_Options(
		e,
		"ruleset_area",
		function(ruleset_name)
			return G.UIDEF.ruleset_info(ruleset_name, mode)
		end,
		default_button,
		function(ruleset_name)
			if mode == "sp" then
				MP.SP.ruleset = "ruleset_mp_" .. ruleset_name
			else
				MP.LOBBY.config.ruleset = "ruleset_mp_" .. ruleset_name
			end
			MP.LoadReworks(ruleset_name)
		end
	)

	MP.LOBBY.ruleset_preview = false
end

function G.UIDEF.ruleset_info(ruleset_name, mode)
	mode = mode or "mp"
	local ruleset = MP.Rulesets["ruleset_mp_" .. ruleset_name]

	local ruleset_info_banned_rework_tabs = UIBox({
		definition = G.UIDEF.ruleset_tabs(ruleset),
		config = { align = "cm" },
	})

	local ruleset_disabled = ruleset.is_disabled()

	-- Different button config for SP vs MP
	local button_config
	if mode == "sp" then
		button_config = {
			id = "start_sp_button",
			button = "start_sp_run",
			label = { localize("b_play_cap") },
			colour = G.C.GREEN,
		}
	else
		button_config = {
			id = "select_gamemode_button",
			button = ruleset.forced_gamemode and "force_" .. ruleset.forced_gamemode or "select_gamemode",
			label = { ruleset.forced_gamemode and localize("b_create_lobby") or localize("b_next") },
			colour = G.C.BLUE,
		}
	end

	return {
		n = G.UIT.ROOT,
		config = { align = "tm", minh = 8, maxh = 8, minw = 11, maxw = 11, colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "tm", padding = 0.2, r = 0.1, colour = G.C.BLACK },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.O, config = { object = ruleset_info_banned_rework_tabs } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							MP.UI.Disableable_Button({
								id = button_config.id,
								button = button_config.button,
								align = "cm",
								padding = 0.05,
								r = 0.1,
								minw = 8,
								minh = 0.8,
								colour = button_config.colour,
								hover = true,
								shadow = true,
								label = button_config.label,
								scale = 0.5,
								enabled_ref_table = { val = not ruleset_disabled },
								enabled_ref_value = "val",
								disabled_text = { ruleset_disabled },
							}),
						},
					},
				},
			},
		},
	}
end

function G.UIDEF.ruleset_tabs(ruleset)
	local default_tabs = UIBox({
		definition = G.UIDEF.lobby_setup_tabs_definition(ruleset, "info", 1, true),
		config = { align = "cm", tab_type = "info", chosen_tab = 1 },
	})

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.L_BLACK, r = 0.1 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "tm", colour = G.C.GREY, r = 0.1 },
						nodes = {
							{ n = G.UIT.O, config = { object = default_tabs } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "bm", padding = 0.05 },
						nodes = {
							create_option_cycle({
								options = { localize("k_info"), localize("k_bans"), localize("k_reworks") },
								current_option = 1,
								opt_callback = "ruleset_switch_tabs",
								opt_args = { ui = default_tabs, ruleset = ruleset },
								w = 5,
								colour = G.C.RED,
								cycle_shoulders = false,
							}),
						},
					},
				},
			},
		},
	}
end

function G.FUNCS.ruleset_switch_tabs(args)
	if not args or not args.cycle_config then return end
	local callback_args = args.cycle_config.opt_args

	local tabs_object = callback_args.ui
	local tabs_wrap = tabs_object.parent

	local active_tab = tabs_wrap.UIBox:get_UIE_by_ID("ruleset_active_tab")
	local active_tab_idx = active_tab and active_tab.config.tab_idx or 1

	local tab_type = (args.to_key == 2 and "banned") or (args.to_key == 3 and "rework") or "info"
	local def = nil

	if tab_type == "banned" then
		def = G.UIDEF.lobby_setup_tabs_definition(callback_args.ruleset, "banned", active_tab_idx, true)
		tabs_object.config.tab_type = "banned"
		MP.LOBBY.config.ruleset = callback_args.ruleset.key
		MP.LOBBY.ruleset_preview = false
	elseif tab_type == "rework" then
		def = G.UIDEF.lobby_setup_tabs_definition(callback_args.ruleset, "rework", active_tab_idx, true)
		tabs_object.config.tab_type = "rework"
		MP.LOBBY.config.ruleset = callback_args.ruleset.key
		MP.LOBBY.ruleset_preview = true
	else
		def = G.UIDEF.lobby_setup_tabs_definition(callback_args.ruleset, "info", active_tab_idx, true)
		tabs_object.config.tab_type = "info"
		MP.LOBBY.config.ruleset = callback_args.ruleset.key
		MP.LOBBY.ruleset_preview = false
	end

	tabs_wrap.config.object:remove()
	tabs_wrap.config.object = UIBox({
		definition = def,
		config = { align = "cm", parent = tabs_wrap },
	})

	tabs_wrap.UIBox:recalculate()
end

local function create_bans_and_reworks_tabs(ruleset_or_gamemode, is_banned_tab, chosen_tab_idx)
	local banned_cards_tabs = {}

	local function merge_lists(lists)
		local seen = {}
		local ret = {}
		for _, tbl in pairs(lists) do
			tbl = tbl or {}
			for _, v in ipairs(tbl) do
				if not seen[v] then
					seen[v] = true
					table.insert(ret, v)
				end
			end
		end
		return ret
	end

	local forced_gamemode = {}
	if ruleset_or_gamemode.forced_gamemode then forced_gamemode = MP.Gamemodes[ruleset_or_gamemode.forced_gamemode] end

	local tabs = {}
	local loc_keys = {
		jokers = "b_jokers",
		consumables = "b_stat_consumables",
		vouchers = "b_vouchers",
		enhancements = "b_enhanced_cards",
		other = "k_other",
	}
	local function copy_list(key)
		if is_banned_tab then
			return merge_lists({
				MP.DECK["BANNED_" .. string.upper(key)],
				ruleset_or_gamemode["banned_" .. key],
				forced_gamemode["banned_" .. key],
			})
		else
			return merge_lists({ ruleset_or_gamemode["reworked_" .. key], forced_gamemode["reworked_" .. key] })
		end
	end
	for _, v in ipairs({ "jokers", "consumables", "vouchers", "enhancements", "other" }) do
		local entry = { type = localize(loc_keys[v]) }
		if v ~= "other" then
			entry.obj_ids = copy_list(v)
		else
			entry.obj_ids = {
				blinds = copy_list("blinds"),
				tags = copy_list("tags"),
			}
		end

		tabs[#tabs + 1] = entry
	end

	for k, v in ipairs(tabs) do
		v.idx = k
		v.is_banned_tab = is_banned_tab
		local tab_def = {
			label = v.type,
			chosen = (k == chosen_tab_idx),
			tab_definition_function = G.UIDEF.ruleset_cardarea_definition,
			tab_definition_function_args = v,
		}
		table.insert(banned_cards_tabs, tab_def)
	end

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			create_tabs({
				tab_h = 4.2,
				padding = 0,
				scale = 0.8,
				text_scale = 0.36,
				no_shoulders = true,
				no_loop = true,
				tabs = banned_cards_tabs,
			}),
		},
	}
end

function G.UIDEF.lobby_setup_tabs_definition(ruleset_or_gamemode, tab_type, chosen_tab_idx, is_ruleset)
	if tab_type == "banned" or tab_type == "rework" then
		return create_bans_and_reworks_tabs(ruleset_or_gamemode, tab_type == "banned", chosen_tab_idx)
	end

	local tab_id = ruleset_or_gamemode.key:find("ruleset") and "ruleset_active_tab" or "gamemode_active_tab"

	return {
		n = G.UIT.ROOT,
		config = { id = tab_id, align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "tm", padding = 0.2, r = 0.1, minw = 10.7, maxw = 10.7, minh = 5.75, maxh = 5.75 },
				nodes = ruleset_or_gamemode.create_info_menu(),
			},
		},
	}
end

function G.UIDEF.ruleset_cardarea_definition(args)
	local function get_ruleset_cardarea(obj_ids, width, height)
		local ret = {}

		if #obj_ids > 0 then
			local card_rows = {}
			local n_rows = math.max(1, 1 + math.floor(#obj_ids / 10) - math.floor(math.log(6, #obj_ids)))
			local max_width = 1
			for k, v in ipairs(obj_ids) do
				local _row = math.ceil(n_rows * (k / #obj_ids))
				card_rows[_row] = card_rows[_row] or {}
				card_rows[_row][#card_rows[_row] + 1] = v
				if #card_rows[_row] > max_width then max_width = #card_rows[_row] end
			end

			local card_size = math.max(0.3, 0.8 - 0.01 * (max_width * n_rows))

			for _, card_row in ipairs(card_rows) do
				local card_area = CardArea(0, 0, width, height / n_rows, {
					card_limit = nil,
					type = "title_2",
					view_deck = true,
					highlight_limit = 0,
					card_w = G.CARD_W * card_size,
				})

				for k, v in ipairs(card_row) do -- Each card_row consists of Card IDs
					local card = Card(
						0,
						0,
						G.CARD_W * card_size,
						G.CARD_H * card_size,
						nil,
						G.P_CENTERS[v],
						{ bypass_discovery_center = true, bypass_discovery_ui = true }
					)
					card_area:emplace(card)
				end

				table.insert(ret, {
					n = G.UIT.R,
					config = { align = "cm" },
					nodes = {
						{ n = G.UIT.O, config = { object = card_area } },
					},
				})
			end
		end

		return ret
	end

	local function get_ruleset_obj_grid(obj_ids, obj_ref_table, objs_per_row, obj_constructor, wrap_as_object)
		local objs = {}
		for _, v in ipairs(obj_ids) do
			objs[#objs + 1] = obj_ref_table[v]
		end
		-- table.sort(objs, function (a, b) return a.order < b.order end)

		local obj_grid = {}
		local obj_rows = {}
		for k, v in ipairs(objs) do
			local obj = obj_constructor(v)

			local row_idx = math.ceil(k / objs_per_row)
			if not obj_rows[row_idx] then obj_rows[row_idx] = {} end
			table.insert(obj_rows[row_idx], {
				n = G.UIT.C,
				config = { align = "cm", padding = 0.1 },
				nodes = {
					wrap_as_object and { n = G.UIT.O, config = { object = obj } } or obj,
				},
			})
		end
		for _, v in ipairs(obj_rows) do
			table.insert(obj_grid, { n = G.UIT.R, config = { align = "cm" }, nodes = v })
		end

		return obj_grid
	end

	local function get_localised_label(objs, obj_type)
		return (#objs > 0)
				and {
					n = G.UIT.T,
					config = {
						text = localize({
							type = "variable",
							key = args.is_banned_tab and "k_banned_objs" or "k_reworked_objs",
							vars = { obj_type },
						}),
						colour = lighten(G.C.L_BLACK, 0.5),
						scale = 0.33,
					},
				}
			or {
				n = G.UIT.T,
				config = {
					text = localize({
						type = "variable",
						key = args.is_banned_tab and "k_no_banned_objs" or "k_no_reworked_objs",
						vars = { obj_type },
					}),
					colour = lighten(G.C.L_BLACK, 0.5),
					scale = 0.33,
				},
			}
	end

	if args.type == localize("k_other") then
		local function tag_constructor(tag_spec)
			return Tag(tag_spec.key):generate_UI(1 - 0.1 * (math.sqrt(#args.obj_ids.tags)))
		end

		local function blind_constructor(blind_spec)
			local temp_blind = AnimatedSprite(
				0,
				0,
				1.1,
				1.1,
				G.ANIMATION_ATLAS[blind_spec.atlas] or G.ANIMATION_ATLAS["blind_chips"],
				blind_spec.pos
			)
			temp_blind:define_draw_steps({
				{ shader = "dissolve", shadow_height = 0.05 },
				{ shader = "dissolve" },
			})
			temp_blind.float = true
			temp_blind.states.hover.can = true
			temp_blind.states.drag.can = false
			temp_blind.states.collide.can = true
			temp_blind.config = { blind = blind_spec, force_focus = true }
			temp_blind.hover = function()
				if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then
					if not temp_blind.hovering and temp_blind.states.visible then
						temp_blind.hovering = true
						temp_blind.hover_tilt = 3
						Juice_up(temp_blind, 0.05, 0.02)
						temp_blind.config.h_popup = create_UIBox_blind_popup(blind_spec, true)
						temp_blind.config.h_popup_config = {
							align = "cl",
							offset = { x = -0.1, y = 0 },
							parent = temp_blind,
						}
						Node.hover(temp_blind)
					end
				end
			end
			temp_blind.stop_hover = function()
				temp_blind.hovering = false
				Node.stop_hover(temp_blind)
				temp_blind.hover_tilt = 0
			end

			return temp_blind
		end

		local tag_grid = get_ruleset_obj_grid(args.obj_ids.tags, G.P_TAGS, 4, tag_constructor)
		local blind_grid = get_ruleset_obj_grid(args.obj_ids.blinds, G.P_BLINDS, 3, blind_constructor, true)

		return {
			n = G.UIT.ROOT,
			config = { id = "ruleset_active_tab", tab_idx = args.idx, align = "cm", colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UIT.C,
					config = { align = "cm", padding = 0.05, r = 0.1, minw = 5.4, minh = 4.8, maxh = 4.8 },
					nodes = {
						{ n = G.UIT.R, config = { align = "cm", minh = 4 }, nodes = tag_grid },
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0.05 },
							nodes = { get_localised_label(args.obj_ids.tags, localize("b_tags")) },
						},
					},
				},
				{
					n = G.UIT.C,
					config = { align = "cm", padding = 0.05, r = 0.1, minw = 5.4, minh = 4.8, maxh = 4.8 },
					nodes = {
						{ n = G.UIT.R, config = { align = "cm", minh = 4 }, nodes = blind_grid },
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0.05 },
							nodes = { get_localised_label(args.obj_ids.blinds, localize("b_blinds")) },
						},
					},
				},
			},
		}
	else
		local cards_grid = get_ruleset_cardarea(args.obj_ids, 10, 4)

		return {
			n = G.UIT.ROOT,
			config = { id = "ruleset_active_tab", tab_idx = args.idx, align = "cm", colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UIT.C,
					config = { align = "cm", padding = 0.05, r = 0.1, minw = 10.8, minh = 4.8, maxh = 4.8 },
					nodes = {
						{ n = G.UIT.R, config = { align = "cm" }, nodes = cards_grid },
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0.05 },
							nodes = { get_localised_label(args.obj_ids, args.type) },
						},
					},
				},
			},
		}
	end
end
