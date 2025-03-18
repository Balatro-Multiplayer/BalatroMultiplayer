SMODS.Atlas({
	key = "conjoined_joker",
	path = "j_conjoined_joker.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "conjoined_joker",
	atlas = "conjoined_joker",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { xmult_gain = 1, max_xmult = 5, xmult = 1 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.xmult_gain, card.ability.extra.max_xmult, card.ability.extra.xmult } }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "Nas4xou" },
		code = { "Virtualized" },
	},
}) 