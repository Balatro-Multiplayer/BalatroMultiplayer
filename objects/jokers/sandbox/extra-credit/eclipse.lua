-- Eclipse - Extra Credit Joker ported to Sandbox
-- +12 Chips for every Hand Level above level one

SMODS.Joker({
	key = "eclipse_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	rarity = 3,
	cost = 8,
	atlas = "ec_jokers_sandbox",
	pos = { x = 3, y = 0 },
	config = { extra = { chip_mod = 12 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		local levels, hands = MP.EC.eclipse_sum_levels()
		return { vars = { (levels - hands) * card.ability.extra.chip_mod, card.ability.extra.chip_mod } }
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main then
			local levels, hands = MP.EC.eclipse_sum_levels()
			local chips = (levels - hands) * card.ability.extra.chip_mod
			if chips > to_big(0) then
				return {
					message = localize({ type = "variable", key = "a_chips", vars = { chips } }),
					chip_mod = chips,
					colour = G.C.CHIPS,
				}
			end
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
