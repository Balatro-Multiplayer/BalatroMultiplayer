MP.Ruleset({
	key = "traditional",
	multiplayer_content = true,
	standard = true,
	banned_silent = {},
	banned_jokers = {
		"j_mp_speedrun",
		"j_mp_conjoined_joker",
	},
	banned_consumables = {
		"c_justice",
		"c_ouija",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	reworked_jokers = {
		"j_hanging_chad",
		"j_idol",
		"j_ticket",
		"j_selzer",
		"j_turtle_bean",
	},
	reworked_consumables = {
		"c_mp_ouija_standard",
	},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass",
	},
	reworked_tags = {},
	reworked_blinds = {},
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = false,
			description_key = "k_traditional_description",
		})
	end,
	force_lobby_options = function(self)
		MP.LOBBY.config.timer = false
		return false
	end,
}):inject()
