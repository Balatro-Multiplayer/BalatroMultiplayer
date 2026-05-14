MP.Ruleset({
	key = "experimental_legacy",
	layers = { "classic" },
	forced_gamemode = "gamemode_mp_attrition",
	-- Let MP jokers through but ban everything but LGG
	multiplayer_content = true,
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
		"j_mp_lets_go_gambling",
	},
	hide_continue_button = true,
	get_modifiers_ui = function(self, mode)
		return G.UIDEF.mp_experimental_modifiers_ui(self, mode)
	end,
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return false
	end,
}):inject()
