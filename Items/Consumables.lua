SMODS.Atlas({
	key = "asteroid",
	path = "c_asteroid.png",
	px = 63,
	py = 93,
})

SMODS.Consumable({
	key = "asteroid",
	set = "Planet",
	atlas = "asteroid",
	cost = 3,
	unlocked = true,
	discovered = true,
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { 1 } }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	can_use = function(self, card)
		return true
	end,
	use = function(self, card, area, copier)
		G.MULTIPLAYER.asteroid()
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "TheTrueRaven" },
		code = { "Virtualized" },
	},
})
