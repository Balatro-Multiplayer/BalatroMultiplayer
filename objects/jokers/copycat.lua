SMODS.Atlas({
	key = "copycat",
	path = "j_copycat.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "copycat",
	atlas = "copycat",
	rarity = 3,
	cost = 8,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
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
		idea = { "Zilver" },
		art = { "zeathemays" },
		code = { "Virtualized" },
	},
}) 