local old_seltzer_calculate = G.P_CENTERS.j_ice_cream.calculate or function(self, card, context) end
SMODS.Joker:take_ownership("j_ice_cream", {
    calculate = function(self, card, context)
        if context.mp_pvp_loss and not context.blueprint then
            local hands_decrease = context.mp_hands_left or 1
            local chips_decrease = card.ability.extra.chip_mod * hands_decrease
			if card.ability.extra.chips - chips_decrease <= 0 then
                SMODS.destroy_cards(card, nil, nil, true)
                return {
                    message = localize('k_melted_ex'),
                    colour = G.C.CHIPS
                }
            else
                card.ability.extra.chips = card.ability.extra.chips - chips_decrease
                return {
                    message = localize { type = 'variable', key = 'a_chips_minus', vars = { chips_decrease } },
                    colour = G.C.CHIPS
                }
            end
		end
        return old_seltzer_calculate(self, card, context)
    end,
}, true)