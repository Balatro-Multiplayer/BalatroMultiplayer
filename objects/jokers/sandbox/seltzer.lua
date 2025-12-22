-- rare, 5 bucks, debuffed in pvp
SMODS.Joker({
	key = "seltzer_sandbox",
	blueprint_compat = true,
	eternal_compat = false,
	rarity = 1,
	cost = 5,
	pos = { x = 3, y = 15 },
	config = { extra = { hands_left = 10 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.hands_left } }
	end,
	calculate = function(self, card, context)
		if context.first_hand_drawn then
			local eval = function()
				return not MP.is_pvp_boss()
			end
			juice_card_until(card, eval, true)
		end
		if context.repetition and context.cardarea == G.play and not MP.is_pvp_boss() then
			return {
				repetitions = 1,
			}
		end
		if context.after and not context.blueprint and not MP.is_pvp_boss() then
			if card.ability.extra.hands_left - 1 <= 0 then
				SMODS.destroy_cards(card, nil, nil, true)
				return {
					message = localize("k_drank_ex"),
					colour = G.C.FILTER,
				}
			else
				card.ability.extra.hands_left = card.ability.extra.hands_left - 1
				return {
					message = card.ability.extra.hands_left .. "",
					colour = G.C.FILTER,
				}
			end
		end
		if context.end_of_round then
			-- stop jiggling
		end
	end,
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
