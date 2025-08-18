SMODS.Atlas({
	key = "vagabond_cheese",
	path = "j_vagabond_cheese.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "vagabond_cheese",
	atlas = "vagabond_cheese",
	rarity = 3,
	cost = 7,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = false,
	perishable_compat = true,
	config = {},
	in_pool = function(self)
		return false
	end,
	mp_credits = {
		art = { "Coo" },
	},
})
