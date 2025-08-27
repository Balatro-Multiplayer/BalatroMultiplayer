SMODS.Joker({
	key = "runner_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 1,
	cost = 5,
	pos = { x = 3, y = 10 },
	config = { extra = { chips = 0, chip_mod = 50 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips } }
	end,
	calculate = function(self, card, context)
		if context.before and context.main_eval and not context.blueprint and next(context.poker_hands["Straight"]) then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.CHIPS,
			}
		end
		if context.joker_main and next(context.poker_hands["Straight"]) then
			return {
				chips = card.ability.extra.chips,
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

