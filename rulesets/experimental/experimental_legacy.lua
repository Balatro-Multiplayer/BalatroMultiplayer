MP.Ruleset({
	key = "experimental_legacy",
	layers = { "classic", "multiplayer_jokers" },
	forced_gamemode = "gamemode_mp_attrition",
	-- Let MP jokers through but ban everything but LGG
	banned_silent = {
		"j_mp_pizza",
		"j_mp_penny_pincher",
		"j_mp_conjoined_joker",
		"j_mp_pacifist",
		"j_mp_defensive_joker",
		"j_mp_speedrun",
		"j_mp_skip_off",
		"j_mp_taxes",
		"j_hanging_chad",
	},
	banned_consumables = {
		"c_justice",
		"c_mp_asteroid",
	},
	reworked_jokers = {
		"j_mp_hanging_chad",
	},
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return false
	end,
}):inject()
