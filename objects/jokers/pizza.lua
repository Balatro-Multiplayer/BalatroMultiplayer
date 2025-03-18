SMODS.Atlas({
	key = "pizza",
	path = "j_pizza.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "pizza",
	atlas = "pizza",
	rarity = 1,
	cost = 4,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { discards = 6, discards_loss = 1 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.discards, card.ability.extra.discards_loss } }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Virtualized" },
		art = { "TheTrueRaven" },
		code = { "Virtualized" },
	},
}) 