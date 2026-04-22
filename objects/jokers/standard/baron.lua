SMODS.Joker({
	key = "baron",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	rarity = 2,
	cost = 5,
	pos = { x = 6, y = 12 },
	config = { extra = { xmult = 1.5 }, mp_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult } }
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.hand and not context.end_of_round and context.other_card:get_id() == 13 then
			if context.other_card.debuff then
				return {
					message = localize("k_debuffed"),
					colour = G.C.RED,
				}
			else
				return {
					x_mult = card.ability.extra.xmult,
				}
			end
		end
	end,
	mp_include = function(self)
		return MP.is_layer_active("standard") and MP.LOBBY.code
	end,
})
