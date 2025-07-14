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
		MP.UTILS.add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.dollars, card.ability.extra.nemesis_dollars } }
	end,
	in_pool = function(self)
		return (MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers) and MP.GAME.pincher_unlock -- do NOT replace this with G.GAME.round_resets.ante >= 3, order sets ante to 0
	end,
	calc_dollar_bonus = function(self, card)
		local spent = MP.GAME.enemy.spent_in_shop[MP.GAME.pincher_index]
		local money = 0
		if spent then
			money = math.floor(spent / card.ability.extra.nemesis_dollars)
		end
		if money > 0 then
			return money
		end
	end,
	mp_credits = {
		idea = { "Nxkoozie" },
		art = { "Coo29" },
		code = { "Virtualized" },
	},
})