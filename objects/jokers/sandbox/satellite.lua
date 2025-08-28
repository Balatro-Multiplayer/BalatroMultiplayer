SMODS.Atlas({
	key = "satellite_sandbox",
	path = "j_satellite_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "satellite_sandbox",
	unlocked = false,
	blueprint_compat = false,
	rarity = 2,
	cost = 6,
	atlas = "satellite_sandbox",
	config = { extra = { dollars = 1 } },
	loc_vars = function(self, info_queue, card)
		local planets_used = 0
		for k, v in pairs(G.GAME.consumeable_usage) do
			if v.set == "Planet" then planets_used = planets_used + 1 end
		end
		return { vars = { card.ability.extra.dollars, planets_used * card.ability.extra.dollars } }
	end,
	calc_dollar_bonus = function(self, card)
		local planets_used = 0
		for k, v in pairs(G.GAME.consumeable_usage) do
			if v.set == "Planet" then planets_used = planets_used + 1 end
		end
		return planets_used > 0 and planets_used * card.ability.extra.dollars or nil
	end,
	locked_loc_vars = function(self, info_queue, card)
		return { vars = { 400 } }
	end,
	check_for_unlock = function(self, args) -- equivalent to `unlock_condition = { type = 'money', extra = 400 }`
		return args.type == "money" and G.GAME.dollars >= 400 -- See note about Talisman on the wiki
	end,
})
