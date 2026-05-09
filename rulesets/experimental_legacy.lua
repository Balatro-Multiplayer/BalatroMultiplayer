MP.Ruleset({
	key = "experimental_legacy",
	layers = { "classic", "ranked" },
	forced_gamemode = "gamemode_mp_attrition",
	-- Override classic's multiplayer_content=false so j_mp_lets_go_gambling's
	-- bespoke mp_include passes. Other top-level MP jokers/consumables that
	-- gate only on multiplayer_jokers are explicitly banned below.
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
}):inject()
