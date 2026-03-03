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
	config = { extra = { hands_left = 8 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.hands_left } }
	end,
	calculate = function(self, card, context)
		if context.repetition and context.cardarea == G.play then return {
			repetitions = 1,
		} end
		if context.after and not context.blueprint then
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
	end,
	mp_include = function(self)
		return MP.UTILS.is_standard_ruleset() and MP.LOBBY.code
	end,
})
