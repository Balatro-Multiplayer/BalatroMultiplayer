if SMODS.Mods["JokerDisplay"] and SMODS.Mods["JokerDisplay"].can_load then
	if JokerDisplay then
		local jd_def = JokerDisplay.Definitions
		jd_def["j_mp_conjoined_joker"] = {
			text = {
				{
					border_nodes = {
						{ text = "X" },
						{ ref_table = "card.joker_display_values", ref_value = "x_mult" },
					},
				},
			},
			calc_function = function(card)
				card.joker_display_values.x_mult = MP.is_pvp_boss() and card.ability.extra.x_mult or 1
			end,
		}
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
						{ ref_table = "card.ability.extra", ref_value = "xmult" },
					},
				},
				{ text = " " },
				{ text = "$", colour = G.C.GOLD },
				{ ref_table = "card.ability.extra", ref_value = "dollars", colour = G.C.GOLD },
			},
			extra = {
				{
					{ text = "(" },
					{ ref_table = "card.joker_display_values", ref_value = "odds" },
					{ text = ")" },
				},
			},
			extra_config = { colour = G.C.GREEN, scale = 0.3 },
			calc_function = function(card)
				card.joker_display_values.odds = localize({
					type = "variable",
					key = "jdis_odds",
					vars = { (G.GAME and G.GAME.probabilities.normal or 1), card.ability.extra.odds },
				})
			end,
		}
		jd_def["j_mp_magnet"] = {
			reminder_text = {
				{ text = "(" },
				{ ref_table = "card.joker_display_values", ref_value = "active" },
				{ text = ")" },
			},
			calc_function = function(card)
				card.joker_display_values.active = card.ability.extra.current_rounds >= card.ability.extra.rounds
						and localize("k_active")
					or (card.ability.extra.current_rounds .. "/" .. card.ability.extra.rounds)
			end,
		}
		jd_def["j_mp_pacifist"] = {
			text = {
				{
					border_nodes = {
						{ text = "X" },
						{ ref_table = "card.joker_display_values", ref_value = "x_mult" },
					},
				},
			},
			calc_function = function(card)
				card.joker_display_values.x_mult = not MP.is_pvp_boss() and card.ability.extra.x_mult or 1
			end,
		}
		jd_def["j_mp_pizza"] = {
			text = {
				{ text = "+", colour = G.C.RED },
				{ ref_table = "card.ability.extra", ref_value = "discards", colour = G.C.RED },
			},
		}
		jd_def["j_mp_skip_off"] = {
			text = {
				{ text = "+", colour = G.C.BLUE },
				{ ref_table = "card.ability.extra", ref_value = "hands", colour = G.C.BLUE },
				{ text = " " },
				{ text = "+", colour = G.C.RED },
				{ ref_table = "card.ability.extra", ref_value = "discards", colour = G.C.RED },
			},
			extra = {
				{ text = "(" },
				{ ref_table = "card.joker_display_values", ref_value = "skip_diff" },
				{ text = ")" },
			},
			calc_function = function(card)
				card.joker_display_values.skip_diff = G.GAME.skips ~= nil
						and MP.GAME.enemy.skips ~= nil
						and localize({
							type = "variable",
							key = MP.GAME.enemy.skips > G.GAME.skips and "a_mp_skips_behind"
								or MP.GAME.enemy.skips == G.GAME.skips and "a_mp_skips_tied"
								or "a_mp_skips_ahead",
							vars = { math.abs(MP.GAME.enemy.skips - G.GAME.skips) },
						})[1]
					or ""
			end,
		}
		jd_def["j_mp_taxes"] = {
			text = {
				{ text = "+", colour = G.C.RED },
				{ ref_table = "card.ability.extra", ref_value = "mult", colour = G.C.RED, retrigger_type = "mult" },
			},
		}
	end
end
