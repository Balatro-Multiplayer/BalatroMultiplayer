SMODS.Atlas({
	key = "constellation_sandbox",
	path = "j_constellation_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "constellation_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 2,
	cost = 6,
	atlas = "constellation_sandbox",
	config = { extra = { Xmult = 1, Xmult_mod = 0.2, Xmult_loss = 0.1 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.Xmult } }
	end,
	calculate = function(self, card, context)
		-- Gain mult when planet card is used
		if context.using_consumeable and not context.blueprint and context.consumeable.ability.set == "Planet" then
			card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
			return {
				message = localize({ type = "variable", key = "a_xmult", vars = { card.ability.extra.Xmult } }),
			}
		end
		-- Apply mult during main calculation
		if context.joker_main then return {
			xmult = card.ability.extra.Xmult,
		} end
		-- Lose mult at end of round
		if context.end_of_round and not context.individual and not context.repetition then
			card.ability.extra.Xmult = math.max(1, card.ability.extra.Xmult - card.ability.extra.Xmult_loss)
			return {
				message = localize("k_reset"),
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
