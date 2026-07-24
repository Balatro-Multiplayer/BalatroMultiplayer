SMODS.Atlas({
	key = "penny_pincher",
	path = "j_penny_pincher.png",
	px = 71,
	py = 95,
})

MPAPI.Joker({
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
		PVP.UTILS.add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.dollars, card.ability.extra.nemesis_dollars } }
	end,
	in_pool = function(self)
		return PVP.GAME.pincher_unlock -- do NOT replace this with G.GAME.round_resets.ante >= 3, order sets ante to 0
	end,
	calculate = function(self, card, context)
		-- §18.2: opponent left their shop, told to us via
		-- MPAPI.broadcast_opponent_context (lovely/game.toml's toggle_shop
		-- patch) -- was previously its own bespoke receive handler
		-- (action_spent_last_shop).
		if context.opponent_spent_in_shop then
			if PVP.is_byed() then
				return
			end
			local target = PVP.current_target_id()
			if target and context.from ~= target then
				return
			end
			PVP.GAME.enemy.spent_in_shop[#PVP.GAME.enemy.spent_in_shop + 1] = tonumber(context.opponent_spent_in_shop)
		end
	end,
	calc_dollar_bonus = function(self, card)
		local spent = PVP.GAME.enemy.spent_in_shop[PVP.GAME.pincher_index]
		local money = 0
		if spent then money = math.floor(spent / card.ability.extra.nemesis_dollars) end
		if money > 0 then return money end
	end,
	mp_credits = {
		idea = { "Nxkoozie" },
		art = { "Coo29" },
		code = { "Virtualized" },
	},
})
