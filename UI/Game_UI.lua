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
				label = { G.localization.misc.dictionary["return_lobby"] or "Return to Lobby" },
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

		local blind_atlas = "blind_chips"
		if blind_choice.config and blind_choice.config.atlas then
			blind_atlas = blind_choice.config.atlas
		end
		blind_choice.animation = AnimatedSprite(0, 0, 1.4, 1.4, G.ANIMATION_ATLAS[blind_atlas], blind_choice.config.pos)
		blind_choice.animation:define_draw_steps({
			{ shader = "dissolve", shadow_height = 0.05 },
			{ shader = "dissolve" },
		})
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

		if G.GAME.round_resets.blind_choices[type] == "bl_pvp" then
			local dt1 = DynaText({
				string = { { string = G.localization.misc.dictionary["bl_life"] or "LIFE", colour = G.C.FILTER } },
				colours = { G.C.BLACK },
				scale = 0.55,
				silent = true,
				pop_delay = 4.5,
				shadow = true,
				bump = true,
				maxw = 3,
			})
			local dt2 = DynaText({
				string = { { string = G.localization.misc.dictionary["bl_or"] or "or", colour = G.C.WHITE } },
				colours = { G.C.CHANCE },
				scale = 0.35,
				silent = true,
				pop_delay = 4.5,
				shadow = true,
				maxw = 3,
			})
			local dt3 = DynaText({
				string = { { string = G.localization.misc.dictionary["bl_death"] or "DEATH", colour = G.C.FILTER } },
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
		elseif type == "Small" then
			extras = create_UIBox_blind_tag(type, run_info)
		elseif type == "Big" then
			extras = create_UIBox_blind_tag(type, run_info)
		else
			extras = nil
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
										func = G.GAME.round_resets.blind_choices[type] == "bl_pvp"
												and "pvp_ready_button"
											or nil,
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

G.FUNCS.blind_choice_handler = function(e)
	if
		not e.config.ref_table.run_info
		and G.blind_select
		and G.blind_select.VT.y < 10
		and e.config.id
		and G.blind_select_opts[string.lower(e.config.id)]
	then
		if e.UIBox.role.xy_bond ~= "Weak" then
			e.UIBox:set_role({ xy_bond = "Weak" })
		end
		if
			(e.config.ref_table.deck ~= "on" and e.config.id == G.GAME.blind_on_deck)
			or (e.config.ref_table.deck ~= "off" and e.config.id ~= G.GAME.blind_on_deck)
		then
			local _blind_choice = G.blind_select_opts[string.lower(e.config.id)]
			local _top_button = e.UIBox:get_UIE_by_ID("select_blind_button")
			local _border = e.UIBox.UIRoot.children[1].children[1]
			local _tag = e.UIBox:get_UIE_by_ID("tag_" .. e.config.id)
			local _tag_container = e.UIBox:get_UIE_by_ID("tag_container")
			if
				_tag_container
				and not G.SETTINGS.tutorial_complete
				and not G.SETTINGS.tutorial_progress.completed_parts["shop_1"]
			then
				_tag_container.states.visible = false
			elseif _tag_container then
				_tag_container.states.visible = true
			end
			if e.config.id == G.GAME.blind_on_deck then
				e.config.ref_table.deck = "on"
				e.config.draw_after = false
				e.config.colour = G.C.CLEAR
				_border.parent.config.outline = 2
				_border.parent.config.outline_colour = G.C.UI.TRANSPARENT_DARK
				_border.config.outline_colour = _border.config.outline and _border.config.outline_colour
					or get_blind_main_colour(e.config.id)
				_border.config.outline = 1.5
				_blind_choice.alignment.offset.y = -0.9
				if _tag and _tag_container then
					_tag_container.children[2].config.draw_after = false
					_tag_container.children[2].config.colour = G.C.BLACK
					_tag.children[2].config.button = "skip_blind"
					_tag.config.outline_colour = adjust_alpha(G.C.BLUE, 0.5)
					_tag.children[2].config.hover = true
					_tag.children[2].config.colour = G.C.RED
					_tag.children[2].children[1].config.colour = G.C.UI.TEXT_LIGHT
					local _sprite = _tag.config.ref_table
					_sprite.config.force_focus = nil
				end
				if _top_button then
					G.E_MANAGER:add_event(Event({
						func = function()
							G.CONTROLLER:snap_to({ node = _top_button })
							return true
						end,
					}))
					if _top_button.config.button ~= "mp_toggle_ready" then
						_top_button.config.button = "select_blind"
					end
					_top_button.config.colour = G.C.FILTER
					_top_button.config.hover = true
					_top_button.children[1].config.colour = G.C.WHITE
				end
			elseif e.config.id ~= G.GAME.blind_on_deck then
				e.config.ref_table.deck = "off"
				e.config.draw_after = true
				e.config.colour = adjust_alpha(
					G.GAME.round_resets.blind_states[e.config.id] == "Skipped"
							and mix_colours(G.C.BLUE, G.C.L_BLACK, 0.1)
						or G.C.L_BLACK,
					0.5
				)
				_border.parent.config.outline = nil
				_border.parent.config.outline_colour = nil
				_border.config.outline_colour = nil
				_border.config.outline = nil
				_blind_choice.alignment.offset.y = -0.2
				if _tag and _tag_container then
					if
						G.GAME.round_resets.blind_states[e.config.id] == "Skipped"
						or G.GAME.round_resets.blind_states[e.config.id] == "Defeated"
					then
						_tag_container.children[2]:set_role({ xy_bond = "Weak" })
						_tag_container.children[2]:align(0, 10)
						_tag_container.children[1]:set_role({ xy_bond = "Weak" })
						_tag_container.children[1]:align(0, 10)
					end
					if G.GAME.round_resets.blind_states[e.config.id] == "Skipped" then
						_blind_choice.children.alert = UIBox({
							definition = create_UIBox_card_alert({
								text_rot = -0.35,
								no_bg = true,
								text = localize("k_skipped_cap"),
								bump_amount = 1,
								scale = 0.9,
								maxw = 3.4,
							}),
							config = {
								align = "tmi",
								offset = { x = 0, y = 2.2 },
								major = _blind_choice,
								parent = _blind_choice,
							},
						})
					end
					_tag.children[2].config.button = nil
					_tag.config.outline_colour = G.C.UI.BACKGROUND_INACTIVE
					_tag.children[2].config.hover = false
					_tag.children[2].config.colour = G.C.UI.BACKGROUND_INACTIVE
					_tag.children[2].children[1].config.colour = G.C.UI.TEXT_INACTIVE
					local _sprite = _tag.config.ref_table
					_sprite.config.force_focus = true
				end
				if _top_button then
					_top_button.config.colour = G.C.UI.BACKGROUND_INACTIVE
					_top_button.config.button = nil
					_top_button.config.hover = false
					_top_button.children[1].config.colour = G.C.UI.TEXT_INACTIVE
				end
			end
		end
	end
end

G.FUNCS.pvp_ready_button = function(e)
	if e.children[1].config.ref_table[e.children[1].config.ref_value] == localize("Select", "blind_states") then
		e.config.button = "mp_toggle_ready"
		e.config.one_press = false
		e.children[1].config.ref_table = G.MULTIPLAYER_GAME
		e.children[1].config.ref_value = "ready_blind_text"
	end
	if e.config.button == "mp_toggle_ready" then
		e.config.colour = (G.MULTIPLAYER_GAME.ready_blind and G.C.GREEN) or G.C.RED
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
				G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_table = G.MULTIPLAYER_GAME.enemy
				G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_value = "score_text"
				G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.func = "multiplayer_blind_chip_UI_scale"
				G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[1].children[1].config.text = G.localization.misc.dictionary["enemy_score"]
					or "Current enemy score"
				G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[3].children[1].config.text = G.localization.misc.dictionary["enemy_hands"]
					or "Enemy hands left:"
				G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object.config.string =
					{ { ref_table = G.MULTIPLAYER_GAME.enemy, ref_value = "hands" } }
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
	sendTraceMessage("Toggling Ready", "MULTIPLAYER")
	G.MULTIPLAYER_GAME.ready_blind = not G.MULTIPLAYER_GAME.ready_blind
	G.MULTIPLAYER_GAME.ready_blind_text = G.MULTIPLAYER_GAME.ready_blind
			and (G.localization.misc.dictionary["unready"] or "Unready")
		or (G.localization.misc.dictionary["ready"] or "Ready")

	if G.MULTIPLAYER_GAME.ready_blind then
		G.MULTIPLAYER.set_location("loc_ready")
		G.MULTIPLAYER.ready_blind(e)
	else
		G.MULTIPLAYER.set_location("loc_selecting")
		G.MULTIPLAYER.unready_blind()
	end
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
			if is_pvp_boss() then
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
end

local update_shop_ref = Game.update_shop
function Game:update_shop(dt)
	if not G.STATE_COMPLETE then
		G.MULTIPLAYER_GAME.ready_blind = false
		G.MULTIPLAYER_GAME.ready_blind_text = G.localization.misc.dictionary["ready"] or "Ready"
		G.MULTIPLAYER_GAME.end_pvp = false
	end
	update_shop_ref(self, dt)
end

local function eval_hand_and_jokers()
	for i = 1, #G.hand.cards do
		--Check for hand doubling
		local reps = { 1 }
		local j = 1
		while j <= #reps do
			local percent = (i - 0.999) / (#G.hand.cards - 0.998) + (j - 1) * 0.1
			if reps[j] ~= 1 then
				card_eval_status_text(
					(reps[j].jokers or reps[j].seals).card,
					"jokers",
					nil,
					nil,
					nil,
					(reps[j].jokers or reps[j].seals)
				)
			end

			--calculate the hand effects
			local effects = { G.hand.cards[i]:get_end_of_round_effect() }
			for k = 1, #G.jokers.cards do
				--calculate the joker individual card effects
				local eval = G.jokers.cards[k]:calculate_joker({
					cardarea = G.hand,
					other_card = G.hand.cards[i],
					individual = true,
					end_of_round = true,
				})
				if eval then
					table.insert(effects, eval)
				end
			end

			if reps[j] == 1 then
				--Check for hand doubling
				--From Red seal
				local eval = eval_card(
					G.hand.cards[i],
					{ end_of_round = true, cardarea = G.hand, repetition = true, repetition_only = true }
				)
				if next(eval) and (next(effects[1]) or #effects > 1) then
					for h = 1, eval.seals.repetitions do
						reps[#reps + 1] = eval
					end
				end

				--from Jokers
				for j = 1, #G.jokers.cards do
					--calculate the joker effects
					local eval = eval_card(G.jokers.cards[j], {
						cardarea = G.hand,
						other_card = G.hand.cards[i],
						repetition = true,
						end_of_round = true,
						card_effects = effects,
					})
					if next(eval) then
						for h = 1, eval.jokers.repetitions do
							reps[#reps + 1] = eval
						end
					end
				end
			end

			for ii = 1, #effects do
				--if this effect came from a joker
				if effects[ii].card then
					G.E_MANAGER:add_event(Event({
						trigger = "immediate",
						func = function()
							effects[ii].card:juice_up(0.7)
							return true
						end,
					}))
				end

				--If dollars
				if effects[ii].h_dollars then
					ease_dollars(effects[ii].h_dollars)
					card_eval_status_text(G.hand.cards[i], "dollars", effects[ii].h_dollars, percent)
				end

				--Any extras
				if effects[ii].extra then
					card_eval_status_text(G.hand.cards[i], "extra", nil, percent, nil, effects[ii].extra)
				end
			end
			j = j + 1
		end
	end
end

local update_hand_played_ref = Game.update_hand_played
---@diagnostic disable-next-line: duplicate-set-field
function Game:update_hand_played(dt)
	-- Ignore for singleplayer or regular blinds
	if not G.LOBBY.connected or not G.LOBBY.code or not is_pvp_boss() then
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
				local card = G.MULTIPLAYER.UTILS.get_joker("j_mp_speedrun")
				G.MULTIPLAYER.play_hand(G.GAME.chips, G.GAME.current_round.hands_left, card ~= nil)
				-- Set blind chips to enemy score
				G.GAME.blind.chips = G.MULTIPLAYER_GAME.enemy.score
				-- For now, never advance to next round
				if G.GAME.current_round.hands_left < 1 then
					attention_text({
						scale = 0.8,
						text = G.localization.misc.dictionary["wait_enemy"] or "Waiting for enemy to finish...",
						hold = 5,
						align = "cm",
						offset = { x = 0, y = -1.5 },
						major = G.play,
					})
					if G.hand.cards[1] then
						eval_hand_and_jokers()
						G.FUNCS.draw_from_hand_to_discard()
					end
				elseif not G.MULTIPLAYER_GAME.end_pvp then
					G.STATE_COMPLETE = false
					G.STATE = G.STATES.DRAW_TO_HAND
				end
				return true
			end,
		}))
	end

	if G.MULTIPLAYER_GAME.end_pvp then
		G.STATE_COMPLETE = false
		G.STATE = G.STATES.NEW_ROUND
		G.MULTIPLAYER_GAME.end_pvp = false
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
	if G.MULTIPLAYER.end_pvp then
		G.FUNCS.draw_from_hand_to_deck()
		G.FUNCS.draw_from_discard_to_deck()
		G.MULTIPLAYER.end_pvp = false
	end
	if G.LOBBY.code and not G.STATE_COMPLETE then
		-- Prevent player from losing
		if to_big(G.GAME.chips) < to_big(G.GAME.blind.chips) and not is_pvp_boss() then
			G.GAME.blind.chips = -1
			G.MULTIPLAYER.fail_round(G.GAME.current_round.hands_played)
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

function G.MULTIPLAYER.end_round()
	G.RESET_BLIND_STATES = true
	G.RESET_JIGGLES = true
	for i = 1, #G.jokers.cards do
		local eval = nil
		eval = G.jokers.cards[i]:calculate_joker({ end_of_round = true, game_over = game_over })
		if eval then
			card_eval_status_text(G.jokers.cards[i], "jokers", nil, nil, nil, eval)
		end
	end
	G.GAME.unused_discards = (G.GAME.unused_discards or 0) + G.GAME.current_round.discards_left
	if G.GAME.blind and G.GAME.blind.config.blind then
		discover_card(G.GAME.blind.config.blind)
	end

	if G.GAME.blind:get_type() == "Boss" then
		local _handname, _played, _order = "High Card", -1, 100
		for k, v in pairs(G.GAME.hands) do
			if v.played > _played or (v.played == _played and _order > v.order) then
				_played = v.played
				_handname = k
			end
		end
		G.GAME.current_round.most_played_poker_hand = _handname
	end

	if G.GAME.blind:get_type() == "Boss" and not G.GAME.seeded and not G.GAME.challenge then
		G.GAME.current_boss_streak = G.GAME.current_boss_streak + 1
		check_and_set_high_score("boss_streak", G.GAME.current_boss_streak)
	end

	if G.GAME.current_round.hands_played == 1 then
		inc_career_stat("c_single_hand_round_streak", 1)
	else
		if not G.GAME.seeded and not G.GAME.challenge then
			G.PROFILES[G.SETTINGS.profile].career_stats.c_single_hand_round_streak = 0
			G:save_settings()
		end
	end

	check_for_unlock({ type = "round_win" })
	set_joker_usage()
	for i = 1, #G.hand.cards do
		--Check for hand doubling
		local reps = { 1 }
		local j = 1
		while j <= #reps do
			local percent = (i - 0.999) / (#G.hand.cards - 0.998) + (j - 1) * 0.1
			if reps[j] ~= 1 then
				card_eval_status_text(
					(reps[j].jokers or reps[j].seals).card,
					"jokers",
					nil,
					nil,
					nil,
					(reps[j].jokers or reps[j].seals)
				)
			end

			--calculate the hand effects
			local effects = { G.hand.cards[i]:get_end_of_round_effect() }
			for k = 1, #G.jokers.cards do
				--calculate the joker individual card effects
				local eval = G.jokers.cards[k]:calculate_joker({
					cardarea = G.hand,
					other_card = G.hand.cards[i],
					individual = true,
					end_of_round = true,
				})
				if eval then
					table.insert(effects, eval)
				end
			end

			if reps[j] == 1 then
				--Check for hand doubling
				--From Red seal
				local eval = eval_card(
					G.hand.cards[i],
					{ end_of_round = true, cardarea = G.hand, repetition = true, repetition_only = true }
				)
				if next(eval) and (next(effects[1]) or #effects > 1) then
					for h = 1, eval.seals.repetitions do
						reps[#reps + 1] = eval
					end
				end

				--from Jokers
				for j = 1, #G.jokers.cards do
					--calculate the joker effects
					local eval = eval_card(G.jokers.cards[j], {
						cardarea = G.hand,
						other_card = G.hand.cards[i],
						repetition = true,
						end_of_round = true,
						card_effects = effects,
					})
					if next(eval) then
						for h = 1, eval.jokers.repetitions do
							reps[#reps + 1] = eval
						end
					end
				end
			end

			for ii = 1, #effects do
				--if this effect came from a joker
				if effects[ii].card then
					G.E_MANAGER:add_event(Event({
						trigger = "immediate",
						func = function()
							effects[ii].card:juice_up(0.7)
							return true
						end,
					}))
				end

				--If dollars
				if effects[ii].h_dollars then
					ease_dollars(effects[ii].h_dollars)
					card_eval_status_text(G.hand.cards[i], "dollars", effects[ii].h_dollars, percent)
				end

				--Any extras
				if effects[ii].extra then
					card_eval_status_text(G.hand.cards[i], "extra", nil, percent, nil, effects[ii].extra)
				end
			end
			j = j + 1
		end
	end
	delay(0.3)

	G.FUNCS.draw_from_hand_to_discard()
	if G.GAME.blind:get_type() == "Boss" then
		G.GAME.voucher_restock = nil
		if G.GAME.modifiers.set_eternal_ante and (G.GAME.round_resets.ante == G.GAME.modifiers.set_eternal_ante) then
			for k, v in ipairs(G.jokers.cards) do
				v:set_eternal(true)
			end
		end
		if
			G.GAME.modifiers.set_joker_slots_ante
			and (G.GAME.round_resets.ante == G.GAME.modifiers.set_joker_slots_ante)
		then
			G.jokers.config.card_limit = 0
		end
		delay(0.4)
		ease_ante(1)
		delay(0.4)
		check_for_unlock({ type = "ante_up", ante = G.GAME.round_resets.ante + 1 })
	end
	G.FUNCS.draw_from_discard_to_deck()
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.3,
		func = function()
			G.STATE = G.STATES.ROUND_EVAL
			G.STATE_COMPLETE = false

			if
				G.GAME.round_resets.blind_states.Small ~= "Defeated"
				and G.GAME.round_resets.blind_states.Small ~= "Skipped"
			then
				G.GAME.round_resets.blind_states.Small = "Defeated"
			elseif
				G.GAME.round_resets.blind_states.Big ~= "Defeated"
				and G.GAME.round_resets.blind_states.Big ~= "Skipped"
			then
				G.GAME.round_resets.blind_states.Big = "Defeated"
			else
				G.GAME.current_round.voucher = get_next_voucher_key()
				G.GAME.round_resets.blind_states.Boss = "Defeated"
				for k, v in ipairs(G.playing_cards) do
					v.ability.played_this_ante = nil
				end
			end

			if G.GAME.round_resets.temp_handsize then
				G.hand:change_size(-G.GAME.round_resets.temp_handsize)
				G.GAME.round_resets.temp_handsize = nil
			end
			if G.GAME.round_resets.temp_reroll_cost then
				G.GAME.round_resets.temp_reroll_cost = nil
				calculate_reroll_cost(true)
			end

			reset_idol_card()
			reset_mail_rank()
			reset_ancient_card()
			reset_castle_card()
			for k, v in ipairs(G.playing_cards) do
				v.ability.discarded = nil
				v.ability.forced_selection = nil
			end
			return true
		end,
	}))
	return true
end

local start_run_ref = Game.start_run
function Game:start_run(args)
	start_run_ref(self, args)

	if not G.LOBBY.connected or not G.LOBBY.code then
		return
	end

	local scale = 0.4
	local hud_ante = G.HUD:get_UIE_by_ID("hud_ante")
	hud_ante.children[1].children[1].config.text = G.localization.misc.dictionary["lives"] or "Lives"

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

local create_UIBox_game_over_ref = create_UIBox_game_over
function create_UIBox_game_over()
	if G.LOBBY.code then
		G.SETTINGS.paused = false
		local eased_red = copy_table(G.GAME.round_resets.ante <= G.GAME.win_ante and G.C.RED or G.C.BLUE)
		eased_red[4] = 0
		ease_value(eased_red, 4, 0.8, nil, nil, true)
		local t = create_UIBox_generic_options({
			bg_colour = eased_red,
			no_back = true,
			padding = 0,
			contents = {
				{
					n = G.UIT.R,
					config = { align = "cm" },
					nodes = {
						{
							n = G.UIT.O,
							config = {
								object = DynaText({
									string = { localize("ph_game_over") },
									colours = { G.C.RED },
									shadow = true,
									float = true,
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
									config = {
										align = "cm",
										padding = 0.05,
										colour = G.C.BLACK,
										emboss = 0.05,
										r = 0.1,
									},
									nodes = {
										{
											n = G.UIT.R,
											config = { align = "cm", padding = 0.08 },
											nodes = {
												create_UIBox_round_scores_row("hand"),
												create_UIBox_round_scores_row("poker_hand"),
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
														create_UIBox_round_scores_row("cards_played", G.C.BLUE),
														create_UIBox_round_scores_row("cards_discarded", G.C.RED),
														create_UIBox_round_scores_row("cards_purchased", G.C.MONEY),
														create_UIBox_round_scores_row("times_rerolled", G.C.GREEN),
														create_UIBox_round_scores_row("new_collection", G.C.WHITE),
														create_UIBox_round_scores_row("seed", G.C.WHITE),
														UIBox_button({
															button = "copy_seed",
															label = { localize("b_copy") },
															colour = G.C.BLUE,
															scale = 0.3,
															minw = 2.3,
															minh = 0.4,
															focus_args = { nav = "wide" },
														}),
													},
												},
												{
													n = G.UIT.C,
													config = { align = "tr", padding = 0.08 },
													nodes = {
														create_UIBox_round_scores_row("furthest_ante", G.C.FILTER),
														create_UIBox_round_scores_row("furthest_round", G.C.FILTER),
														{
															n = G.UIT.R,
															config = { align = "cm", padding = 0.08, minw = 5 },
															nodes = {
																{
																	n = G.UIT.T,
																	config = {
																		text = localize("k_mp_kofi_message")[1],
																		scale = 0.35,
																		colour = G.C.UI.TEXT_LIGHT,
																		col = true,
																	},
																},
															},
														},
														{
															n = G.UIT.R,
															config = { align = "cm", padding = 0.08, minw = 5 },
															nodes = {
																{
																	n = G.UIT.T,
																	config = {
																		text = localize("k_mp_kofi_message")[2],
																		scale = 0.35,
																		colour = G.C.UI.TEXT_LIGHT,
																		col = true,
																	},
																},
															},
														},
														{
															n = G.UIT.R,
															config = { align = "cm", padding = 0.08, minw = 5 },
															nodes = {
																{
																	n = G.UIT.T,
																	config = {
																		text = localize("k_mp_kofi_message")[3],
																		scale = 0.35,
																		colour = G.C.UI.TEXT_LIGHT,
																		col = true,
																	},
																},
															},
														},
														{
															n = G.UIT.R,
															config = { align = "cm", padding = 0.08, minw = 5 },
															nodes = {
																{
																	n = G.UIT.T,
																	config = {
																		text = localize("k_mp_kofi_message")[4],
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
																		maxw = 4.8,
																	},
																	nodes = {
																		{
																			n = G.UIT.T,
																			config = {
																				text = localize("k_mp_kofi_button"),
																				scale = 0.35,
																				colour = G.C.UI.TEXT_LIGHT,
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
									},
								},
								{
									n = G.UIT.R,
									config = { align = "cm", padding = 0.1 },
									nodes = {
										{
											n = G.UIT.R,
											config = {
												id = "from_game_over",
												align = "cm",
												minw = 5,
												padding = 0.1,
												r = 0.1,
												hover = true,
												colour = G.C.RED,
												button = "return_to_lobby",
												shadow = true,
												focus_args = { nav = "wide", snap_to = true },
											},
											nodes = {
												{
													n = G.UIT.R,
													config = { align = "cm", padding = 0, no_fill = true, maxw = 4.8 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = G.localization.misc.dictionary["return_lobby"]
																	or "Return to Lobby",
																scale = 0.5,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
											},
										},
										{
											n = G.UIT.R,
											config = {
												align = "cm",
												minw = 5,
												padding = 0.1,
												r = 0.1,
												hover = true,
												colour = G.C.RED,
												button = "lobby_leave",
												shadow = true,
												focus_args = { nav = "wide" },
											},
											nodes = {
												{
													n = G.UIT.R,
													config = { align = "cm", padding = 0, no_fill = true, maxw = 4.8 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = G.localization.misc.dictionary["leave_lobby"]
																	or "Leave Lobby",
																scale = 0.5,
																colour = G.C.UI.TEXT_LIGHT,
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
							n = G.UIT.R,
							config = { align = "cm" },
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
					},
				},
				{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = { t.nodes[1] } },
			},
		}

		return t
	end
	return create_UIBox_game_over_ref()
end

local create_UIBox_win_ref = create_UIBox_win
function create_UIBox_win()
	if G.LOBBY.code then
		G.SETTINGS.paused = false
		local eased_green = copy_table(G.C.GREEN)
		eased_green[4] = 0
		ease_value(eased_green, 4, 0.5, nil, nil, true)
		local t = create_UIBox_generic_options({
			padding = 0,
			bg_colour = eased_green,
			colour = G.C.BLACK,
			outline_colour = G.C.EDITION,
			no_back = true,
			no_esc = true,
			contents = {
				{
					n = G.UIT.R,
					config = { align = "cm" },
					nodes = {
						{
							n = G.UIT.O,
							config = {
								object = DynaText({
									string = { localize("ph_you_win") },
									colours = { G.C.EDITION },
									shadow = true,
									float = true,
									spacing = 10,
									rotate = true,
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
										create_UIBox_round_scores_row("hand"),
										create_UIBox_round_scores_row("poker_hand"),
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
												create_UIBox_round_scores_row("cards_played", G.C.BLUE),
												create_UIBox_round_scores_row("cards_discarded", G.C.RED),
												create_UIBox_round_scores_row("cards_purchased", G.C.MONEY),
												create_UIBox_round_scores_row("times_rerolled", G.C.GREEN),
												create_UIBox_round_scores_row("new_collection", G.C.WHITE),
												create_UIBox_round_scores_row("seed", G.C.WHITE),
												UIBox_button({
													button = "copy_seed",
													label = { localize("b_copy") },
													colour = G.C.BLUE,
													scale = 0.3,
													minw = 2.3,
													minh = 0.4,
												}),
											},
										},
										{
											n = G.UIT.C,
											config = { align = "tr", padding = 0.08 },
											nodes = {
												create_UIBox_round_scores_row("furthest_ante", G.C.FILTER),
												create_UIBox_round_scores_row("furthest_round", G.C.FILTER),
												{
													n = G.UIT.R,
													config = { align = "cm", padding = 0.08, minw = 5 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = localize("k_mp_kofi_message")[1],
																scale = 0.35,
																colour = G.C.UI.TEXT_LIGHT,
																col = true,
															},
														},
													},
												},
												{
													n = G.UIT.R,
													config = { align = "cm", padding = 0.08, minw = 5 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = localize("k_mp_kofi_message")[2],
																scale = 0.35,
																colour = G.C.UI.TEXT_LIGHT,
																col = true,
															},
														},
													},
												},
												{
													n = G.UIT.R,
													config = { align = "cm", padding = 0.08, minw = 5 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = localize("k_mp_kofi_message")[3],
																scale = 0.35,
																colour = G.C.UI.TEXT_LIGHT,
																col = true,
															},
														},
													},
												},
												{
													n = G.UIT.R,
													config = { align = "cm", padding = 0.08, minw = 5 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = localize("k_mp_kofi_message")[4],
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
																maxw = 4.8,
															},
															nodes = {
																{
																	n = G.UIT.T,
																	config = {
																		text = localize("k_mp_kofi_button"),
																		scale = 0.35,
																		colour = G.C.UI.TEXT_LIGHT,
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
								{
									n = G.UIT.R,
									config = { align = "cm", padding = 0.1 },
									nodes = {
										{
											n = G.UIT.R,
											config = {
												id = "from_game_won",
												align = "cm",
												minw = 5,
												padding = 0.1,
												r = 0.1,
												hover = true,
												colour = G.C.RED,
												button = "return_to_lobby",
												shadow = true,
												focus_args = { nav = "wide", snap_to = true },
											},
											nodes = {
												{
													n = G.UIT.R,
													config = { align = "cm", padding = 0, no_fill = true, maxw = 4.8 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = G.localization.misc.dictionary["return_lobby"]
																	or "Return to Lobby",
																scale = 0.5,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
											},
										},
										{
											n = G.UIT.R,
											config = {
												align = "cm",
												minw = 5,
												padding = 0.1,
												r = 0.1,
												hover = true,
												colour = G.C.RED,
												button = "lobby_leave",
												shadow = true,
												focus_args = { nav = "wide" },
											},
											nodes = {
												{
													n = G.UIT.R,
													config = { align = "cm", padding = 0, no_fill = true, maxw = 4.8 },
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = G.localization.misc.dictionary["leave_lobby"]
																	or "Leave Lobby",
																scale = 0.5,
																colour = G.C.UI.TEXT_LIGHT,
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
		t.config.id = "you_win_UI"
		return t
	end
	return create_UIBox_win_ref()
end

local ease_ante_ref = ease_ante
function ease_ante(mod)
	if not G.LOBBY.code then
		return ease_ante_ref(mod)
	end
	-- Prevents easing multiple times at once
	if G.MULTIPLAYER_GAME.antes_keyed[G.MULTIPLAYER_GAME.ante_key] then
		return
	end
	G.MULTIPLAYER_GAME.antes_keyed[G.MULTIPLAYER_GAME.ante_key] = true
	G.MULTIPLAYER.set_ante(G.GAME.round_resets.ante + mod)
	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		func = function()
			G.GAME.round_resets.ante = G.GAME.round_resets.ante + mod
			check_and_set_high_score("furthest_ante", G.GAME.round_resets.ante)
			return true
		end,
	}))
end

function ease_lives(mod)
	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		func = function()
			if not G.hand_text_area then
				return
			end
			local lives_UI = G.hand_text_area.ante
			mod = mod or 0
			local text = "+"
			local col = G.C.IMPORTANT
			if mod < 0 then
				text = "-"
				col = G.C.RED
			end
			lives_UI.config.object:update()
			G.HUD:recalculate()
			attention_text({
				text = text .. tostring(math.abs(mod)),
				scale = 1,
				hold = 0.7,
				cover = lives_UI.parent,
				cover_colour = col,
				align = "cm",
			})
			play_sound("highlight2", 0.685, 0.2)
			play_sound("generic1")
			return true
		end,
	}))
end

local exit_overlay_menu_ref = G.FUNCS.exit_overlay_menu
---@diagnostic disable-next-line: duplicate-set-field
function G.FUNCS:exit_overlay_menu()
	-- Saves username if user presses ESC instead of Enter
	if G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("username_input_box") ~= nil then
		G.MULTIPLAYER.UTILS.save_username(G.LOBBY.username)
	end

	exit_overlay_menu_ref(self)
end

local mods_button_ref = G.FUNCS.mods_button
function G.FUNCS.mods_button(arg_736_0)
	if G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("username_input_box") ~= nil then
		G.MULTIPLAYER.UTILS.save_username(G.LOBBY.username)
	end

	mods_button_ref(arg_736_0)
end

local reset_blinds_ref = reset_blinds
function reset_blinds()
	reset_blinds_ref()
	if G.LOBBY.code then
		if G.LOBBY.config.gamemode == "attrition" then
			G.GAME.round_resets.blind_choices.Boss = "bl_pvp"
		end
		if
			G.LOBBY.config.gamemode == "showdown"
			and G.GAME.round_resets.ante >= G.LOBBY.config.showdown_starting_antes
		then
			G.GAME.round_resets.blind_choices.Small = "bl_pvp"
			G.GAME.round_resets.blind_choices.Big = "bl_pvp"
			G.GAME.round_resets.blind_choices.Boss = "bl_pvp"
		end
	end
end

local init_game_object_ref = Game.init_game_object
function Game:init_game_object()
	local t = init_game_object_ref(self)
	if G.LOBBY.code then
		if G.LOBBY.config.gamemode == "attrition" then
			t.round_resets.blind_choices.Boss = "bl_pvp"
		end
	end
	return t
end

G.FUNCS.can_skip_booster = function(e)
	if
		G.pack_cards
		and G.pack_cards.cards
		and G.pack_cards.cards[1]
		and (
			G.STATE == G.STATES.PLANET_PACK
			or G.STATE == G.STATES.STANDARD_PACK
			or G.STATE == G.STATES.BUFFOON_PACK
			or (G.hand and G.hand.cards[1])
		)
	then
		e.config.colour = G.C.GREY
		e.config.button = "skip_booster"
	else
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
		e.config.button = nil
	end
end

local update_selecting_hand_ref = Game.update_selecting_hand
function Game:update_selecting_hand(dt)
	if
		G.GAME.current_round.hands_left < G.GAME.round_resets.hands
		and #G.hand.cards < 1
		and #G.deck.cards < 1
		and #G.play.cards < 1
		and G.LOBBY.code
	then
		G.GAME.current_round.hands_left = 0
		if not is_pvp_boss() then
			G.STATE_COMPLETE = false
			G.STATE = G.STATES.NEW_ROUND
		else
			G.MULTIPLAYER.play_hand(G.GAME.chips, 0, false)
			G.STATE_COMPLETE = false
			G.STATE = G.STATES.HAND_PLAYED
		end
		return
	end
	update_selecting_hand_ref(self, dt)

	if G.MULTIPLAYER_GAME.end_pvp then
		G.hand:unhighlight_all()
		G.STATE_COMPLETE = false
		G.STATE = G.STATES.NEW_ROUND
		G.MULTIPLAYER_GAME.end_pvp = false
	end
end

local can_open_ref = G.FUNCS.can_open
G.FUNCS.can_open = function(e)
	if G.MULTIPLAYER_GAME.ready_blind then
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
		e.config.button = nil
		return
	end
	can_open_ref(e)
end

local blind_disable_ref = Blind.disable
function Blind:disable()
	if is_pvp_boss() then
		return
	end
	blind_disable_ref(self)
end

G.FUNCS.multiplayer_blind_chip_UI_scale = function(e)
	local new_score_text = number_format(G.MULTIPLAYER_GAME.enemy.score)
	if G.GAME.blind and G.MULTIPLAYER_GAME.enemy.score and G.MULTIPLAYER_GAME.enemy.score_text ~= new_score_text then
		e.config.scale = scale_number(G.MULTIPLAYER_GAME.enemy.score, 0.7, 100000)
		G.MULTIPLAYER_GAME.enemy.score_text = new_score_text
	end
end

local function show_enemy_location()
	local row_dollars_chips = G.HUD:get_UIE_by_ID("row_dollars_chips")
	if row_dollars_chips then
		row_dollars_chips.children[1]:remove()
		row_dollars_chips.children[1] = nil
		G.HUD:add_child({
			n = G.UIT.C,
			config = { align = "cm", padding = 0.1 },
			nodes = {
				{
					n = G.UIT.C,
					config = { align = "cm", minw = 1.3 },
					nodes = {
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0, maxw = 1.3 },
							nodes = {
								{
									n = G.UIT.T,
									config = {
										text = G.localization.misc.dictionary["enemy_loc_1"] or "Enemy",
										scale = 0.42,
										colour = G.C.UI.TEXT_LIGHT,
										shadow = true,
									},
								},
							},
						},
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0, maxw = 1.3 },
							nodes = {
								{
									n = G.UIT.T,
									config = {
										text = G.localization.misc.dictionary["enemy_loc_2"] or "location",
										scale = 0.42,
										colour = G.C.UI.TEXT_LIGHT,
										shadow = true,
									},
								},
							},
						},
					},
				},
				{
					n = G.UIT.C,
					config = { align = "cm", minw = 3.3, minh = 0.7, r = 0.1, colour = G.C.DYN_UI.BOSS_DARK },
					nodes = {
						{
							n = G.UIT.T,
							config = {
								ref_table = G.MULTIPLAYER_GAME.enemy,
								ref_value = "location",
								scale = 0.35,
								colour = G.C.WHITE,
								id = "chip_UI_count",
								shadow = true,
							},
						},
					},
				},
			},
		}, row_dollars_chips)
	end
end

local function hide_enemy_location()
	local row_dollars_chips = G.HUD:get_UIE_by_ID("row_dollars_chips")
	if row_dollars_chips then
		row_dollars_chips.children[1]:remove()
		row_dollars_chips.children[1] = nil
		G.HUD:add_child({
			n = G.UIT.C,
			config = { align = "cm", padding = 0.1 },
			nodes = {
				{
					n = G.UIT.C,
					config = { align = "cm", minw = 1.3 },
					nodes = {
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0, maxw = 1.3 },
							nodes = {
								{
									n = G.UIT.T,
									config = {
										text = localize("k_round"),
										scale = 0.42,
										colour = G.C.UI.TEXT_LIGHT,
										shadow = true,
									},
								},
							},
						},
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0, maxw = 1.3 },
							nodes = {
								{
									n = G.UIT.T,
									config = {
										text = localize("k_lower_score"),
										scale = 0.42,
										colour = G.C.UI.TEXT_LIGHT,
										shadow = true,
									},
								},
							},
						},
					},
				},
				{
					n = G.UIT.C,
					config = { align = "cm", minw = 3.3, minh = 0.7, r = 0.1, colour = G.C.DYN_UI.BOSS_DARK },
					nodes = {
						{
							n = G.UIT.O,
							config = {
								w = 0.5,
								h = 0.5,
								object = get_stake_sprite(G.GAME.stake or 1, 0.5),
								hover = true,
								can_collide = false,
							},
						},
						{ n = G.UIT.B, config = { w = 0.1, h = 0.1 } },
						{
							n = G.UIT.T,
							config = {
								ref_table = G.GAME,
								ref_value = "chips_text",
								lang = G.LANGUAGES["en-us"],
								scale = 0.85,
								colour = G.C.WHITE,
								id = "chip_UI_count",
								func = "chip_UI_set",
								shadow = true,
							},
						},
					},
				},
			},
		}, row_dollars_chips)
	end
end

local update_shop_ref = Game.update_shop
function Game:update_shop(dt)
	local updated_location = false
	if G.LOBBY.code and not G.STATE_COMPLETE and not updated_location and not G.GAME.USING_RUN then
		G.MULTIPLAYER.set_location("loc_shop")
		show_enemy_location()
	end
	if G.STATE_COMPLETE and updated_location then
		updated_location = false
	end
	update_shop_ref(self, dt)
end

local update_blind_select_ref = Game.update_blind_select
function Game:update_blind_select(dt)
	local updated_location = false
	if G.LOBBY.code and not G.STATE_COMPLETE and not updated_location then
		G.MULTIPLAYER.set_location("loc_selecting")
		show_enemy_location()
		updated_location = true
	end
	if G.STATE_COMPLETE and updated_location then
		updated_location = false
	end
	update_blind_select_ref(self, dt)
end

local select_blind_ref = G.FUNCS.select_blind
function G.FUNCS.select_blind(e)
	G.MULTIPLAYER_GAME.prevent_eval = false
	select_blind_ref(e)
	if G.LOBBY.code then
		G.MULTIPLAYER_GAME.ante_key = tostring(math.random())
		G.MULTIPLAYER.play_hand(0, G.GAME.round_resets.hands, false)
		G.MULTIPLAYER.new_round()
		G.MULTIPLAYER.set_location("loc_playing-" .. (e.config.ref_table.key or e.config.ref_table.name))
		hide_enemy_location()
	end
end

function G.UIDEF.multiplayer_deck()
	return G.UIDEF.challenge_description(get_challenge_int_from_id("c_multiplayer_1"), nil, false)
end

local skip_blind_ref = G.FUNCS.skip_blind
G.FUNCS.skip_blind = function(e)
	skip_blind_ref(e)
	if G.LOBBY.code then
		G.MULTIPLAYER.skip(G.GAME.skips)
	end
end

function G.FUNCS.open_kofi(e)
	love.system.openURL("https://ko-fi.com/virtualized")
end
