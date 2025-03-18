SMODS.Atlas({
	key = "lets_go_gambling",
	path = "j_lets_go_gambling.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "lets_go_gambling",
	atlas = "lets_go_gambling",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { denominator = 4, xmult = 4, dollars = 10, nemesis_denominator = 8, nemesis_dollars = 5 } },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				G.GAME.probabilities.normal,
				card.ability.extra.denominator,
				card.ability.extra.xmult,
				card.ability.extra.dollars,
				G.GAME.probabilities.normal,
				card.ability.extra.nemesis_denominator,
				card.ability.extra.nemesis_dollars,
			},
		}
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	calculate = function(self, card, context)
		
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = { "Carter" },
		code = { "Virtualized" },
	},
}) 