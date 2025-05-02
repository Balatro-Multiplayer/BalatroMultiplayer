SMODS.Atlas({
	key = "penny_pincher",
	path = "j_penny_pincher.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "penny_pincher",
	atlas = "penny_pincher",
	rarity = 1,
	cost = 4,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { dollars = 1, nemesis_dollars = 3 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.dollars, card.ability.extra.nemesis_dollars } }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.starting_shop then
			return {
				dollars = math.floor(MP.GAME.enemy.spent_last_shop / card.ability.extra.nemesis_dollars),
			}
		end
	end,
	mp_credits = {
		idea = { "Nxkoozie" },
		art = { "Coo29" },
		code = { "Virtualized" },
	},
})
