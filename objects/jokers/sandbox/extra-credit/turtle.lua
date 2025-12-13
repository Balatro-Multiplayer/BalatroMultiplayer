-- Turtle - Extra Credit Joker ported to Sandbox
-- Gains X0.2 Mult at the end of each Small Blind or Big Blind (not Boss)

SMODS.Joker({
	key = "turtle_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = false,
	rarity = 2,
	cost = 6,
	atlas = "ec_jokers_sandbox",
	pos = { x = 1, y = 1 },
	config = { extra = { Xmult_mod = 0.2, Xmult = 1 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.Xmult } }
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and card.ability.extra.Xmult > 1 then
			return {
				message = localize({ type = "variable", key = "a_xmult", vars = { card.ability.extra.Xmult } }),
				Xmult_mod = card.ability.extra.Xmult,
			}
		elseif context.end_of_round and not context.repetition and not context.individual and not G.GAME.blind.boss and not context.blueprint then
			card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
			return {
				message = localize("k_upgrade_ex"),
				card = card,
				colour = G.C.RED,
			}
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
