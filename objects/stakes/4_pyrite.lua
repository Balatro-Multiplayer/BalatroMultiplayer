if MP.EXPERIMENTAL.alt_stakes then
	SMODS.Stake({
		mp_alt_stake = true,
		name = "Pyrite Stake",
		key = "pyrite",
		unlocked = true,
		applied_stakes = { "ferrite" },
		above_stake = "ferrite",
		atlas = "alt_mp_stakes",
		pos = { x = 4, y = 0 },
		sticker_pos = { x = 3, y = 1 },
		modifiers = function()
			G.GAME.modifiers.mp_extra_reroll_increment = 1
		end,
		colour = HEX("F2D955"),
		-- shiny = true,
	})

	local calculate_reroll_cost_ref = calculate_reroll_cost
	function calculate_reroll_cost(skip_increment)
		calculate_reroll_cost_ref(skip_increment)
		if G.GAME.modifiers and G.GAME.modifiers.mp_extra_reroll_increment then
			if not skip_increment then
				G.GAME.current_round.reroll_cost_increase = G.GAME.current_round.reroll_cost_increase
					+ G.GAME.modifiers.mp_extra_reroll_increment
			end
			G.GAME.current_round.reroll_cost = (G.GAME.round_resets.temp_reroll_cost or G.GAME.round_resets.reroll_cost)
				+ G.GAME.current_round.reroll_cost_increase
		end
	end
end
