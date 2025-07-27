-- this is kinda strange but we can just override the logic for pvp only rather than re-implementing it again, bc if we don't return anything, it'll run the normal logic
MP.ReworkCenter({
	key = "j_bloodstone",
	ruleset = MP.UTILS.get_standard_rulesets(),
	silent = true,
	calculate = function(self, card, context)
		if MP.is_pvp_boss() then
			if not context.blueprint then
				if context.before then
					G.GAME.round_resets.mp_bloodstone = G.GAME.round_resets.mp_bloodstone or {}
					G.GAME.round_resets.mp_bloodstone[MP.order_round_based(true)] = G.GAME.round_resets.mp_bloodstone[MP.order_round_based(true)] or {}
					G.GAME.round_resets.mp_bsindex = 0
				end
			end
			if context.individual and context.cardarea == G.play then
				if context.other_card:is_suit("Hearts") then
					local stored_queue = G.GAME.round_resets.mp_bloodstone[MP.order_round_based(true)]
					G.GAME.round_resets.mp_bsindex = G.GAME.round_resets.mp_bsindex + 1 -- increment before indexing
					stored_queue[G.GAME.round_resets.mp_bsindex] = stored_queue[G.GAME.round_resets.mp_bsindex] or pseudorandom('bloodstone'..MP.order_round_based(true))
					if stored_queue[G.GAME.round_resets.mp_bsindex] < G.GAME.probabilities.normal/card.ability.extra.odds then
						return {
							x_mult = card.ability.extra.Xmult,
							card = card
						}
					end
					return nil, true -- prevents normal logic from triggering
				end
			end
		end
	end,
})