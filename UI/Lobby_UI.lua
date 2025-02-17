local Disableable_Button = G.MULTIPLAYER.COMPONENTS.Disableable_Button
local Disableable_Toggle = G.MULTIPLAYER.COMPONENTS.Disableable_Toggle
local Disableable_Option_Cycle = G.MULTIPLAYER.COMPONENTS.Disableable_Option_Cycle

-- This needs to have a parameter because its a callback for inputs
local function send_lobby_options(value)
	G.MULTIPLAYER.lobby_options()
end

G.HUD_connection_status = nil

function G.UIDEF.get_connection_status_ui()
	return UIBox({
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
						text = (G.LOBBY.code and (G.localization.misc.dictionary["in_lobby"] or "In Lobby"))
							or (G.LOBBY.connected and (G.localization.misc.dictionary["connected"] or "Connected to Service"))
							or G.localization.misc.dictionary["warn_service"]
							or "WARN: Cannot Find Multiplayer Service",
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
				y = 0.9,
			},
			major = G.ROOM_ATTACH,
		},
	})
end

function G.UIDEF.create_UIBox_view_code()
	local var_495_0 = 0.75

	return (
		create_UIBox_generic_options({
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
								{
									n = G.UIT.T,
									config = {
										text = G.LOBBY.code,
										shadow = true,
										scale = var_495_0 * 0.6,
										colour = G.C.UI.TEXT_LIGHT,
									},
								},
							},
						},
						{
							n = G.UIT.R,
							config = {
								padding = 0,
								align = "cm",
							},
							nodes = {
								UIBox_button({
									label = { G.localization.misc.dictionary["copy_clipboard"] or "Copy to Clipboard" },
									colour = G.C.BLUE,
									button = "copy_to_clipboard",
									minw = 5,
								}),
							},
						},
					},
				},
			},
		})
	)
end

function G.UIDEF.create_UIBox_lobby_menu()
	local text_scale = 0.45

	local t = {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			colour = G.C.CLEAR,
		},
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "bm",
				},
				nodes = {
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
									scale = 0.3,
									shadow = true,
									text = (
										(
												(G.LOBBY.host and G.LOBBY.host.hash)
												and (G.LOBBY.guest and G.LOBBY.guest.hash)
												and (G.LOBBY.host.hash ~= G.LOBBY.guest.hash)
											)
											and (G.localization.misc.dictionary["mod_hash_warning"] or "Players have different mods or mod versions! This can cause problems!")
										or ((G.LOBBY.username == "Guest") and (G.localization.misc.dictionary["set_name"] or "Set your username in the main menu! (Mods > Multiplayer > Config)"))
										or " "
									),
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					} or nil,
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.2,
							r = 0.1,
							emboss = 0.1,
							colour = G.C.L_BLACK,
							mid = true,
						},
						nodes = {
							Disableable_Button({
								id = "lobby_menu_start",
								button = "lobby_start_game",
								colour = G.C.BLUE,
								minw = 3.65,
								minh = 1.55,
								label = { G.localization.misc.dictionary["start"] or "START" },
								disabled_text = G.LOBBY.is_host and {
									G.localization.misc.dictionary["wait_for"] or "WAITING FOR",
									G.localization.misc.dictionary["players"] or "PLAYERS",
								} or {
									G.localization.misc.dictionary["wait_for"] or "WAITING FOR",
									G.localization.misc.dictionary["host_start"] or "HOST TO START",
								},
								scale = text_scale * 2,
								col = true,
								enabled_ref_table = G.LOBBY,
								enabled_ref_value = "ready_to_start",
							}),
							{
								n = G.UIT.C,
								config = {
									align = "cm",
								},
								nodes = {
									UIBox_button({
										button = "lobby_options",
										colour = G.C.ORANGE,
										minw = 3.15,
										minh = 1.35,
										label = {
											G.localization.misc.dictionary["lobby_options_cap"] or "LOBBY OPTIONS",
										},
										scale = text_scale * 1.2,
										col = true,
									}),
									{
										n = G.UIT.C,
										config = {
											align = "cm",
											minw = 0.2,
										},
										nodes = {},
									},
									G.LOBBY.is_host and Disableable_Button({
										id = "lobby_choose_deck",
										button = "lobby_choose_deck",
										colour = G.C.PURPLE,
										minw = 2.15,
										minh = 1.35,
										label = {
											G.LOBBY.config.back,
											localize({
												type = "name_text",
												key = SMODS.stake_from_index(
													type(G.LOBBY.config.stake) == "string"
															and tonumber(G.LOBBY.config.stake)
														or G.LOBBY.config.stake
												),
												set = "Stake",
											}),
										},
										scale = text_scale * 1.2,
										col = true,
										enabled_ref_table = G.LOBBY,
										enabled_ref_value = "is_host",
									}) or Disableable_Button({
										id = "lobby_choose_deck",
										button = "lobby_choose_deck",
										colour = G.C.PURPLE,
										minw = 2.15,
										minh = 1.35,
										label = {
											G.LOBBY.config.back,
											localize({
												type = "name_text",
												key = SMODS.stake_from_index(
													type(G.LOBBY.config.stake) == "string"
															and tonumber(G.LOBBY.config.stake)
														or G.LOBBY.config.stake
												),
												set = "Stake",
											}),
										},
										scale = text_scale * 1.2,
										col = true,
										enabled_ref_table = G.LOBBY.config,
										enabled_ref_value = "different_decks",
									}),
									{
										n = G.UIT.C,
										config = {
											align = "cm",
											minw = 0.2,
										},
										nodes = {},
									},
									{
										n = G.UIT.C,
										config = {
											align = "tm",
											minw = 2.65,
										},
										nodes = {
											{
												n = G.UIT.R,
												config = {
													padding = 0.15,
													align = "cm",
												},
												nodes = {
													{
														n = G.UIT.T,
														config = {
															text = G.localization.misc.dictionary["connect_player"]
																or "Connected Players:",
															shadow = true,
															scale = text_scale * 0.8,
															colour = G.C.UI.TEXT_LIGHT,
														},
													},
												},
											},
											G.LOBBY.host.username and {
												n = G.UIT.R,
												config = {
													padding = 0.1,
													align = "cm",
												},
												nodes = {
													{
														n = G.UIT.T,
														config = {
															ref_table = G.LOBBY.host,
															ref_value = "username",
															shadow = true,
															scale = text_scale * 0.8,
															colour = G.C.UI.TEXT_LIGHT,
														},
													},
													{
														n = G.UIT.B,
														config = {
															w = 0.1,
															h = 0.1,
														},
													},
													G.LOBBY.host.hash and UIBox_button({
														id = "host_hash",
														button = "view_host_hash",
														label = { G.LOBBY.host.hash },
														minw = 0.75,
														minh = 0.3,
														scale = 0.25,
														shadow = false,
														colour = G.C.PURPLE,
														col = true,
													}),
												},
											} or nil,
											G.LOBBY.guest.username and {
												n = G.UIT.R,
												config = {
													padding = 0.1,
													align = "cm",
												},
												nodes = {
													{
														n = G.UIT.T,
														config = {
															ref_table = G.LOBBY.guest,
															ref_value = "username",
															shadow = true,
															scale = text_scale * 0.8,
															colour = G.C.UI.TEXT_LIGHT,
														},
													},
													{
														n = G.UIT.B,
														config = {
															w = 0.1,
															h = 0.1,
														},
													},
													G.LOBBY.guest.hash and UIBox_button({
														id = "host_guest",
														button = "view_guest_hash",
														label = { G.LOBBY.guest.hash },
														minw = 0.75,
														minh = 0.3,
														scale = 0.25,
														shadow = false,
														colour = G.C.PURPLE,
														col = true,
													}),
												},
											} or nil,
										},
									},
									{
										n = G.UIT.C,
										config = {
											align = "cm",
											minw = 0.2,
										},
										nodes = {},
									},
									UIBox_button({
										button = "view_code",
										colour = G.C.PALE_GREEN,
										minw = 3.15,
										minh = 1.35,
										label = { G.localization.misc.dictionary["view_code"] or "VIEW CODE" },
										scale = text_scale * 1.2,
										col = true,
									}),
								},
							},
							UIBox_button({
								id = "lobby_menu_leave",
								button = "lobby_leave",
								colour = G.C.RED,
								minw = 3.65,
								minh = 1.55,
								label = { G.localization.misc.dictionary["leave"] or "LEAVE" },
								scale = text_scale * 1.5,
								col = true,
							}),
						},
					},
				},
			},
		},
	}
	return t
end

function G.UIDEF.create_UIBox_lobby_options()
	return create_UIBox_generic_options({
		contents = {
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
				},
				nodes = {
					not G.LOBBY.is_host and {
						n = G.UIT.R,
						config = {
							padding = 0.3,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									scale = 0.6,
									shadow = true,
									text = G.localization.misc.dictionary["opts_only_host"]
										or "Only the Lobby Host can change these options",
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					} or nil,
					create_tabs({
						snap_to_nav = true,
						colour = G.C.BOOSTER,
						tabs = {
							{
								label = G.localization.misc.dictionary["lobby_options"] or "Lobby Options",
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
													padding = 0,
													align = "cr",
												},
												nodes = {
													Disableable_Toggle({
														id = "gold_on_life_loss_toggle",
														enabled_ref_table = G.LOBBY,
														enabled_ref_value = "is_host",
														label = G.localization.misc.dictionary["opts_cb_money"]
															or "Give comeback gold on life loss",
														ref_table = G.LOBBY.config,
														ref_value = "gold_on_life_loss",
														callback = send_lobby_options,
													}),
												},
											},
											{
												n = G.UIT.R,
												config = {
													padding = 0,
													align = "cr",
												},
												nodes = {
													Disableable_Toggle({
														id = "no_gold_on_round_loss_toggle",
														enabled_ref_table = G.LOBBY,
														enabled_ref_value = "is_host",
														label = G.localization.misc.dictionary["opts_no_gold_on_loss"]
															or "Don't get blind gold on round loss",
														ref_table = G.LOBBY.config,
														ref_value = "no_gold_on_round_loss",
														callback = send_lobby_options,
													}),
												},
											},
											{
												n = G.UIT.R,
												config = {
													padding = 0,
													align = "cr",
												},
												nodes = {
													Disableable_Toggle({
														id = "death_on_round_loss_toggle",
														enabled_ref_table = G.LOBBY,
														enabled_ref_value = "is_host",
														label = G.localization.misc.dictionary["opts_death_on_loss"]
															or "Lose a life on non-PvP round loss",
														ref_table = G.LOBBY.config,
														ref_value = "death_on_round_loss",
														callback = send_lobby_options,
													}),
												},
											},
											{
												n = G.UIT.R,
												config = {
													padding = 0,
													align = "cr",
												},
												nodes = {
													Disableable_Toggle({
														id = "different_seeds_toggle",
														enabled_ref_table = G.LOBBY,
														enabled_ref_value = "is_host",
														label = G.localization.misc.dictionary["opts_diff_seeds"]
															or "Players have different seeds",
														ref_table = G.LOBBY.config,
														ref_value = "different_seeds",
														callback = toggle_different_seeds,
													}),
												},
											},
											{
												n = G.UIT.R,
												config = {
													padding = 0,
													align = "cr",
												},
												nodes = {
													Disableable_Toggle({
														id = "different_decks_toggle",
														enabled_ref_table = G.LOBBY,
														enabled_ref_value = "is_host",
														label = G.localization.misc.dictionary["opts_player_diff_deck"]
															or "Players have different decks",
														ref_table = G.LOBBY.config,
														ref_value = "different_decks",
														callback = send_lobby_options,
													}),
												},
											},
											{
												n = G.UIT.R,
												config = {
													padding = 0,
													align = "cr",
												},
												nodes = {
													Disableable_Toggle({
														id = "multiplayer_jokers_toggle",
														enabled_ref_table = G.LOBBY,
														enabled_ref_value = "is_host",
														label = G.localization.misc.dictionary["opts_multiplayer_jokers"]
															or "Enable Multiplayer Jokers",
														ref_table = G.LOBBY.config,
														ref_value = "multiplayer_jokers",
														callback = send_lobby_options,
													}),
												},
											},
											not G.LOBBY.config.different_seeds
													and {
														n = G.UIT.R,
														config = {
															padding = 0,
															align = "cr",
														},
														nodes = {
															{
																n = G.UIT.C,
																config = {
																	padding = 0,
																	align = "cm",
																},
																nodes = {
																	{
																		n = G.UIT.R,
																		config = {
																			padding = 0.2,
																			align = "cr",
																			func = "display_custom_seed",
																		},
																		nodes = {
																			{
																				n = G.UIT.T,
																				config = {
																					scale = 0.45,
																					text = G.localization.misc.dictionary["current_seed"]
																						or "Current seed: ",
																					colour = G.C.UI.TEXT_LIGHT,
																				},
																			},
																			{
																				n = G.UIT.T,
																				config = {
																					scale = 0.45,
																					text = G.LOBBY.config.custom_seed,
																					colour = G.C.UI.TEXT_LIGHT,
																				},
																			},
																		},
																	},
																	{
																		n = G.UIT.R,
																		config = {
																			padding = 0.2,
																			align = "cr",
																		},
																		nodes = {
																			Disableable_Button({
																				id = "custom_seed_overlay",
																				button = "custom_seed_overlay",
																				colour = G.C.BLUE,
																				minw = 3.65,
																				minh = 0.6,
																				label = {
																					G.localization.misc.dictionary["set_custom_seed"]
																						or "Set Custom Seed",
																				},
																				disabled_text = {
																					G.localization.misc.dictionary["set_custom_seed"]
																						or "Set Custom Seed",
																				},
																				scale = 0.45,
																				col = true,
																				enabled_ref_table = G.LOBBY,
																				enabled_ref_value = "is_host",
																			}),
																			{
																				n = G.UIT.B,
																				config = {
																					w = 0.1,
																					h = 0.1,
																				},
																			},
																			Disableable_Button({
																				id = "custom_seed_reset",
																				button = "custom_seed_reset",
																				colour = G.C.RED,
																				minw = 1.65,
																				minh = 0.6,
																				label = {
																					G.localization.misc.dictionary["reset"]
																						or "Reset",
																				},
																				disabled_text = {
																					G.localization.misc.dictionary["reset"]
																						or "Reset",
																				},
																				scale = 0.45,
																				col = true,
																				enabled_ref_table = G.LOBBY,
																				enabled_ref_value = "is_host",
																			}),
																		},
																	},
																},
															},
														},
													}
												or {
													n = G.UIT.B,
													config = {
														w = 0.1,
														h = 0.1,
													},
												},
										},
									}
								end,
							},
							{
								label = G.localization.misc.dictionary["opts_gm"] or "Gamemode Modifiers",
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
													padding = 0,
													align = "cm",
												},
												nodes = {
													Disableable_Option_Cycle({
														id = "starting_lives_option",
														enabled_ref_table = G.LOBBY,
														enabled_ref_value = "is_host",
														label = G.localization.misc.dictionary["opts_lives"] or "Lives",
														options = {
															1,
															2,
															3,
															4,
															5,
															6,
															7,
															8,
															9,
															10,
															11,
															12,
															13,
															14,
															15,
															16,
														},
														current_option = G.LOBBY.config.starting_lives,
														opt_callback = "change_starting_lives",
													}),
													G.LOBBY.type == "showdown"
															and Disableable_Option_Cycle({
																id = "showdown_starting_antes_option",
																enabled_ref_table = G.LOBBY,
																enabled_ref_value = "is_host",
																label = G.localization.misc.dictionary["opts_start_antes"]
																	or "Starting Antes",
																options = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
																current_option = G.LOBBY.config.showdown_starting_antes,
																opt_callback = "change_showdown_starting_antes",
															})
														or nil,
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
end

function G.FUNCS.display_custom_seed(e)
	local display = G.LOBBY.config.custom_seed == "random" and G.localization.misc.dictionary["random"]
		or G.LOBBY.config.custom_seed
	if display ~= e.children[1].config.text then
		e.children[2].config.text = display
		e.UIBox:recalculate(true)
	end
end

function G.UIDEF.create_UIBox_custom_seed_overlay()
	return create_UIBox_generic_options({
		back_func = "lobby_options",
		contents = {
			{
				n = G.UIT.R,
				config = { align = "cm", colour = G.C.CLEAR },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", minw = 0.1 },
						nodes = {
							create_text_input({
								max_length = 8,
								all_caps = true,
								ref_table = G.LOBBY,
								ref_value = "temp_seed",
								prompt_text = localize("k_enter_seed"),
								callback = function(val)
									G.LOBBY.config.custom_seed = G.LOBBY.temp_seed
									send_lobby_options()
								end,
							}),
							{
								n = G.UIT.B,
								config = { w = 0.1, h = 0.1 },
							},
							{
								n = G.UIT.T,
								config = {
									scale = 0.3,
									text = G.localization.misc.dictionary["enter_to_save"] or "Press enter to save",
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					},
				},
			},
		},
	})
end

function G.UIDEF.create_UIBox_view_hash(type)
	return (
		create_UIBox_generic_options({
			contents = {
				{
					n = G.UIT.C,
					config = {
						padding = 0.2,
						align = "cm",
					},
					nodes = hash_str_to_view(type == "host" and G.LOBBY.host.hash_str or G.LOBBY.guest.hash_str),
				},
			},
		})
	)
end

function hash_str_to_view(str)
	local t = {}

	if not str then
		return t
	end

	for s in str:gmatch("[^;]+") do
		table.insert(t, {
			n = G.UIT.R,
			config = {
				padding = 0.05,
				align = "cm",
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = s,
						shadow = true,
						scale = 0.45,
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		})
	end
	return t
end

G.FUNCS.view_host_hash = function(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_view_hash("host"),
	})
end

G.FUNCS.view_guest_hash = function(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_view_hash("guest"),
	})
end

function toggle_different_seeds()
	G.FUNCS.lobby_options()
	send_lobby_options()
end

G.FUNCS.change_starting_lives = function(args)
	G.LOBBY.config.starting_lives = args.to_val
	send_lobby_options()
end

G.FUNCS.change_showdown_starting_antes = function(args)
	G.LOBBY.config.showdown_starting_antes = args.to_val
	send_lobby_options()
end

function G.FUNCS.get_lobby_main_menu_UI(e)
	return UIBox({
		definition = G.UIDEF.create_UIBox_lobby_menu(),
		config = {
			align = "bmi",
			offset = {
				x = 0,
				y = 10,
			},
			major = G.ROOM_ATTACH,
			bond = "Weak",
		},
	})
end

---@type fun(e: table | nil, args: { deck: string, stake: number | nil, seed: string | nil })
function G.FUNCS.lobby_start_run(e, args)
	if G.LOBBY.config.different_decks == false then
		G.FUNCS.copy_host_deck()
	end

	local challenge = G.CHALLENGES[get_challenge_int_from_id("c_multiplayer_1")]

	G.FUNCS.start_run(e, {
		mp_start = true,
		challenge = challenge,
		stake = tonumber(G.LOBBY.deck.stake),
		seed = args.seed,
	})
end

function G.FUNCS.copy_host_deck()
	G.LOBBY.deck.back = G.LOBBY.config.back
	G.LOBBY.deck.sleeve = G.LOBBY.config.sleeve
	G.LOBBY.deck.stake = G.LOBBY.config.stake
end

function G.FUNCS.lobby_start_game(e)
	G.MULTIPLAYER.start_game()
end

function G.FUNCS.lobby_options(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_lobby_options(),
	})
end

function G.FUNCS.view_code(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_view_code(),
	})
end

function G.FUNCS.lobby_leave(e)
	G.LOBBY.code = nil
	G.MULTIPLAYER.leave_lobby()
	G.MULTIPLAYER.update_connection_status()
end

function G.FUNCS.lobby_choose_deck(e)
	G.FUNCS.setup_run(e)
	if G.OVERLAY_MENU then
		G.OVERLAY_MENU:get_UIE_by_ID("run_setup_seed"):remove()
	end
end

local start_run_ref = G.FUNCS.start_run
G.FUNCS.start_run = function(e, args)
	if G.LOBBY.code then
		if not args.mp_start then
			G.FUNCS.exit_overlay_menu()
			local chosen_stake = args.stake
			if G.MULTIPLAYER.MAX_STAKE > 0 and chosen_stake > G.MULTIPLAYER.MAX_STAKE then
				G.MULTIPLAYER.UTILS.overlay_message(
					"Selected stake is incompatible with Multiplayer, stake set to "
						.. SMODS.stake_from_index(G.MULTIPLAYER.MAX_STAKE)
				)
				chosen_stake = G.MULTIPLAYER.MAX_STAKE
			end
			if G.LOBBY.is_host then
				G.LOBBY.config.back = (args.deck and args.deck.name) or G.GAME.viewed_back.name
				G.LOBBY.config.stake = chosen_stake
				G.LOBBY.config.sleeve = G.viewed_sleeve
				send_lobby_options()
			end
			G.LOBBY.deck.back = (args.deck and args.deck.name) or G.GAME.viewed_back.name
			G.LOBBY.deck.stake = chosen_stake
			G.LOBBY.deck.sleeve = G.viewed_sleeve
		else
			local back = args.challenge
			back.deck.type = G.LOBBY.deck.back
			back.sleeve = G.LOBBY.deck.sleeve
			start_run_ref(e, {
				challenge = back,
				stake = tonumber(G.LOBBY.deck.stake),
				seed = args.seed,
			})
		end
	else
		start_run_ref(e, args)
	end
end

function G.FUNCS.display_lobby_main_menu_UI(e)
	G.MAIN_MENU_UI = G.FUNCS.get_lobby_main_menu_UI(e)
	G.MAIN_MENU_UI.alignment.offset.y = 0
	G.MAIN_MENU_UI:align_to_major()

	G.CONTROLLER:snap_to({ node = G.MAIN_MENU_UI:get_UIE_by_ID("lobby_menu_start") })
end

function G.FUNCS.return_to_lobby()
	G.MULTIPLAYER.stop_game()
end

function G.FUNCS.custom_seed_overlay(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_custom_seed_overlay(),
	})
end

function G.FUNCS.custom_seed_reset(e)
	G.LOBBY.config.custom_seed = "random"
	send_lobby_options()
end

local set_main_menu_UI_ref = set_main_menu_UI
---@diagnostic disable-next-line: lowercase-global
function set_main_menu_UI()
	if G.LOBBY.code then
		G.FUNCS.display_lobby_main_menu_UI()
	else
		set_main_menu_UI_ref()
	end
end

local in_lobby = false
local gameUpdateRef = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	if (G.LOBBY.code and not in_lobby) or (not G.LOBBY.code and in_lobby) then
		in_lobby = not in_lobby
		G.F_NO_SAVING = in_lobby
		self.FUNCS.go_to_menu()
		reset_game_states()
	end
	gameUpdateRef(self, dt)
end
