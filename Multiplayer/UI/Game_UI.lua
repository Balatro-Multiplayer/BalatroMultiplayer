--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD GAME UI-----------------------

local create_UIBox_options_ref = create_UIBox_options
---@diagnostic disable-next-line: lowercase-global
function create_UIBox_options()
	if G.LOBBY.code then
		local current_seed = nil
		local main_menu = nil
		local your_collection = nil
		local credits = nil

		G.E_MANAGER:add_event(Event({
			blockable = false,
			func = function()
				G.REFRESH_ALERTS = true
				return true
			end,
		}))

		if G.STAGE == G.STAGES.RUN then
			main_menu = UIBox_button({
				label = { "Return to Lobby" },
				button = "return_to_lobby",
				minw = 5,
			})
			your_collection = UIBox_button({
				label = { localize("b_collection") },
				button = "your_collection",
				minw = 5,
				id = "your_collection",
			})
			current_seed = {
				n = G.UIT.R,
				config = { align = "cm", padding = 0.05 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", padding = 0 },
						nodes = {
							{
								n = G.UIT.T,
								config = { text = localize("b_seed") .. ": ", scale = 0.4, colour = G.C.WHITE },
							},
						},
					},
					{
						n = G.UIT.C,
						config = { align = "cm", padding = 0, minh = 0.8 },
						nodes = {
							{
								n = G.UIT.C,
								config = { align = "cm", padding = 0, minh = 0.8 },
								nodes = {
									{
										n = G.UIT.R,
										config = {
											align = "cm",
											r = 0.1,
											colour = G.GAME.seeded and G.C.RED or G.C.BLACK,
											minw = 1.8,
											minh = 0.5,
											padding = 0.1,
											emboss = 0.05,
										},
										nodes = {
											{
												n = G.UIT.C,
												config = { align = "cm" },
												nodes = {
													{
														n = G.UIT.T,
														config = {
															text = tostring(G.GAME.pseudorandom.seed),
															scale = 0.43,
															colour = G.C.UI.TEXT_LIGHT,
															shadow = true,
														},
													},
												},
											},
										},
									},
								},
							},
						},
					},
					UIBox_button({
						col = true,
						button = "copy_seed",
						label = { localize("b_copy") },
						colour = G.C.BLUE,
						scale = 0.3,
						minw = 1.3,
						minh = 0.5,
					}),
				},
			}
		end
		if G.STAGE == G.STAGES.MAIN_MENU then
			credits = UIBox_button({ label = { localize("b_credits") }, button = "show_credits", minw = 5 })
		end

		local settings = UIBox_button({
			button = "settings",
			label = { localize("b_settings") },
			minw = 5,
			focus_args = { snap_to = true },
		})
		local high_scores = UIBox_button({ label = { localize("b_stats") }, button = "high_scores", minw = 5 })

		local t = create_UIBox_generic_options({
			contents = {
				settings,
				G.GAME.seeded and current_seed or nil,
				main_menu,
				high_scores,
				your_collection,
				credits,
			},
		})
		return t
	else
		return create_UIBox_options_ref()
	end
end

local create_UIBox_blind_choice_ref = create_UIBox_blind_choice
---@diagnostic disable-next-line: lowercase-global
function create_UIBox_blind_choice(type, run_info)
	if G.LOBBY.code then
		if not G.GAME.blind_on_deck then
			G.GAME.blind_on_deck = "Small"
		end
		if not run_info then
			G.GAME.round_resets.blind_states[G.GAME.blind_on_deck] = "Select"
		end

		local disabled = false
		type = type or "Small"

		local blind_choice = {
			config = G.P_BLINDS[G.GAME.round_resets.blind_choices[type]],
		}

		blind_choice.animation =
			AnimatedSprite(0, 0, 1.4, 1.4, G.ANIMATION_ATLAS["blind_chips"], blind_choice.config.pos)
		blind_choice.animation:define_draw_steps({
			{ shader = "dissolve", shadow_height = 0.05 },
			{ shader = "dissolve" },
		})
		local extras = nil
		local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)

		G.GAME.orbital_choices = G.GAME.orbital_choices or {}
		G.GAME.orbital_choices[G.GAME.round_resets.ante] = G.GAME.orbital_choices[G.GAME.round_resets.ante] or {}

		if not G.GAME.orbital_choices[G.GAME.round_resets.ante][type] then
			local _poker_hands = {}
			for k, v in pairs(G.GAME.hands) do
				if v.visible then
					_poker_hands[#_poker_hands + 1] = k
				end
			end

			G.GAME.orbital_choices[G.GAME.round_resets.ante][type] =
				pseudorandom_element(_poker_hands, pseudoseed("orbital"))
		end

		if type == "Small" then
			extras = nil
		elseif type == "Big" then
			extras = nil
		elseif not run_info then
			local dt1 = DynaText({
				string = { { string = "LIFE", colour = G.C.FILTER } },
				colours = { G.C.BLACK },
				scale = 0.55,
				silent = true,
				pop_delay = 4.5,
				shadow = true,
				bump = true,
				maxw = 3,
			})
			local dt2 = DynaText({
				string = { { string = "or", colour = G.C.WHITE } },
				colours = { G.C.CHANCE },
				scale = 0.35,
				silent = true,
				pop_delay = 4.5,
				shadow = true,
				maxw = 3,
			})
			local dt3 = DynaText({
				string = { { string = "DEATH", colour = G.C.FILTER } },
				colours = { G.C.BLACK },
				scale = 0.55,
				silent = true,
				pop_delay = 4.5,
				shadow = true,
				bump = true,
				maxw = 3,
			})
			extras = {
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.07, r = 0.1, colour = { 0, 0, 0, 0.12 }, minw = 2.9 },
						nodes = {
							{
								n = G.UIT.R,
								config = { align = "cm" },
								nodes = {
									{ n = G.UIT.O, config = { object = dt1 } },
								},
							},
							{
								n = G.UIT.R,
								config = { align = "cm" },
								nodes = {
									{ n = G.UIT.O, config = { object = dt2 } },
								},
							},
							{
								n = G.UIT.R,
								config = { align = "cm" },
								nodes = {
									{ n = G.UIT.O, config = { object = dt3 } },
								},
							},
						},
					},
				},
			}
		end
		G.GAME.round_resets.blind_ante = G.GAME.round_resets.blind_ante or G.GAME.round_resets.ante

		local loc_target = localize({
			type = "raw_descriptions",
			key = blind_choice.config.key,
			set = "Blind",
			vars = { localize(G.GAME.current_round.most_played_poker_hand, "poker_hands") },
		})
		local loc_name = localize({ type = "name_text", key = blind_choice.config.key, set = "Blind" })
		local blind_col = get_blind_main_colour(type)
		local blind_amt = get_blind_amount(G.GAME.round_resets.blind_ante)
			* blind_choice.config.mult
			* G.GAME.starting_params.ante_scaling

		if G.GAME.round_resets.blind_choices[type] == "bl_pvp" then
			blind_amt = "????"
		end

		local text_table = loc_target

		local blind_state = G.GAME.round_resets.blind_states[type]
		local _reward = true
		if G.GAME.modifiers.no_blind_reward and G.GAME.modifiers.no_blind_reward[type] then
			---@diagnostic disable-next-line: cast-local-type
			_reward = nil
		end
		if blind_state == "Select" then
			blind_state = "Current"
		end
		local run_info_colour = run_info
			and (
				blind_state == "Defeated" and G.C.GREY
				or blind_state == "Skipped" and G.C.BLUE
				or blind_state == "Upcoming" and G.C.ORANGE
				or blind_state == "Current" and G.C.RED
				or G.C.GOLD
			)
		local t = {
			n = G.UIT.R,
			config = {
				id = type,
				align = "tm",
				func = "blind_choice_handler",
				minh = not run_info and 10 or nil,
				ref_table = { deck = nil, run_info = run_info },
				r = 0.1,
				padding = 0.05,
			},
			nodes = {
				{
					n = G.UIT.R,
					config = {
						align = "cm",
						colour = mix_colours(G.C.BLACK, G.C.L_BLACK, 0.5),
						r = 0.1,
						outline = 1,
						outline_colour = G.C.L_BLACK,
					},
					nodes = {
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0.2 },
							nodes = {
								not run_info and {
									n = G.UIT.R,
									config = {
										id = "select_blind_button",
										align = "cm",
										ref_table = blind_choice.config,
										colour = disabled and G.C.UI.BACKGROUND_INACTIVE or G.C.ORANGE,
										minh = 0.6,
										minw = 2.7,
										padding = 0.07,
										r = 0.1,
										shadow = true,
										hover = true,
										one_press = true,
										button = "select_blind",
									},
									nodes = {
										{
											n = G.UIT.T,
											config = {
												ref_table = G.GAME.round_resets.loc_blind_states,
												ref_value = type,
												scale = 0.45,
												colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT,
												shadow = not disabled,
											},
										},
									},
								} or {
									n = G.UIT.R,
									config = {
										id = "select_blind_button",
										align = "cm",
										ref_table = blind_choice.config,
										colour = run_info_colour,
										minh = 0.6,
										minw = 2.7,
										padding = 0.07,
										r = 0.1,
										emboss = 0.08,
									},
									nodes = {
										{
											n = G.UIT.T,
											config = {
												text = localize(blind_state, "blind_states"),
												scale = 0.45,
												colour = G.C.UI.TEXT_LIGHT,
												shadow = true,
											},
										},
									},
								},
							},
						},
						{
							n = G.UIT.R,
							config = { id = "blind_name", align = "cm", padding = 0.07 },
							nodes = {
								{
									n = G.UIT.R,
									config = {
										align = "cm",
										r = 0.1,
										outline = 1,
										outline_colour = blind_col,
										colour = darken(blind_col, 0.3),
										minw = 2.9,
										emboss = 0.1,
										padding = 0.07,
										line_emboss = 1,
									},
									nodes = {
										{
											n = G.UIT.O,
											config = {
												object = DynaText({
													string = loc_name,
													colours = { disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE },
													shadow = not disabled,
													float = not disabled,
													y_offset = -4,
													scale = 0.45,
													maxw = 2.8,
												}),
											},
										},
									},
								},
							},
						},
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0.05 },
							nodes = {
								{
									n = G.UIT.R,
									config = { id = "blind_desc", align = "cm", padding = 0.05 },
									nodes = {
										{
											n = G.UIT.R,
											config = { align = "cm" },
											nodes = {
												{
													n = G.UIT.R,
													config = { align = "cm", minh = 1.5 },
													nodes = {
														{ n = G.UIT.O, config = { object = blind_choice.animation } },
													},
												},
												text_table and text_table[1] and {
													n = G.UIT.R,
													config = {
														align = "cm",
														minh = 0.7,
														padding = 0.05,
														minw = 2.9,
													},
													nodes = {
														text_table[1]
																and {
																	n = G.UIT.R,
																	config = { align = "cm", maxw = 2.8 },
																	nodes = {
																		{
																			n = G.UIT.T,
																			config = {
																				id = blind_choice.config.key,
																				ref_table = { val = "" },
																				ref_value = "val",
																				scale = 0.32,
																				colour = disabled
																						and G.C.UI.TEXT_INACTIVE
																					or G.C.WHITE,
																				shadow = not disabled,
																				func = "HUD_blind_debuff_prefix",
																			},
																		},
																		{
																			n = G.UIT.T,
																			config = {
																				text = text_table[1] or "-",
																				scale = 0.32,
																				colour = disabled
																						and G.C.UI.TEXT_INACTIVE
																					or G.C.WHITE,
																				shadow = not disabled,
																			},
																		},
																	},
																}
															or nil,
														text_table[2] and {
															n = G.UIT.R,
															config = { align = "cm", maxw = 2.8 },
															nodes = {
																{
																	n = G.UIT.T,
																	config = {
																		text = text_table[2] or "-",
																		scale = 0.32,
																		colour = disabled and G.C.UI.TEXT_INACTIVE
																			or G.C.WHITE,
																		shadow = not disabled,
																	},
																},
															},
														} or nil,
													},
												} or nil,
											},
										},
										{
											n = G.UIT.R,
											config = {
												align = "cm",
												r = 0.1,
												padding = 0.05,
												minw = 3.1,
												colour = G.C.BLACK,
												emboss = 0.05,
											},
											nodes = {
												{
													n = G.UIT.R,
													config = { align = "cm", maxw = 3 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = localize("ph_blind_score_at_least"),
																scale = 0.3,
																colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE,
																shadow = not disabled,
															},
														},
													},
												},
												{
													n = G.UIT.R,
													config = { align = "cm", minh = 0.6 },
													nodes = {
														{
															n = G.UIT.O,
															config = {
																w = 0.5,
																h = 0.5,
																colour = G.C.BLUE,
																object = stake_sprite,
																hover = true,
																can_collide = false,
															},
														},
														{ n = G.UIT.B, config = { h = 0.1, w = 0.1 } },
														{
															n = G.UIT.T,
															config = {
																text = number_format(blind_amt),
																scale = score_number_scale(0.9, blind_amt),
																colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.RED,
																shadow = not disabled,
															},
														},
													},
												},
												_reward
														and {
															n = G.UIT.R,
															config = { align = "cm" },
															nodes = {
																{
																	n = G.UIT.T,
																	config = {
																		text = localize("ph_blind_reward"),
																		scale = 0.35,
																		colour = disabled and G.C.UI.TEXT_INACTIVE
																			or G.C.WHITE,
																		shadow = not disabled,
																	},
																},
																{
																	n = G.UIT.T,
																	config = {
																		text = string.rep(
																			---@diagnostic disable-next-line: param-type-mismatch
																			localize("$"),
																			blind_choice.config.dollars
																		) .. "+",
																		scale = 0.35,
																		colour = disabled and G.C.UI.TEXT_INACTIVE
																			or G.C.MONEY,
																		shadow = not disabled,
																	},
																},
															},
														}
													or nil,
											},
										},
									},
								},
							},
						},
					},
				},
				{ n = G.UIT.R, config = { id = "blind_extras", align = "cm" }, nodes = {
					extras,
				} },
			},
		}
		return t
	else
		return create_UIBox_blind_choice_ref(type, run_info)
	end
end

local function update_blind_HUD()
	if G.LOBBY.code then
		G.HUD_blind.alignment.offset.y = -10
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.3,
			blockable = false,
			func = function()
				G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_table = G.LOBBY.enemy
				G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_value = "score"
				G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[1].children[1].config.text =
					"Current enemy score"
				G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[3].children[1].config.text =
					"Enemy hands left: "
				G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object.config.string =
					{ { ref_table = G.LOBBY.enemy, ref_value = "hands" } }
				G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object:update_text()
				G.HUD_blind.alignment.offset.y = 0
				return true
			end,
		}))
	end
end

local function reset_blind_HUD()
	if G.LOBBY.code then
		G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object.config.string =
			{ { ref_table = G.GAME.blind, ref_value = "loc_name" } }
		G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:update_text()
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_table = G.GAME.blind
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_value = "chip_text"
		G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[1].children[1].config.text =
			localize("ph_blind_score_at_least")
		G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[3].children[1].config.text =
			localize("ph_blind_reward")
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object.config.string =
			{ { ref_table = G.GAME.current_round, ref_value = "dollars_to_be_earned" } }
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object:update_text()
	end
end

function G.FUNCS.mp_toggle_ready(e)
	G.MULTIPLAYER_GAME.ready_blind = not G.MULTIPLAYER_GAME.ready_blind
	G.MULTIPLAYER_GAME.ready_blind_text = G.MULTIPLAYER_GAME.ready_blind and "Unready" or "Ready"

	if G.MULTIPLAYER_GAME.ready_blind then
		G.MULTIPLAYER.ready_blind()
	else
		G.MULTIPLAYER.unready_blind()
	end
end

function G.FUNCS.mp_cfg_ready_blind_button(e)
	-- Override next round button
	e.config.ref_table = G.FUNCS
	e.config.button = "mp_toggle_ready"
	e.config.colour = G.MULTIPLAYER_GAME.ready_blind and G.C.GREEN or G.C.RED
	e.config.one_press = false
end

local update_draw_to_hand_ref = Game.update_draw_to_hand
function Game:update_draw_to_hand(dt)
	if G.LOBBY.code then
		if
			not G.STATE_COMPLETE
			and G.GAME.current_round.hands_played == 0
			and G.GAME.current_round.discards_used == 0
			and G.GAME.facing_blind
		then
			if G.GAME.blind.name == "Your Nemesis" then
				G.E_MANAGER:add_event(Event({
					trigger = "after",
					delay = 1,
					blockable = false,
					func = function()
						G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:pop_out(0)
						update_blind_HUD()
						G.E_MANAGER:add_event(Event({
							trigger = "after",
							delay = 0.45,
							blockable = false,
							func = function()
								G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object.config.string = {
									{
										ref_table = G.LOBBY.is_host and G.LOBBY.guest or G.LOBBY.host,
										ref_value = "username",
									},
								}
								G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:update_text()
								G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:pop_in(0)
								return true
							end,
						}))
						return true
					end,
				}))
			end
		end
	end
	update_draw_to_hand_ref(self, dt)
end

local blind_defeat_ref = Blind.defeat
function Blind:defeat(silent)
	blind_defeat_ref(self, silent)
	reset_blind_HUD()
	G.MULTIPLAYER.play_hand(0, G.GAME.round_resets.hands)
end

local update_shop_ref = Game.update_shop
function Game:update_shop(dt)
	if not G.STATE_COMPLETE then
		G.MULTIPLAYER_GAME.ready_blind = false
		G.MULTIPLAYER_GAME.ready_blind_text = "Ready"
	end
	update_shop_ref(self, dt)
end

local ui_def_shop_ref = G.UIDEF.shop
---@diagnostic disable-next-line: duplicate-set-field
function G.UIDEF.shop()
	-- Only modify the shop if not in a singleplayer game
	if not G.LOBBY.connected or not G.LOBBY.code then
		return ui_def_shop_ref()
	end

	local t = ui_def_shop_ref()

	local inner_table = t.nodes[1].nodes[1].nodes[1].nodes

	local next_round_button = inner_table[1].nodes[1].nodes[1].nodes[1]
	next_round_button.config.func = "mp_cfg_ready_blind_button"

	-- Text inside the button
	next_round_button.nodes[1].nodes = {
		{
			n = G.UIT.R,
			config = { align = "cm" },
			nodes = {
				{
					n = G.UIT.T,
					config = {
						ref_table = G.MULTIPLAYER_GAME,
						ref_value = "ready_blind_text",
						scale = 0.65,
						colour = G.C.WHITE,
						shadow = true,
					},
				},
			},
		},
	}

	return t
end

local update_hand_played_ref = Game.update_hand_played
---@diagnostic disable-next-line: duplicate-set-field
function Game:update_hand_played(dt)
	-- Ignore for singleplayer or regular blinds
	if not G.LOBBY.connected or not G.LOBBY.code or not G.GAME.blind.boss then
		update_hand_played_ref(self, dt)
		return
	end

	if self.buttons then
		self.buttons:remove()
		self.buttons = nil
	end
	if self.shop then
		self.shop:remove()
		self.shop = nil
	end

	if not G.STATE_COMPLETE then
		G.STATE_COMPLETE = true
		G.E_MANAGER:add_event(Event({
			trigger = "immediate",
			func = function()
				G.MULTIPLAYER.play_hand(G.GAME.chips, G.GAME.current_round.hands_left)
				-- Set blind chips to enemy score
				G.GAME.blind.chips = G.LOBBY.enemy.score
				-- For now, never advance to next round
				if G.GAME.current_round.hands_left < 1 then
					if G.hand.cards[1] then
						attention_text({
							scale = 0.8,
							text = "Waiting for enemy to finish...",
							hold = 5,
							align = "cm",
							offset = { x = 0, y = -1.5 },
							major = G.play,
						})
						G.FUNCS.draw_from_hand_to_discard()
					end

					G.MULTIPLAYER_GAME.processed_round_done = true
				else
					G.STATE_COMPLETE = false
					G.STATE = G.STATES.DRAW_TO_HAND
				end

				return true
			end,
		}))
	end
end

local can_play_ref = G.FUNCS.can_play
G.FUNCS.can_play = function(e)
	if G.GAME.current_round.hands_left <= 0 then
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
		e.config.button = nil
	else
		can_play_ref(e)
	end
end

local update_new_round_ref = Game.update_new_round
function Game:update_new_round(dt)
	if G.LOBBY.code then
		-- Prevent player from losing
		if G.GAME.chips - G.GAME.blind.chips < 0 then
			G.GAME.blind.chips = -1
		end

		-- Prevent player from winning
		G.GAME.win_ante = 999

		update_new_round_ref(self, dt)

		-- Reset ante number
		G.GAME.win_ante = 8
		return
	end
	update_new_round_ref(self, dt)
end

local start_run_ref = Game.start_run
function Game:start_run(args)
	if not G.LOBBY.connected or not G.LOBBY.code then
		start_run_ref(self, args)
		return
	end

	start_run_ref(self, args)

	local scale = 0.4
	local hud_ante = G.HUD:get_UIE_by_ID("hud_ante")
	hud_ante.children[1].children[1].config.text = "Lives"

	-- Set lives number
	hud_ante.children[2].children[1].config.object = DynaText({
		string = { { ref_table = G.MULTIPLAYER_GAME, ref_value = "lives" } },
		colours = { G.C.IMPORTANT },
		shadow = true,
		font = G.LANGUAGES["en-us"].font,
		scale = 2 * scale,
	})

	-- Remove unnecessary HUD elements
	hud_ante.children[2].children[2] = nil
	hud_ante.children[2].children[3] = nil
	hud_ante.children[2].children[4] = nil

	self.HUD:recalculate()
end

local add_round_eval_row_ref = add_round_eval_row
function add_round_eval_row(config)
	if G.LOBBY.code and config.name == "blind1" and G.GAME.blind.chips == -1 then
		local config = config or {}
		local width = G.round_eval.T.w - 0.51
		local num_dollars = config.dollars or 1
		local scale = 0.9
		delay(0.4)
		G.E_MANAGER:add_event(Event({
			trigger = "before",
			delay = 0.5,
			func = function()
				--Add the far left text and context first:
				local left_text = {}
				local blind_sprite =
					AnimatedSprite(0, 0, 1.2, 1.2, G.ANIMATION_ATLAS["blind_chips"], copy_table(G.GAME.blind.pos))
				blind_sprite:define_draw_steps({
					{ shader = "dissolve", shadow_height = 0.05 },
					{ shader = "dissolve" },
				})
				table.insert(left_text, {
					n = G.UIT.O,
					config = { w = 1.2, h = 1.2, object = blind_sprite, hover = true, can_collide = false },
				})

				table.insert(left_text, {
					n = G.UIT.C,
					config = { padding = 0.05, align = "cm" },
					nodes = {
						{
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								{
									n = G.UIT.O,
									config = {
										object = DynaText({
											string = { G.GAME.blind.boss and " Lost a Life " or " Failed " },
											colours = { G.C.FILTER },
											shadow = true,
											pop_in = 0,
											scale = 0.5 * scale,
											silent = true,
										}),
									},
								},
							},
						},
					},
				})
				local full_row = {
					n = G.UIT.R,
					config = { align = "cm", minw = 5 },
					nodes = {
						{
							n = G.UIT.C,
							config = { padding = 0.05, minw = width * 0.55, minh = 0.61, align = "cl" },
							nodes = left_text,
						},
						{
							n = G.UIT.C,
							config = { padding = 0.05, minw = width * 0.45, align = "cr" },
							nodes = {
								{ n = G.UIT.C, config = { align = "cm", id = "dollar_" .. config.name }, nodes = {} },
							},
						},
					},
				}

				G.GAME.blind:juice_up()
				G.round_eval:add_child(full_row, G.round_eval:get_UIE_by_ID("base_round_eval"))
				play_sound("negative", (1.5 * config.pitch) or 1, 0.2)
				play_sound("whoosh2", 0.9, 0.7)
				if config.card then
					config.card:juice_up(0.7, 0.46)
				end
				return true
			end,
		}))
		local dollar_row = 0
		if num_dollars > 60 then
			G.E_MANAGER:add_event(Event({
				trigger = "before",
				delay = 0.38,
				func = function()
					G.round_eval:add_child({
						n = G.UIT.R,
						config = { align = "cm", id = "dollar_row_" .. (dollar_row + 1) .. "_" .. config.name },
						nodes = {
							{
								n = G.UIT.O,
								config = {
									object = DynaText({
										string = { localize("$") .. num_dollars },
										colours = { G.C.MONEY },
										shadow = true,
										pop_in = 0,
										scale = 0.65,
										float = true,
									}),
								},
							},
						},
					}, G.round_eval:get_UIE_by_ID("dollar_" .. config.name))

					play_sound("coin3", 0.9 + 0.2 * math.random(), 0.7)
					play_sound("coin6", 1.3, 0.8)
					return true
				end,
			}))
		else
			for i = 1, num_dollars or 1 do
				G.E_MANAGER:add_event(Event({
					trigger = "before",
					delay = 0.18 - ((num_dollars > 20 and 0.13) or (num_dollars > 9 and 0.1) or 0),
					func = function()
						if i % 30 == 1 then
							G.round_eval:add_child({
								n = G.UIT.R,
								config = {
									align = "cm",
									id = "dollar_row_" .. (dollar_row + 1) .. "_" .. config.name,
								},
								nodes = {},
							}, G.round_eval:get_UIE_by_ID("dollar_" .. config.name))
							dollar_row = dollar_row + 1
						end

						local r = {
							n = G.UIT.T,
							config = {
								text = localize("$"),
								colour = G.C.MONEY,
								scale = ((num_dollars > 20 and 0.28) or (num_dollars > 9 and 0.43) or 0.58),
								shadow = true,
								hover = true,
								can_collide = false,
								juice = true,
							},
						}
						play_sound("coin3", 0.9 + 0.2 * math.random(), 0.7 - (num_dollars > 20 and 0.2 or 0))

						if config.name == "blind1" then
							G.GAME.current_round.dollars_to_be_earned = G.GAME.current_round.dollars_to_be_earned:sub(2)
						end

						G.round_eval:add_child(
							r,
							G.round_eval:get_UIE_by_ID("dollar_row_" .. dollar_row .. "_" .. config.name)
						)
						G.VIBRATION = G.VIBRATION + 0.4
						return true
					end,
				}))
			end
		end
	else
		add_round_eval_row_ref(config)
	end
end
----------------------------------------------
------------MOD GAME UI END-------------------
