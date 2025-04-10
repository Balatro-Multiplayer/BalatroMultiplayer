SMODS.Atlas({
	key = "speedrun",
	path = "j_speedrun.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "speedrun",
	atlas = "speedrun",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = {} }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Virtualized" },
		art = { "Aura!" },
		code = { "Virtualized" },
	},
})
