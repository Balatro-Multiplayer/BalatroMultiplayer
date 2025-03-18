SMODS.Atlas({
	key = "magnet",
	path = "j_magnet.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "magnet",
	atlas = "magnet",
	rarity = 3,
	cost = 8,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { rounds = 2, current_rounds = 0 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.rounds, card.ability.extra.current_rounds, card.ability.extra.rounds } }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "Ganpan140" },
		code = { "Virtualized" },
	},
}) 