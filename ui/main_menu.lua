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

function G.UIDEF.create_UIBox_create_lobby_button()
	local var_495_0 = 0.75

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
						create_tabs({
							snap_to_nav = true,
							colour = G.C.BOOSTER,
							tabs = {
								{
									label = localize("k_standard"),
									chosen = true,
									tab_definition_function = function()
										return {
											n = G.UIT.ROOT,
											config = {
												emboss = 0.05,
												minh = 6,
												r = 0.1,
												minw = 10,
												align = "tm",
												padding = 0.2,
												colour = G.C.BLACK,
											},
											nodes = {
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														w = 8,
														h = 2,
													},
													nodes = {
														UIBox_button({
															id = "start_standard",
															label = {
																localize("b_start_lobby"),
															},
															colour = G.C.RED,
															button = "start_lobby",
															minw = 5,
														}),
													},
												},
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														minw = 8,
														minh = 4,
													},
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = MP.UTILS.wrapText(
																	localize("k_standard_description"),
																	50
																),
																shadow = true,
																scale = var_495_0 * 0.6,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
											},
										}
									end,
								},
								{
									label = localize("k_vanilla"),
									tab_definition_function = function()
										return {
											n = G.UIT.ROOT,
											config = {
												emboss = 0.05,
												minh = 6,
												r = 0.1,
												minw = 10,
												align = "tm",
												padding = 0.2,
												colour = G.C.BLACK,
											},
											nodes = {
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														w = 8,
														h = 2,
													},
													nodes = {
														UIBox_button({
															id = "start_vanilla",
															label = {
																localize("b_start_lobby"),
															},
															colour = G.C.RED,
															button = "start_lobby",
															minw = 5,
														}),
													},
												},
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														minw = 8,
														minh = 4,
													},
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = MP.UTILS.wrapText(
																	localize("k_vanilla_description"),
																	50
																),
																shadow = true,
																scale = var_495_0 * 0.6,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
											},
										}
									end,
								},
								{
									label = localize("k_weekly"),
									tab_definition_function = function()
										return {
											n = G.UIT.ROOT,
											config = {
												emboss = 0.05,
												minh = 6,
												r = 0.1,
												minw = 10,
												align = "tm",
												padding = 0.2,
												colour = G.C.BLACK,
											},
											nodes = {
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														w = 8,
														h = 2,
													},
													nodes = {
														UIBox_button({
															id = "start_weekly",
															label = {
																localize("k_coming_soon"),
															},
															colour = G.C.RED,
															--button = "start_lobby",
															minw = 5,
														}),
													},
												},
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														minw = 8,
														minh = 4,
													},
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = MP.UTILS.wrapText(
																	localize("k_weekly_description"),
																	50
																),
																shadow = true,
																scale = var_495_0 * 0.6,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
											},
										}
									end,
								},
								{
									label = localize("k_badlatro"),
									tab_definition_function = function()
										return {
											n = G.UIT.ROOT,
											config = {
												emboss = 0.05,
												minh = 6,
												r = 0.1,
												minw = 10,
												align = "Tm",
												padding = 0.2,
												colour = G.C.BLACK,
											},
											nodes = {
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														w = 8,
														h = 2,
													},
													nodes = {
														UIBox_button({
															id = "start_badlatro",
															label = {
																localize("b_start_lobby"),
															},
															colour = G.C.RED,
															button = "start_lobby",
															minw = 5,
														}),
													},
												},
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														minw = 8,
														minh = 4,
													},
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = MP.UTILS.wrapText(
																	localize("k_badlatro_description"),
																	50
																),
																shadow = true,
																scale = var_495_0 * 0.6,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
											},
										}
									end,
								},
							},
						}),
					},
				},
			},
		})
	)
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
		definition = G.UIDEF.create_UIBox_create_lobby_button(),
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
