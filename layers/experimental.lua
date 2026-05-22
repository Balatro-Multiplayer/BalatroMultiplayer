MP.Layer("experimental", {
	multiplayer_content = true,
	standard = true,
	banned_silent = {
		"j_hanging_chad",
		"j_ticket",
		"j_selzer",
		"j_bloodstone",
		"c_ouija",
		"j_todo_list",
		"j_idol",
	},
	banned_jokers = {
		"j_mp_speedrun",
	},
	banned_consumables = {
		"c_justice",
	},
	banned_enhancements = {
		"m_glass",
	},
	reworked_jokers = {
		"j_mp_hanging_chad",
		"j_mp_ticket_experimental",
		"j_mp_seltzer",
		"j_mp_todo_list",
		"j_mp_bloodstone",
		"j_mp_idol_rare",
	},
	reworked_consumables = {
		"c_mp_ouija_standard",
	},
	reworked_enhancements = {
		"m_glass",
	},
	on_apply_bans = function()
		change_shop_size(1)
        G.GAME.starting_params.ante_scaling = 1.15
        G.GAME.modifiers.mp_extra_reroll_increment = 1
	end,
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
