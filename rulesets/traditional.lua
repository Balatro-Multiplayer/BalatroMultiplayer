MP.Ruleset({
	key = "traditional",
	multiplayer_content = true,
	standard = true,
	banned_jokers = {
		"j_mp_speedrun",
		"j_mp_conjoined_joker",
	},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds ={},

	reworked_jokers = {
		"j_hanging_chad",
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass"
	},
	reworked_tags = {},
	reworked_blinds = {},
}):inject()
