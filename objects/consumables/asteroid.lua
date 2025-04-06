SMODS.Atlas({
	key = "asteroid",
	path = {
		["default"] = "c_asteroid.png",
		["ru"] = "c_asteroid_ru.png",
	},
	px = 71,
	py = 95,
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
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	can_use = function(self, card)
		return true
	end,
	use = function(self, card, area, copier)
		MP.ACTIONS.asteroid()
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "TheTrueRaven" },
		code = { "Virtualized" },
	},
})
