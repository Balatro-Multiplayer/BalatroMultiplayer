MP.Ruleset({
	key = "blitz",
	multiplayer_content = true,
	standard = true,

	banned_jokers = {},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds ={},

	reworked_jokers = {
		"j_hanging_chad",
		"j_mp_conjoined_joker",
		"j_mp_defensive_joker",
		"j_mp_lets_go_gambling",
		--"j_mp_magnet",
		"j_mp_pacifist",
		"j_mp_penny_pincher",
		"j_mp_pizza",
		"j_mp_skip_off",
		"j_mp_speedrun",
		"j_mp_taxes",
	},
	reworked_consumables = {
		"c_mp_asteroid"
	},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass"
	},
	reworked_tags = {},
	reworked_blinds = {
		"bl_mp_nemesis"
	},
}):inject()
