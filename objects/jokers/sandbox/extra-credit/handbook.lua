-- Handbook - Extra Credit Joker ported to Sandbox
-- Gains +5 Chips if played poker hand has not already been played this round

SMODS.Joker({
	key = "handbook_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = false,
	rarity = 1,
	cost = 5,
	atlas = "ec_jokers_sandbox",
	pos = { x = 3, y = 1 },
	config = { extra = { chip_mod = 5, chips = 0 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chip_mod, card.ability.extra.chips } }
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and card.ability.extra.chips > 0 then
			return {
				message = localize({ type = "variable", key = "a_chips", vars = { card.ability.extra.chips } }),
				chip_mod = card.ability.extra.chips,
			}
		elseif context.cardarea == G.jokers and G.GAME.hands[context.scoring_name] and G.GAME.hands[context.scoring_name].played_this_round == 1 and not context.blueprint and context.before then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			return {
				message = localize("k_upgrade_ex"),
				card = card,
				colour = G.C.CHIPS,
			}
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
