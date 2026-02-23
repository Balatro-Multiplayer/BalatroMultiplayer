SMODS.Joker({
	key = "seltzer",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = false,
	rarity = 2,
	cost = 5,
	pos = { x = 3, y = 15 },
	config = { extra = { retrigger_count = 1, retrigger_max = 5 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.retrigger_count, card.ability.extra.retrigger_max } }
	end,
	calculate = function(self, card, context)
		if context.repetition and context.cardarea == G.play then
			for i = 1, math.min(card.ability.extra.retrigger_count, #context.scoring_hand) do
				if context.other_card == context.scoring_hand[i] then
					return {
						message = localize("k_again_ex"),
						repetitions = 1,
						card = card,
					}
				end
			end
		end
		if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
			if card.ability.extra.retrigger_count + 1 > card.ability.extra.retrigger_max then
				SMODS.destroy_cards(card, nil, nil, true)
				return {
					message = localize("k_drank_ex"),
					colour = G.C.FILTER,
				}
			else
				card.ability.extra.retrigger_count = card.ability.extra.retrigger_count + 1
				return {
					message = card.ability.extra.retrigger_count .. "",
					colour = G.C.FILTER,
				}
			end
		end
	end,
	mp_include = function(self)
		return MP.UTILS.is_standard_ruleset() and MP.LOBBY.code
	end,
})
