function MP.UI.create_UIBox_mp_game_end(has_won)
	MP.end_game_jokers = CardArea(
		0,
		0,
		5 * G.CARD_W,
		G.CARD_H,
		{ card_limit = G.GAME.starting_params.joker_slots, type = "joker", highlight_limit = 1 }
	)
	if not MP.end_game_jokers_received then
		MP.ACTIONS.get_end_game_jokers()
	else
		G.FUNCS.load_end_game_jokers()
	end
	MP.end_game_jokers_text = localize("k_enemy_jokers")

	MP.ACTIONS.request_nemesis_stats()

	MP.nemesis_deck = CardArea(-100, -100, G.CARD_W, G.CARD_H, { type = "deck" })
	MP.nemesis_cards = {}
	if not MP.nemesis_deck_received then
		MP.ACTIONS.get_nemesis_deck()
	else
		G.FUNCS.load_nemesis_deck()
	end

	G.SETTINGS.paused = false

	local eased_bg_colour
	if has_won then
		eased_bg_colour = copy_table(G.C.GREEN)
		eased_bg_colour[4] = 0
		ease_value(eased_bg_colour, 4, 0.5, nil, nil, true)
	else
		eased_bg_colour = copy_table(G.C.RED)
		eased_bg_colour[4] = 0
		ease_value(eased_bg_colour, 4, 0.8, nil, nil, true)
	end

	local t = create_UIBox_generic_options({
		padding = 0,
		bg_colour = eased_bg_colour,
		colour = has_won and G.C.BLACK or nil,
		outline_colour = has_won and G.C.EDITION or nil,
		no_back = true,
		no_esc = has_won,
		contents = {
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.O,
						config = {
							object = DynaText({
								string = { has_won and localize("ph_you_win") or localize("ph_game_over") },
								colours = { has_won and G.C.EDITION or G.C.RED },
								shadow = true,
								float = true,
								spacing = has_won and 10 or nil,
								rotate = has_won,
								scale = 1.5,
								pop_in = 0.4,
								maxw = 6.5,
							}),
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.15 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm" },
						nodes = {
							{
								n = G.UIT.R,
								config = { align = "cm", padding = 0.08 },
								nodes = {
									{
										n = G.UIT.T,
										config = {
											ref_table = MP,
											ref_value = "end_game_jokers_text",
											scale = 0.8,
											maxw = 5,
											shadow = true,
										},
									},
								},
							},
							{
								n = G.UIT.R,
								config = { align = "cm", padding = 0.08 },
								nodes = {
									{ n = G.UIT.O, config = { object = MP.end_game_jokers } },
								},
							},
							{
								n = G.UIT.R,
								config = { align = "cm", padding = 0.08 },
								nodes = {
									{
										n = G.UIT.C,
										config = {
											maxw = has_won and 0.8 or 1,
											minw = has_won and 0.8 or 1,
											minh = 0.7,
											colour = G.C.CLEAR,
											no_fill = false,
										},
									},
									{
										n = G.UIT.C,
										config = {
											button = "toggle_players_jokers",
											align = "cm",
											padding = 0.12,
											colour = G.C.BLUE,
											emboss = 0.05,
											minh = 0.7,
											minw = 2,
											maxw = 2,
											r = 0.1,
											shadow = true,
											hover = true,
										},
										nodes = {
											{
												n = G.UIT.T,
												config = {
													text = localize("b_toggle_jokers"),
													colour = G.C.UI.TEXT_LIGHT,
													scale = 0.65,
													col = true,
												},
											},
										},
									},
									{
										n = G.UIT.C,
										config = {
											id = "view_nemesis_deck_button",
											button = "view_nemesis_deck",
											align = "cm",
											padding = 0.12,
											colour = G.C.BLUE,
											emboss = 0.05,
											minh = 0.7,
											minw = 2,
											maxw = 2,
											r = 0.1,
											shadow = true,
											hover = true,
											focus_args = has_won and { nav = "wide" } or nil,
										},
										nodes = {
											{
												n = G.UIT.T,
												config = {
													text = localize("b_view_nemesis_deck"),
													colour = G.C.UI.TEXT_LIGHT,
													scale = 0.65,
													col = true,
												},
											},
										},
									},
									{
										n = G.UIT.C,
										config = {
											maxw = has_won and 0.8 or 1,
											minw = has_won and 0.8 or 1,
											minh = 0.7,
											colour = G.C.CLEAR,
											no_fill = false,
										},
									},
								},
							},
							{
								n = G.UIT.R,
								config = { align = "cm" },
								nodes = {
									{
										n = G.UIT.C,
										config = { align = "cm", padding = 0.08 },
										nodes = {
											create_UIBox_round_scores_row("hand"),
											create_UIBox_round_scores_row("poker_hand"),
											{
												n = G.UIT.R,
												config = { align = "cm", padding = 0.08, minw = 2 },
												nodes = {
													{
														n = G.UIT.T,
														config = {
															text = localize("ml_mp_kofi_message")[1],
															scale = 0.35,
															colour = G.C.UI.TEXT_LIGHT,
															col = true,
														},
													},
												},
											},
											{
												n = G.UIT.R,
												config = { align = "cm", padding = 0.08, minw = 2 },
												nodes = {
													{
														n = G.UIT.T,
														config = {
															text = localize("ml_mp_kofi_message")[2],
															scale = 0.35,
															colour = G.C.UI.TEXT_LIGHT,
															col = true,
														},
													},
												},
											},
											{
												n = G.UIT.R,
												config = { align = "cm", padding = 0.08, minw = 2 },
												nodes = {
													{
														n = G.UIT.T,
														config = {
															text = localize("ml_mp_kofi_message")[3],
															scale = 0.35,
															colour = G.C.UI.TEXT_LIGHT,
															col = true,
														},
													},
												},
											},
											{
												n = G.UIT.R,
												config = { align = "cm", padding = 0.08, minw = 2 },
												nodes = {
													{
														n = G.UIT.T,
														config = {
															text = localize("ml_mp_kofi_message")[4],
															scale = 0.35,
															colour = G.C.UI.TEXT_LIGHT,
															col = true,
														},
													},
												},
											},
											{
												n = G.UIT.R,
												config = {
													id = "ko-fi_button",
													align = "cm",
													padding = 0.1,
													r = 0.1,
													hover = true,
													colour = HEX("72A5F2"),
													button = "open_kofi",
													shadow = true,
												},
												nodes = {
													{
														n = G.UIT.R,
														config = {
															align = "cm",
															padding = 0,
															no_fill = true,
															maxw = 3,
														},
														nodes = {
															{
																n = G.UIT.T,
																config = {
																	text = localize("b_mp_kofi_button"),
																	scale = 0.35,
																	colour = G.C.UI.TEXT_LIGHT,
																},
															},
														},
													},
												},
											},
											--[[ Removed until it is fixed in a future update
											UIBox_button({
												id = "continue_singpleplayer_button",
												align = "lm",
												button = "continue_in_singleplayer",
												label = { localize("b_continue_singleplayer") },
												colour = G.C.GREEN,
												toolTip = {title = "", text = localize("k_continue_singleplayer_tooltip")},
												minw = 6,
												minh = 1,
												func = 'set_button_pip',
												focus_args = { nav = "wide", button = "y" },
											})]]
										},
									},
									{
										n = G.UIT.C,
										config = { align = "tr", padding = 0.08 },
										nodes = {
											create_UIBox_round_scores_row("furthest_ante", G.C.FILTER),
											create_UIBox_round_scores_row("furthest_round", G.C.FILTER),
											create_UIBox_round_scores_row("seed", G.C.WHITE),
											UIBox_button({
												id = "copy_seed_button",
												button = "copy_seed",
												label = { localize("b_copy") },
												colour = G.C.BLUE,
												scale = 0.3,
												minw = 2.3,
												minh = 0.4,
											}),
											{
												n = G.UIT.R,
												config = { align = "cm", minh = 0.4, minw = 0.1 },
												nodes = {},
											},
											UIBox_button({
												id = "from_game_won",
												button = "mp_return_to_lobby",
												label = { localize("b_return_lobby") },
												minw = 2.5,
												maxw = 2.5,
												minh = 1,
												focus_args = { nav = "wide", snap_to = true },
											}),
											UIBox_button({
												button = "lobby_leave",
												label = { localize("b_leave_lobby") },
												minw = 2.5,
												maxw = 2.5,
												minh = 1,
												focus_args = { nav = "wide" },
											}),
										},
									},
								},
							},
						},
					},
				},
			},
		},
	})

	t.nodes[1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.1 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 2 },
				nodes = {
					{
						n = G.UIT.O,
						config = {
							padding = 0,
							id = "jimbo_spot",
							object = Moveable(0, 0, G.CARD_W * 1.1, G.CARD_H * 1.1),
						},
					},
				},
			},
			{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = { t.nodes[1] } },
		},
	}

	if has_won then t.config.id = "you_win_UI" end

	return t
end

function G.UIDEF.view_nemesis_deck()
	local playing_cards_ref = G.playing_cards
	G.playing_cards = MP.nemesis_cards
	local t = G.UIDEF.view_deck()
	G.playing_cards = playing_cards_ref
	return t
end

function G.UIDEF.create_UIBox_view_nemesis_deck()
	return create_UIBox_generic_options({
		back_func = "overlay_endgame_menu",
		contents = {
			create_tabs({
				tabs = {
					{
						label = localize("k_nemesis_deck"),
						chosen = true,
						tab_definition_function = G.UIDEF.view_nemesis_deck,
					},
					{
						label = localize("k_your_deck"),
						tab_definition_function = G.UIDEF.view_deck,
					},
				},
				tab_h = 8,
				snap_to_nav = true,
			}),
		},
	})
end

-- Contains function overrides (monkey-patches) for UI-related functionality
-- Overrides UI creation functions like create_UIBox_game_over, create_UIBox_win, etc.

local create_UIBox_game_over_ref = create_UIBox_game_over
function create_UIBox_game_over()
	if not MP.LOBBY.code then return create_UIBox_game_over_ref() end
	return MP.UI.create_UIBox_mp_game_end(false)
end

local create_UIBox_win_ref = create_UIBox_win
function create_UIBox_win()
	if not MP.LOBBY.code then return create_UIBox_win_ref() end
	return MP.UI.create_UIBox_mp_game_end(true)
end

local exit_overlay_menu_ref = G.FUNCS.exit_overlay_menu
---@diagnostic disable-next-line: duplicate-set-field
function G.FUNCS:exit_overlay_menu()
	-- Saves username if user presses ESC instead of Enter
	if G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("username_input_box") ~= nil then
		MP.UTILS.save_username(MP.LOBBY.username)
	end

	exit_overlay_menu_ref(self)
end

local mods_button_ref = G.FUNCS.mods_button
function G.FUNCS.mods_button(arg_736_0)
	if G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("username_input_box") ~= nil then
		MP.UTILS.save_username(MP.LOBBY.username)
	end

	mods_button_ref(arg_736_0)
end

function G.UIDEF.multiplayer_deck()
	return G.UIDEF.challenge_description(
		get_challenge_int_from_id(MP.Rulesets[MP.LOBBY.config.ruleset].challenge_deck),
		nil,
		false
	)
end
