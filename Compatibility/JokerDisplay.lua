if SMODS.Mods["JokerDisplay"] and SMODS.Mods["JokerDisplay"].can_load then
	if JokerDisplay then
		local jd_def = JokerDisplay.Definitions
		jd_def["j_mp_defensive_joker"] = {
			text = {
				{ text = "+" },
				{ ref_table = "card.joker_display_values", ref_value = "chips", retrigger_type = "mult" },
			},
			text_config = { colour = G.C.CHIPS },
			calc_function = function(card)
				card.joker_display_values.chips = card.ability.t_chips
			end,
		}
		jd_def["j_mp_lets_go_gambling"] = {
			text = {
				{
					border_nodes = {
						{ text = "X" },
						{ ref_table = "card.ability", ref_value = "x_mult", retrigger_type = "exp" },
					},
				},
			},
		}
	end
end
