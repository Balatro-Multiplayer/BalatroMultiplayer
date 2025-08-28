SMODS.Joker({
	key = "baseball",
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
	pos = { x = 6, y = 14 },
	config = { extra = { xmult = 1.5 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult } }
	end,
	calculate = function(self, card, context)
		if
			context.other_joker
			and (
				context.other_joker.config.center.rarity == 2
				or context.other_joker.config.center.rarity == "Uncommon"
			)
		then
			return {
				xmult = card.ability.extra.xmult,
			}
		end
	end,
})
