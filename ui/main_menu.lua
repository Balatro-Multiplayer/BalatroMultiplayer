MULTIPLAYER_VERSION = SMODS.Mods["Multiplayer"].version .. "-MULTIPLAYER"

function nope_a_joker(card)
	attention_text({
		text = localize("k_nope_ex"),
		scale = 0.8,
		hold = 0.8,
		major = card,
		backdrop_colour = G.C.SECONDARY_SET.Tarot,
		align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and "tm" or "cm",
		offset = {
			x = 0,
			y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0,
		},
		silent = true,
	})
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.06 * G.SETTINGS.GAMESPEED,
		blockable = false,
		blocking = false,
		func = function()
			play_sound("tarot2", 0.76, 0.4)
			return true
		end,
	}))
	play_sound("tarot2", 1, 0.4)
end

function wheel_of_fortune_the_card(card)
	math.randomseed(os.time())
	local chance = math.random(4)
	if chance == 1 then
		local edition = poll_edition("main_menu", nil, false, true)
		card:set_edition(edition, true)
		card:juice_up(0.3, 0.5)
	else
		nope_a_joker(card)
		card:juice_up(0.3, 0.5)
	end
end

wheel_of_fortune_the_title_card = wheel_of_fortune_the_title_card
	or function()
		wheel_of_fortune_the_card(G.title_top.cards[1])
		return true
	end

MP.title_card = nil

wheel_of_fortune_the_mp_card = wheel_of_fortune_the_mp_card
	or function()
		if MP.title_card then
			wheel_of_fortune_the_card(MP.title_card)
		end
		return true
	end

function add_custom_multiplayer_cards(change_context)
	G.title_top.cards[1]:set_base(G.P_CARDS["S_A"], true)

	-- Credit to the Cryptid mod for the original code to add a card to the main menu
	local title_card = create_card("Base", G.title_top, nil, nil, nil, nil)
	title_card:set_base(G.P_CARDS["H_A"], true)
	G.title_top.T.w = G.title_top.T.w * 1.7675
	G.title_top.T.x = G.title_top.T.x - 0.8
	G.title_top:emplace(title_card)
	title_card.T.w = title_card.T.w * 1.1 * 1.2
	title_card.T.h = title_card.T.h * 1.1 * 1.2
	title_card.no_ui = true
	title_card.states.visible = false

	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = change_context == "game" and 1.5 or 0,
		blockable = false,
		blocking = false,
		func = function()
			if change_context == "splash" then
				title_card.states.visible = true
				title_card:start_materialize({ G.C.WHITE, G.C.WHITE }, true, 2.5)
				play_sound("whoosh1", math.random() * 0.1 + 0.3, 0.3)
				play_sound("crumple" .. math.random(1, 5), math.random() * 0.2 + 0.6, 0.65)
			else
				title_card.states.visible = true
				title_card:start_materialize({ G.C.WHITE, G.C.WHITE }, nil, 1.2)
			end
			G.VIBRATION = G.VIBRATION + 1
			return true
		end,
	}))

	MP.title_card = title_card

	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 2,
		blockable = false,
		blocking = false,
		func = wheel_of_fortune_the_title_card,
	}))

	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 3,
		blockable = false,
		blocking = false,
		func = wheel_of_fortune_the_mp_card,
	}))
end

local game_main_menu_ref = Game.main_menu
---@diagnostic disable-next-line: duplicate-set-field
function Game:main_menu(change_context)
	local ret = game_main_menu_ref(self, change_context)

	add_custom_multiplayer_cards(change_context)

	-- Add version to main menu
	UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = {
				align = "cm",
				colour = G.C.UI.TRANSPARENT_DARK,
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						scale = 0.3,
						text = MULTIPLAYER_VERSION,
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		},
		config = {
			align = "tri",
			bond = "Weak",
			offset = {
				x = 0,
				y = 0.6,
			},
			major = G.ROOM_ATTACH,
		},
	})

	return ret
end

function G.UIDEF.ruleset_selection_options()
	local default_ruleset_area = UIBox({
		definition = G.UIDEF.ruleset_info("standard"),
		config = {align = "cm"}
	})

	return create_UIBox_generic_options({back_func = "play_options", contents = {
		{n=G.UIT.C, config={align = "tm", minh = 8, minw = 4}, nodes={
			{n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
				UIBox_button({id = "standard_ruleset_button", col = true, chosen = "vert", label = {localize("k_standard")}, button = "change_ruleset_selection", colour = G.C.RED, minw = 4, scale = 0.4, minh = 0.6}),
			}},
			{n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
				UIBox_button({id = "vanilla_ruleset_button", col = true, label = {localize("k_vanilla")}, button = "change_ruleset_selection", colour = G.C.RED, minw = 4, scale = 0.4, minh = 0.6}),
			}},
			{n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
				UIBox_button({id = "badlatro_ruleset_button", col = true, label = {localize("k_badlatro")}, button = "change_ruleset_selection", colour = G.C.RED, minw = 4, scale = 0.4, minh = 0.6}),
			}}
		}},
		{n=G.UIT.C, config={align = "cm", minh = 8, maxh = 8, minw = 10}, nodes={
			{n=G.UIT.O, config={id = "ruleset_area", object = default_ruleset_area}}
		}}
	}})
end

function G.FUNCS.change_ruleset_selection(e)
	if not G.OVERLAY_MENU then return end

	local ruleset_area = G.OVERLAY_MENU:get_UIE_by_ID("ruleset_area")
	if not ruleset_area then return end

	-- Switch 'chosen' status from the previously-chosen button to this one:
	if ruleset_area.config.prev_chosen then
		ruleset_area.config.prev_chosen.config.chosen = nil
	else -- The previously-chosen button should be the default one here:
		local default_button = G.OVERLAY_MENU:get_UIE_by_ID("standard_ruleset_button")
		if default_button then default_button.config.chosen = nil end
	end
	e.config.chosen = "vert" -- Special setting to show 'chosen' indicator on the side

	if ruleset_area.config.object then ruleset_area.config.object:remove() end
	ruleset_area.config.object = UIBox({
		 definition = G.UIDEF.ruleset_info(string.match(e.config.id, "([^_]+)")),
		 config = {align = "cm", parent = ruleset_area}
	})

	ruleset_area.config.prev_chosen = e
end

function G.UIDEF.ruleset_info(ruleset_name)
	local ruleset = MP.Rulesets["ruleset_mp_" .. ruleset_name]

	local ruleset_desc = MP.UTILS.wrapText(localize("k_" .. ruleset_name .. "_description"), 80)
	local _, ruleset_desc_lines = ruleset_desc:gsub("\n", " ")

	local ruleset_banned_tabs = UIBox({
		definition = G.UIDEF.ruleset_banned_tabs(ruleset),
		config = {align = "cm"}
	})

	return {n=G.UIT.ROOT, config={align = "tm", minh = 8, maxh = 8, minw = 10, colour = G.C.CLEAR}, nodes={
		{n=G.UIT.C, config={align = "tm", padding = 0.2, r = 0.1, colour = G.C.BLACK}, nodes={
			{n=G.UIT.R, config={align = "tm", padding = 0.05, minw = 9, maxw = 9, minh = math.max(2, ruleset_desc_lines) * 0.35}, nodes={
				{n=G.UIT.T, config={text = ruleset_desc, colour = G.C.UI.TEXT_LIGHT, scale = 0.8}}
			}},
			{n=G.UIT.R, config={align = "cm"}, nodes={
				{n=G.UIT.O, config={object = ruleset_banned_tabs}}
			}},
			{n=G.UIT.R, config={align = "cm"}, nodes={
				{n=G.UIT.R, config={id = "start"..ruleset_name, button = "start_lobby", align = "cm", padding = 0.05, r = 0.1, minw = 8, minh = 0.8, colour = G.C.BLUE, hover = true, shadow = true}, nodes={
					{n=G.UIT.T, config={text = localize("b_create_lobby"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT}}
				}}
			}}
		}}
	}}
end

function G.UIDEF.ruleset_banned_tabs(ruleset)
	local banned_cards_tabs = {}
	for k, v in ipairs({{type = localize("b_jokers"), card_ids = ruleset.banned_jokers},
											{type = localize("b_stat_consumables"), card_ids = ruleset.banned_consumables},
											{type = localize("b_vouchers"), card_ids = ruleset.banned_vouchers},
											{type = localize("b_enhanced_cards"), card_ids = ruleset.banned_enhancements}})
	do
		local tab_def = {label = v.type,
										 chosen = (k == 1),
										 tab_definition_function = G.UIDEF.ruleset_banned_cards,
										 tab_definition_function_args = v}
		table.insert(banned_cards_tabs, tab_def)
	end

	return {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={
		create_tabs({tab_h = 4.2, padding = 0, scale = 0.85, text_scale = 0.36, no_shoulders = true, no_loop = true,
								 tabs = banned_cards_tabs})
	}}
end

function G.UIDEF.ruleset_banned_cards(args)
	local function get_ruleset_cardarea(card_ids, width, height)
		local ret = {}

		if #card_ids > 0 then
			local card_rows = {}
			local n_rows = math.max(1, 1 + math.floor(#card_ids/10) - math.floor(math.log(6, #card_ids)))
			local max_width = 1
			for k, v in ipairs(card_ids) do
				local _row = math.ceil(n_rows * (k/(#card_ids)))
				card_rows[_row] = card_rows[_row] or {}
				card_rows[_row][#card_rows[_row]+1] = v
				if #card_rows[_row] > max_width then max_width = #card_rows[_row] end
			end

			local card_size = math.max(0.3, 0.8 - 0.01*(max_width*n_rows))

			for _, card_row in ipairs(card_rows) do
				local card_area = CardArea(
					0, 0,
					width, height/n_rows,
					{card_limit = nil, type = 'title_2', view_deck = true, highlight_limit = 0, card_w = G.CARD_W*card_size}
				)

				for k, v in ipairs(card_row) do -- Each card_row consists of Card IDs
					local card = Card(0,0, G.CARD_W*card_size, G.CARD_H*card_size, nil, G.P_CENTERS[v], {bypass_discovery_center = true,bypass_discovery_ui = true})
					card_area:emplace(card)
				end

				table.insert(ret,
										 {n=G.UIT.R, config={align = "cm"}, nodes={
											 {n=G.UIT.O, config={object = card_area}}
										 }})
			end
		end

		return ret
	end

	local cards_grid = get_ruleset_cardarea(args.card_ids, 8, 4)

	return {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={
		{n=G.UIT.C, config={align = "cm", colour = G.C.L_BLACK, padding = 0.05, r = 0.1, minw = 9, minh = 4.8, maxh = 4.8}, nodes={
			{n=G.UIT.R, config={align = "cm"}, nodes=cards_grid},
			{n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
				(#args.card_ids > 0)
					and {n=G.UIT.T, config={text = localize({type = "variable", key = "k_banned_cards", vars = {args.type}}), colour = lighten(G.C.L_BLACK, 0.5), scale = 0.33}}
					or {n=G.UIT.T, config={text = localize({type = "variable", key = "k_no_banned_cards", vars = {args.type}}), colour = lighten(G.C.L_BLACK, 0.5), scale = 0.33}}
			}}
		}}
	}}
end

function G.UIDEF.create_UIBox_join_lobby_button()
	return (
		create_UIBox_generic_options({
			back_func = "play_options",
			contents = {
				{
					n = G.UIT.R,
					config = {
						padding = 0,
						align = "cm",
					},
					nodes = {
						{
							n = G.UIT.R,
							config = {
								padding = 0.5,
								align = "cm",
							},
							nodes = {
								create_text_input({
									w = 4,
									h = 1,
									max_length = 5,
									all_caps = true,
									prompt_text = localize("k_enter_lobby_code"),
									ref_table = MP.LOBBY,
									ref_value = "temp_code",
									extended_corpus = false,
									keyboard_offset = 1,
									minw = 5,
									callback = function(val)
										MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
									end,
								}),
							},
						},
						UIBox_button({
							label = { localize("k_paste") },
							colour = G.C.RED,
							button = "join_from_clipboard",
							minw = 5,
						}),
					},
				},
			},
		})
	)
end

function G.UIDEF.override_main_menu_play_button()
	return (
		create_UIBox_generic_options({
			contents = {
				UIBox_button({
					label = { localize("b_singleplayer") },
					colour = G.C.BLUE,
					button = "setup_run",
					minw = 5,
				}),
				MP.LOBBY.connected and UIBox_button({
					label = { localize("b_create_lobby") },
					colour = G.C.GREEN,
					button = "create_lobby",
					minw = 5,
				}) or nil,
				MP.LOBBY.connected and UIBox_button({
					label = { localize("b_join_lobby") },
					colour = G.C.RED,
					button = "join_lobby",
					minw = 5,
				}) or nil,
				not MP.LOBBY.connected and UIBox_button({
					label = { localize("b_reconnect") },
					colour = G.C.RED,
					button = "reconnect",
					minw = 5,
				}) or nil,
			},
		})
	)
end

function G.FUNCS.play_options(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.override_main_menu_play_button(),
	})
end

function G.FUNCS.create_lobby(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_options(),
	})
end

function G.FUNCS.join_lobby(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_join_lobby_button(),
	})
end

function G.FUNCS.join_from_clipboard(e)
	MP.LOBBY.temp_code = MP.UTILS.get_from_clipboard()
	MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
end

function G.FUNCS.start_lobby(e)
	G.SETTINGS.paused = false
	if e.config.id == "start_vanilla" then
		MP.LOBBY.config.multiplayer_jokers = false
	else
		MP.LOBBY.config.multiplayer_jokers = true
	end
	MP.ACTIONS.create_lobby(
		e.config.id == "start_vanilla" and "ruleset_mp_vanilla"
			or e.config.id == "start_weekly" and "ruleset_mp_weekly"
			or e.config.id == "start_badlatro" and "ruleset_mp_badlatro"
			or "ruleset_mp_standard"
	)
	G.FUNCS.exit_overlay_menu()
end

-- Modify play button to take you to mode select first
local create_UIBox_main_menu_buttonsRef = create_UIBox_main_menu_buttons
---@diagnostic disable-next-line: lowercase-global
function create_UIBox_main_menu_buttons()
	local menu = create_UIBox_main_menu_buttonsRef()
	menu.nodes[1].nodes[1].nodes[1].nodes[1].config.button = "play_options"
	return menu
end

G.FUNCS.wipe_off = function()
	G.E_MANAGER:add_event(Event({
		no_delete = true,
		func = function()
			delay(0.3)
			if not G.screenwipe then
				return true
			end
			G.screenwipe.children.particles.max = 0
			G.E_MANAGER:add_event(Event({
				trigger = "ease",
				no_delete = true,
				blockable = false,
				blocking = false,
				timer = "REAL",
				ref_table = G.screenwipe.colours.black,
				ref_value = 4,
				ease_to = 0,
				delay = 0.3,
				func = function(t)
					return t
				end,
			}))
			G.E_MANAGER:add_event(Event({
				trigger = "ease",
				no_delete = true,
				blockable = false,
				blocking = false,
				timer = "REAL",
				ref_table = G.screenwipe.colours.white,
				ref_value = 4,
				ease_to = 0,
				delay = 0.3,
				func = function(t)
					return t
				end,
			}))
			return true
		end,
	}))
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.55,
		no_delete = true,
		blocking = false,
		timer = "REAL",
		func = function()
			if not G.screenwipe then
				return true
			end
			if G.screenwipecard then
				G.screenwipecard:start_dissolve({ G.C.BLACK, G.C.ORANGE, G.C.GOLD, G.C.RED })
			end
			if G.screenwipe:get_UIE_by_ID("text") then
				for k, v in ipairs(G.screenwipe:get_UIE_by_ID("text").children) do
					v.children[1].config.object:pop_out(4)
				end
			end
			return true
		end,
	}))
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 1.1,
		no_delete = true,
		blocking = false,
		timer = "REAL",
		func = function()
			if not G.screenwipe then
				return true
			end
			G.screenwipe.children.particles:remove()
			G.screenwipe:remove()
			G.screenwipe.children.particles = nil
			G.screenwipe = nil
			G.screenwipecard = nil
			return true
		end,
	}))
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 1.2,
		no_delete = true,
		blocking = true,
		timer = "REAL",
		func = function()
			return true
		end,
	}))
end

function G.FUNCS.join_game_submit(e)
	G.FUNCS.exit_overlay_menu()
	MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
end

function G.FUNCS.join_game_paste(e)
	MP.LOBBY.temp_code = MP.UTILS.get_from_clipboard()
	MP.ACTIONS.join_lobby(MP.LOBBY.temp_code)
	G.FUNCS.exit_overlay_menu()
end
