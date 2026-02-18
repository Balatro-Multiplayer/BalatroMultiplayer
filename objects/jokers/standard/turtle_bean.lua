SMODS.Joker({
	key = "turtle_bean",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = false,
	rarity = 1,
	cost = 5,
	pos = { x = 4, y = 13 },
	config = { extra = { h_size = 5, h_mod = 1 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.h_size, card.ability.extra.h_mod } }
	end,
	calculate = function(self, card, context)
		if context.first_hand_drawn and MP.is_pvp_boss() and not context.blueprint then
			G.hand:change_size(-card.ability.extra.h_size)
			card.ability.extra.effect_disabled = true
		end
		if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
			if MP.is_pvp_boss() then
				G.hand:change_size(card.ability.extra.h_size)
				card.ability.extra.effect_disabled = false
			else
				if card.ability.extra.h_size - card.ability.extra.h_mod <= 0 then
					SMODS.destroy_cards(card, nil, nil, true)
					return {
						message = localize("k_eaten_ex"),
						colour = G.C.FILTER,
					}
				else
					card.ability.extra.h_size = card.ability.extra.h_size - card.ability.extra.h_mod
					G.hand:change_size(-card.ability.extra.h_mod)
					return {
						message = localize({
							type = "variable",
							key = "a_handsize_minus",
							vars = { card.ability.extra.h_mod },
						}),
						colour = G.C.FILTER,
					}
				end
			end
		end
	end,
	add_to_deck = function(self, card, from_debuff)
		if not MP.is_pvp_boss() then
			G.hand:change_size(card.ability.extra.h_size)
		else
			card.ability.extra.effect_disabled = true
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not card.ability.extra.effect_disabled then G.hand:change_size(-card.ability.extra.h_size) end
	end,
	mp_include = function(self)
		return MP.UTILS.is_standard_ruleset() and MP.LOBBY.code
	end,
})
