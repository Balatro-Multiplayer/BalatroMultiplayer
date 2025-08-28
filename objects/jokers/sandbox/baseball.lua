SMODS.Atlas({
	key = "baseball_sandbox",
	path = "j_baseball_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "baseball_sandbox",
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
	atlas = "baseball_sandbox",
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
	mp_credits = { idea = "Sylvie" },
})
