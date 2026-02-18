MP.Ruleset({
	key = "speedlatro",
	multiplayer_content = true,
	standard = true,
	banned_silent = {},
	banned_jokers = {},
	banned_consumables = {
		"c_justice",
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
			forced_gamemode_text = "k_attrition",
			description_key = "k_speedlatro_description",
		})
	end,
	forced_gamemode = "gamemode_mp_attrition",
}):inject()
