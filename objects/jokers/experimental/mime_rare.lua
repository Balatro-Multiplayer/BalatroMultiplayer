SMODS.Joker({
	key = "mime",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
	pos = { x = 4, y = 1 },
	config = { extra = { repetitions = 1 }, mp_balanced = true },
	calculate = function(self, card, context)
		if context.repetition and context.cardarea == G.hand and (next(context.card_effects[1]) or #context.card_effects > 1) then
			return {
				repetitions = card.ability.extra.repetitions,
			}
		end
	end,
})
