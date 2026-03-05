-- Contains function overrides (monkey-patches) for game state management
-- Overrides Game methods like update_draw_to_hand, update_hand_played, update_new_round, etc.

local update_draw_to_hand_ref = Game.update_draw_to_hand
function Game:update_draw_to_hand(dt)
	if MP.LOBBY.code then
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
				G.E_MANAGER:add_event(Event({
					trigger = "after",
					delay = 1,
					blockable = false,
					func = function()
						G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:pop_out(0)
						MP.UI.update_blind_HUD()
						G.E_MANAGER:add_event(Event({
							trigger = "after",
							delay = 0.45,
							blockable = false,
							func = function()
								G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object.config.string = {
									{
										ref_table = MP.LOBBY.is_host and MP.LOBBY.guest or MP.LOBBY.host,
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
							for i = 1, MP.GAME.asteroids do
								MP.ACTIONS.asteroid()
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
	if not MP.LOBBY.connected or not MP.LOBBY.code or not MP.is_pvp_boss() then
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
				MP.ACTIONS.play_hand(G.GAME.chips, G.GAME.current_round.hands_left)
				-- For now, never advance to next round
				if G.GAME.current_round.hands_left < 1 then
					attention_text({
						scale = 0.8,
						text = localize("k_wait_enemy"),
						hold = 5,
						align = "cm",
						offset = { x = 0, y = -1.5 },
						major = G.play,
					})
					if G.hand.cards[1] and G.STATE == G.STATES.HAND_PLAYED then
						eval_hand_and_jokers()
						G.FUNCS.draw_from_hand_to_discard()
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
	if MP.LOBBY.code and not G.STATE_COMPLETE then
		-- Prevent player from losing
		if to_big(G.GAME.chips) < to_big(G.GAME.blind.chips) and not MP.is_pvp_boss() then
			G.GAME.blind.chips = -1
			MP.GAME.wait_for_enemys_furthest_blind = (MP.LOBBY.config.gamemode == "gamemode_mp_survival")
				and (tonumber(MP.GAME.lives) == 1) -- In Survival Mode, if this is the last live, wait for the enemy.
			MP.ACTIONS.fail_round(G.GAME.current_round.hands_played)
		end

		-- Prevent player from winning
		G.GAME.win_ante = 999

		if MP.LOBBY.config.gamemode == "gamemode_mp_survival" and MP.GAME.wait_for_enemys_furthest_blind then
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
		and MP.LOBBY.code
	then
		G.GAME.current_round.hands_left = 0
		if not MP.is_pvp_boss() then
			G.STATE_COMPLETE = false
			G.STATE = G.STATES.NEW_ROUND
		else
			MP.ACTIONS.play_hand(G.GAME.chips, 0)
			G.STATE_COMPLETE = false
			G.STATE = G.STATES.HAND_PLAYED
		end
		return
	end
	update_selecting_hand_ref(self, dt)

	if MP.GAME.end_pvp and MP.is_pvp_boss() then
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

	if not MP.LOBBY.connected or not MP.LOBBY.code or MP.LOBBY.config.disable_live_and_timer_hud then return end

	local scale = 0.4
	local hud_ante = G.HUD:get_UIE_by_ID("hud_ante")
	hud_ante.children[1].children[1].config.text = localize("k_lives")

	-- Set lives number
	hud_ante.children[2].children[1].config.object = DynaText({
		string = { { ref_table = MP.GAME, ref_value = "lives" } },
		colours = { G.C.IMPORTANT },
		shadow = true,
		font = G.LANGUAGES["en-us"].font,
		scale = 2 * scale,
	})

	-- Remove unnecessary HUD elements from ante counter
	hud_ante.children[2].children[2] = nil
	hud_ante.children[2].children[3] = nil
	hud_ante.children[2].children[4] = nil

	G.HUD:recalculate()
end

-- This prevents duplicate execution during certain cases. e.g. Full deck discard before playing any hands.
function MP.handle_duplicate_end()
	if MP.LOBBY.code then
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
	if MP.LOBBY.code then
		if
			G.GAME.current_round.hands_played == 0
			and G.GAME.current_round.discards_used > 0
			and MP.LOBBY.config.gamemode ~= "gamemode_mp_survival"
		then
			if MP.is_pvp_boss() then MP.ACTIONS.play_hand(0, 0) end

			MP.ACTIONS.fail_round(1)
		end
	end
end
