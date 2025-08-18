SMODS.Atlas({
	key = "the_broker",
	path = "j_broker.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "the_broker",
	atlas = "the_broker",
	rarity = 2,
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
		art = { "Zwei" },
	},
})
