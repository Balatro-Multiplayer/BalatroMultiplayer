MP.Ruleset({
	key = "minorleague",
	multiplayer_content = false,
	banned_jokers = {},
	banned_consumables = {},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	reworked_jokers = {},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {},
	reworked_tags = {},
	reworked_blinds = {},
	forced_gamemode = "gamemode_mp_attrition",
	forced_lobby_options = true,
	force_lobby_options = function(self)
		MP.LOBBY.config.timer_base_seconds = 210
		MP.LOBBY.config.timer_forgiveness = 1
		MP.LOBBY.config.the_order = true
		return true
	end,
}):inject()
