SMODS.Joker({
	key = "square_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 1,
	cost = 4,
	pos = { x = 9, y = 11 },
	pixel_size = { h = 71 },
	config = { extra = { chips = 64, chip_mod = 16 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
	calculate = function(self, card, context)
		if context.before and context.main_eval and not context.blueprint and #context.full_hand == 4 then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.CHIPS,
			}
		end
		if context.joker_main and #context.full_hand == 4 then return {
			chips = card.ability.extra.chips,
		} end
	end,
})
