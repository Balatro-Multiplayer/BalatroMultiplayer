MP.Ruleset({
	key = "majorleague",
	multiplayer_content = false,
	banned_jokers = {},
	banned_consumables = {},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	banned_silent = { "j_bloodstone" },
	reworked_jokers = { "j_mp_bloodstone" },
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {},
	reworked_tags = {},
	reworked_blinds = {},
	forced_gamemode = "gamemode_mp_attrition",
	forced_lobby_options = true,
	is_disabled = function(self)
		return false
	end,
	force_lobby_options = function(self)
		MP.LOBBY.config.timer_base_seconds = 180
		MP.LOBBY.config.timer_forgiveness = 1
		MP.LOBBY.config.the_order = false
		MP.LOBBY.config.preview_disabled = true
		MP.LOBBY.config.enemy_location_disabled = true
		MP.LOBBY.config.timer_display_threshold = 180
		return true
	end,
}):inject()
