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
		"m_gold",
	},
	on_apply_bans = function()
		change_shop_size(1)
	end,
})
