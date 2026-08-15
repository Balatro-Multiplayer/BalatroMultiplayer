SMODS.Joker({
	key = "todo_list",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	rarity = 1,
	cost = 4,
	pos = { x = 4, y = 11 },
	config = { extra = { dollars = 5, poker_hand = "High Card" }, mp_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.dollars, localize(card.ability.extra.poker_hand, "poker_hands") } }
	end,
	calculate = function(self, card, context)
		if context.before and context.scoring_name == card.ability.extra.poker_hand then
			G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
			return {
				dollars = card.ability.extra.dollars,
				func = function()
					G.E_MANAGER:add_event(Event({
						func = function()
							G.GAME.dollar_buffer = 0
							return true
						end,
					}))
				end,
			}
		end
		if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
			local _poker_hands = {}
			for handname, _ in pairs(G.GAME.hands) do
				if handname ~= card.ability.extra.poker_hand then _poker_hands[#_poker_hands + 1] = handname end
			end
			card.ability.extra.poker_hand = pseudorandom_element(_poker_hands, "todo_list")
			return {
				message = localize("k_reset"),
			}
		end
	end,
	set_ability = function(self, card, initial, delay_sprites)
		local _poker_hands = {}
		for handname, _ in pairs(G.GAME.hands) do
			if handname ~= card.ability.extra.poker_hand then _poker_hands[#_poker_hands + 1] = handname end
		end
		card.ability.extra.poker_hand = pseudorandom_element(_poker_hands, "todo_list")
	end,
})
