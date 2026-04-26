-- Contains function overrides (monkey-patches) for game state management
-- Overrides Game methods like update_draw_to_hand, update_hand_played, update_new_round, etc.

local update_draw_to_hand_ref = Game.update_draw_to_hand
function Game:update_draw_to_hand(dt)
	if MP.is_mp_or_ghost() then
		if
			not G.STATE_COMPLETE
			and G.GAME.current_round.hands_played == 0
			and G.GAME.current_round.discards_used == 0
			and G.GAME.facing_blind
		then
			if G.GAME.round_resets.pvp_blind_choices[G.GAME.blind_on_deck] then
				G.GAME.blind.pvp = true
			else
				G.GAME.blind.pvp = false
			end
			if MP.is_pvp_boss() then
				MP.GAME.pincher_unlock = true
				G.after_pvp = true -- i can't find a reasonable way to detect end of pvp (for pizza) so i'm doing something strange instead

				if MP.GAME.asteroids > 0 then -- launch asteroids, messy event garbage
					delay(0.8)
					update_hand_text({ sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, {
						handname = localize("k_asteroids"),
						chips = localize("k_amount_short"),
						mult = MP.GAME.asteroids,
					})
					delay(0.6)
					local send = 0
					for i = 1, MP.GAME.asteroids do
						local perc = MP.GAME.asteroids - send
						G.E_MANAGER:add_event(Event({
							func = function()
								play_sound("tarot1", 0.9 + (perc / 10), 1)
								return true
							end,
						}))
						send = send + 1
						update_hand_text({ delay = 0 }, { mult = MP.GAME.asteroids - send })
						delay(0.2)
					end
					G.E_MANAGER:add_event(Event({
						func = function()
							if not MP.GHOST.is_active() then
								for i = 1, MP.GAME.asteroids do
									MP.ACTIONS.asteroid()
								end
							end
							MP.GAME.asteroids = 0
							return true
						end,
					}))
					delay(0.7)
					update_hand_text(
						{ sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
						{ mult = 0, chips = 0, handname = "", level = "" }
					)
				end
			end
		end
	end
	update_draw_to_hand_ref(self, dt)
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
				if eval then table.insert(effects, eval) end
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
	local ghost = MP.GHOST.is_active()
	if (not ghost and (not MP.LOBBY.connected or not MP.LOBBY.code)) or not MP.is_pvp_boss() then
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
				if not ghost then
					MP.ACTIONS.play_hand(G.GAME.chips, G.GAME.current_round.hands_left)
				end

				if G.GAME.current_round.hands_left < 1 then
					if ghost then
						local result = MP.GHOST.resolve_pvp_hands_exhausted(G.GAME.chips)
						if result == "won" then
							win_game()
							return true
						elseif result == "game_over" then
							G.STATE = G.STATES.GAME_OVER
							G.STATE_COMPLETE = false
							return true
						end
					else
						attention_text({
							scale = 0.8,
							text = localize("k_wait_enemy"),
							hold = 5,
							align = "cm",
							offset = { x = 0, y = -1.5 },
							major = G.play,
						})
					end
					if G.hand.cards[1] and G.STATE == G.STATES.HAND_PLAYED then
						eval_hand_and_jokers()
						G.FUNCS.draw_from_hand_to_discard()
					end
				elseif ghost and MP.GHOST.has_hand_data() then
					MP.GHOST.resolve_pvp_mid_hand(G.GAME.chips)

					if not MP.GAME.end_pvp and G.STATE == G.STATES.HAND_PLAYED then
						G.STATE_COMPLETE = false
						G.STATE = G.STATES.DRAW_TO_HAND
					end
				elseif not MP.GAME.end_pvp and G.STATE == G.STATES.HAND_PLAYED then
					G.STATE_COMPLETE = false
					G.STATE = G.STATES.DRAW_TO_HAND
				end
				return true
			end,
		}))
	end

	if MP.GAME.end_pvp and MP.is_pvp_boss() and not (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) then
		G.STATE_COMPLETE = false
		G.STATE = G.STATES.NEW_ROUND
		MP.GAME.end_pvp = false
	end
end

local update_new_round_ref = Game.update_new_round
function Game:update_new_round(dt)
	if MP.GAME.end_pvp then
		if G.STATE ~= G.STATES.NEW_ROUND then
			G.FUNCS.draw_from_hand_to_deck()
			G.FUNCS.draw_from_discard_to_deck()
		end
		G.STATE = G.STATES.NEW_ROUND
		MP.GAME.end_pvp = false
	end
	if MP.is_mp_or_ghost() and not G.STATE_COMPLETE then
		local ghost = MP.GHOST.is_active()
		-- Prevent player from losing
		if to_big(G.GAME.chips) < to_big(G.GAME.blind.chips) and not MP.is_pvp_boss() then
			G.GAME.blind.chips = -1
			if ghost then
				if MP.GHOST.resolve_round_fail() == "game_over" then
					G.STATE = G.STATES.GAME_OVER
					G.STATE_COMPLETE = false
					return
				end
			else
				MP.GAME.wait_for_enemys_furthest_blind = (MP.LOBBY.config.gamemode == "gamemode_mp_survival")
					and (tonumber(MP.GAME.lives) == 1)
				MP.ACTIONS.fail_round(G.GAME.current_round.hands_played)
			end
		end

		-- Prevent player from winning
		G.GAME.win_ante = 999

		if not ghost and MP.LOBBY.config.gamemode == "gamemode_mp_survival" and MP.GAME.wait_for_enemys_furthest_blind then
			G.STATE_COMPLETE = true
			G.FUNCS.draw_from_hand_to_discard()
			attention_text({
				scale = 0.8,
				text = localize("k_wait_enemy_reach_this_blind"),
				hold = 5,
				align = "cm",
				offset = { x = 0, y = -1.5 },
				major = G.play,
			})
		else
			update_new_round_ref(self, dt)
		end

		-- Reset ante number
		G.GAME.win_ante = 8
		return
	end
	update_new_round_ref(self, dt)
end

local update_selecting_hand_ref = Game.update_selecting_hand
function Game:update_selecting_hand(dt)
	if
		G.GAME.current_round.hands_left < G.GAME.round_resets.hands
		and #G.hand.cards < 1
		and #G.deck.cards < 1
		and #G.play.cards < 1
		and MP.is_mp_or_ghost()
	then
		G.GAME.current_round.hands_left = 0
		if not MP.is_pvp_boss() then
			G.STATE_COMPLETE = false
			G.STATE = G.STATES.NEW_ROUND
		else
			if not MP.GHOST.is_active() then
				MP.ACTIONS.play_hand(G.GAME.chips, 0)
			end
			G.STATE_COMPLETE = false
			G.STATE = G.STATES.HAND_PLAYED
		end
		return
	end
	update_selecting_hand_ref(self, dt)

	if MP.GAME.end_pvp and MP.is_pvp_boss() and MP.is_mp_or_ghost() then
		G.hand:unhighlight_all()
		G.STATE_COMPLETE = false
		G.STATE = G.STATES.NEW_ROUND
		MP.GAME.end_pvp = false
	end
end

-- Consolidate both update_shop overrides
local update_shop_ref = Game.update_shop
function Game:update_shop(dt)
	if not G.STATE_COMPLETE then
		MP.GAME.ready_blind = false
		MP.GAME.ready_blind_text = localize("b_ready")
		MP.GAME.end_pvp = false
	end

	local updated_location = false
	if MP.LOBBY.code and not G.STATE_COMPLETE and not updated_location and not G.GAME.USING_RUN then
		updated_location = true
		MP.ACTIONS.set_location("loc_shop")
		MP.GAME.spent_before_shop = to_big(MP.GAME.spent_total) + to_big(0)
		if MP.UI.show_enemy_location then MP.UI.show_enemy_location() end
	end
	if G.STATE_COMPLETE and updated_location then updated_location = false end
	update_shop_ref(self, dt)
end

local update_blind_select_ref = Game.update_blind_select
function Game:update_blind_select(dt)
	local updated_location = false
	if MP.LOBBY.code and not G.STATE_COMPLETE and not updated_location then
		updated_location = true
		MP.ACTIONS.set_location("loc_selecting")
		if MP.UI.show_enemy_location then MP.UI.show_enemy_location() end
	end
	if G.STATE_COMPLETE and updated_location then updated_location = false end
	update_blind_select_ref(self, dt)
end

local start_run_ref = Game.start_run
function Game:start_run(args)
	-- Use MP ruleset if in lobby, otherwise use SP ruleset (if selected)
	MP.LoadReworks(MP.LOBBY.config.ruleset or MP.SP.ruleset)

	start_run_ref(self, args)

	local show_lives_hud = (MP.LOBBY.connected and MP.LOBBY.code) or MP.GHOST.is_active()
	if not show_lives_hud or MP.LOBBY.config.disable_live_and_timer_hud then return end

	local scale = 0.4
	local hud_ante = G.HUD:get_UIE_by_ID("hud_ante")
	hud_ante.children[1].children[1].config.text = localize("k_lives")

	-- Set lives number
    local lives_container = hud_ante.children[2].children[1]
    if  lives_container.config.object then
        lives_container.config.object:remove()
    end
    lives_container.config.object = UIBox({
        definition = {
            n = G.UIT.ROOT,
            config = { colour = G.C.CLEAR },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { align = "cm", minw = 1.2, maxw = 1.2, minh = 0.664 },
                    nodes = {
                        {
                            n = G.UIT.T,
                            config = {
                                ref_table = MP.GAME,
                                ref_value = "lives",
                                scale = 2 * scale * 0.8,
                                colour = G.C.IMPORTANT,
                                shadow = true,
                                maxw = 0.5,
                            }
                        },
                        { n = G.UIT.B, config = { w = 0.05, h = 0.05 } },
                        {
                            n = G.UIT.T,
                            config = {
                                text = "vs", -- not localized intentionally
                                scale = scale * 0.8,
                                colour = G.C.UI.TEXT_DARK,
                                shadow = true,
                            }
                        },
                        { n = G.UIT.B, config = { w = 0.05, h = 0.05 } },
                        {
                            n = G.UIT.T,
                            config = {
                                ref_table = MP.GAME.enemy,
                                ref_value = "lives",
                                scale = 2 * scale * 0.8,
                                colour = G.C.RED,
                                shadow = true,
                                maxw = 0.5,
                            }
                        },
                    }
                }
            }
        },
        config = {},
    })

	-- Remove unnecessary HUD elements from ante counter
	hud_ante.children[2].children[2] = nil
	hud_ante.children[2].children[3] = nil
	hud_ante.children[2].children[4] = nil

	G.HUD:recalculate()
end

-- This prevents duplicate execution during certain cases. e.g. Full deck discard before playing any hands.
function MP.handle_duplicate_end()
	if MP.is_mp_or_ghost() then
		if MP.GAME.round_ended then
			if not MP.GAME.duplicate_end then
				MP.GAME.duplicate_end = true
				sendDebugMessage("Duplicate end_round calls prevented.", "MULTIPLAYER")
			end
			return true
		end
	end
	return false
end

-- This handles an edge case where a player plays no hands, and discards the only cards in their deck.
-- Allows opponent to advance after playing anything, and eases a life from the person who discarded their deck.
function MP.handle_deck_out()
	if MP.is_mp_or_ghost() then
		if
			G.GAME.current_round.hands_played == 0
			and G.GAME.current_round.discards_used > 0
			and MP.LOBBY.config.gamemode ~= "gamemode_mp_survival"
		then
			if not MP.GHOST.is_active() then
				if MP.is_pvp_boss() then MP.ACTIONS.play_hand(0, 0) end
				MP.ACTIONS.fail_round(1)
			end
		end
	end
end

local mp_jimbo = nil
local mp_jimbo_pos = nil

local JIMBO_POSITIONS = {
	[1] = { align = "cri", offset = { x = 1, y = 0 }, bubble_align = "cl", bubble_offset = { x = 0, y = 0 } },
	[2] = { align = "tli", offset = { x = -0.75, y = -0.75 }, bubble_align = "cr", bubble_offset = { x = 0, y = -0.5 } },
	[3] = { align = "tri", offset = { x = 1.8, y = -0.1 }, bubble_align = "bl", bubble_offset = { x = 2.1, y = 0 } },
	[4] = { align = "cmi", offset = { x = 0, y = -1.5 }, bubble_align = "cr", bubble_offset = { x = 0, y = 0 } },
}

function MP.UI.create_jimbo(pos, text)
	if mp_jimbo then MP.UI.remove_jimbo() end
	local p = JIMBO_POSITIONS[pos] or JIMBO_POSITIONS[1]
	mp_jimbo_pos = pos or 1
	mp_jimbo = Card_Character({
		x = 0,
		y = G.ROOM.T.h + 5,
		center = "j_perkeo",
		particle_colours = { HEX("4e997b"), HEX("e9564e"), HEX("ebecee") },
	})
	mp_jimbo.children.particles:remove()
	mp_jimbo.children.particles = nil
	mp_jimbo.children.card:set_edition({ negative = true }, true, true)
	mp_jimbo.say_stuff = function(self, n, not_first)
		self.talking = true
		if not not_first then
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				timer = "REAL",
				delay = 0.1,
				func = function()
					if self.children.speech_bubble then self.children.speech_bubble.states.visible = true end
					self:say_stuff(n, true)
					return true
				end,
			}))
		else
			if n <= 0 then
				self.talking = false
				return
			end
			play_sound("voice" .. math.random(1, 11), math.random() * 0.2 + 1, 0.5)
			self.children.card:juice_up()
			G.E_MANAGER:add_event(
				Event({
					trigger = "after",
					timer = "REAL",
					blockable = false,
					blocking = false,
					delay = 0.13,
					func = function()
						self:say_stuff(n - 1, true)
						return true
					end,
				}),
				"tutorial"
			)
		end
	end
	mp_jimbo:set_alignment({
		major = G.ROOM_ATTACH,
		type = p.align,
		offset = p.offset,
	})
	if text then MP.UI.jimbo_say(text) end
	return mp_jimbo
end

function MP.UI.move_jimbo(pos)
	if not mp_jimbo then return end
	local p = JIMBO_POSITIONS[pos] or JIMBO_POSITIONS[1]
	mp_jimbo_pos = pos or 1
	mp_jimbo:set_alignment({
		major = G.ROOM_ATTACH,
		type = p.align,
		offset = p.offset,
	})
	if mp_jimbo.children.speech_bubble then
		mp_jimbo.children.speech_bubble.alignment.type = p.bubble_align
		mp_jimbo.children.speech_bubble.alignment.offset = p.bubble_offset
		mp_jimbo.children.speech_bubble:align_to_major()
	end
end

function MP.UI.jimbo_say(text)
	if not mp_jimbo then return end
	if mp_jimbo.children.speech_bubble then mp_jimbo.children.speech_bubble:remove() end
	local lines = {}
	for line in MP.UTILS.wrapText(text, 30):gmatch("[^\n]+") do
		lines[#lines + 1] = line:match("^%s*(.-)%s*$")
	end
	local rows = {}
	for _, line in ipairs(lines) do
		rows[#rows + 1] = {
			n = G.UIT.R,
			config = { align = "cl" },
			nodes = {
				{ n = G.UIT.T, config = { text = line, scale = 0.4, colour = G.C.UI.TEXT_DARK } },
			},
		}
	end
	local definition = {
		n = G.UIT.ROOT,
		config = { align = "cm", minh = 1, r = 0.3, padding = 0.07, minw = 1, colour = G.C.JOKER_GREY, shadow = true },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm", minh = 1, r = 0.2, padding = 0.1, minw = 1, colour = G.C.WHITE },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", minh = 1, r = 0.2, padding = 0.03, minw = 1, colour = G.C.WHITE },
						nodes = rows,
					},
				},
			},
		},
	}
	local p = JIMBO_POSITIONS[mp_jimbo_pos] or JIMBO_POSITIONS[1]
	mp_jimbo.children.speech_bubble = UIBox({
		definition = definition,
		config = { align = p.bubble_align, offset = p.bubble_offset, parent = mp_jimbo },
	})
	mp_jimbo.children.speech_bubble:set_role({
		role_type = "Minor",
		xy_bond = "Weak",
		r_bond = "Strong",
		major = mp_jimbo,
	})
	mp_jimbo.children.speech_bubble.states.visible = true
	local word_count = select(2, text:gsub("%S+", ""))
	local read_time = math.max(5, word_count * 0.3 + 1) + 5
	mp_jimbo:say_stuff(math.ceil(word_count / 2))
	local bubble_ref = mp_jimbo.children.speech_bubble
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		timer = "REAL",
		blockable = false,
		blocking = false,
		delay = read_time,
		func = function()
			if mp_jimbo and mp_jimbo.children.speech_bubble == bubble_ref then
				mp_jimbo.children.speech_bubble:remove()
				mp_jimbo.children.speech_bubble = nil
			end
			return true
		end,
	}))
end

-- Practice mode: spawn Jimbo when opening collection to hint at card spawning (once per boot)
local practice_collection_jimbo = false
local practice_collection_hint_shown = false

local your_collection_ref = G.FUNCS.your_collection
function G.FUNCS.your_collection(e)
	your_collection_ref(e)
	if MP.is_practice_mode() and not MP.LOBBY.code and not practice_collection_hint_shown then
		practice_collection_hint_shown = true
		practice_collection_jimbo = true
		MP.UI.create_jimbo(2, localize("k_practice_collection_hint"))
	end
end

local exit_overlay_menu_ref_jimbo = G.FUNCS.exit_overlay_menu
function G.FUNCS:exit_overlay_menu()
	if practice_collection_jimbo then
		practice_collection_jimbo = false
		MP.UI.remove_jimbo()
	end
	exit_overlay_menu_ref_jimbo(self)
end

function MP.UI.remove_jimbo()
	if not mp_jimbo then return end
	local jimbo = mp_jimbo
	mp_jimbo = nil
	if jimbo.children.speech_bubble then
		jimbo.children.speech_bubble:remove()
		jimbo.children.speech_bubble = nil
	end
	if jimbo.children.button then
		jimbo.children.button:remove()
		jimbo.children.button = nil
	end
	jimbo.children.card:start_dissolve({ HEX("4e997b") }, nil, nil, true)
	if jimbo.children.particles then jimbo.children.particles:fade(0.5) end
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		blockable = false,
		delay = 0.8,
		func = function()
			jimbo:remove()
			return true
		end,
	}))
end
