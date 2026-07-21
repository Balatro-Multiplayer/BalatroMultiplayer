PVP.Ruleset({
	key = "traditional",
	layers = { "standard" },
	banned_jokers = {
		"j_mp_speedrun",
		"j_mp_conjoined_joker",
	},
	force_lobby_options = function(self)
		PVP.LOBBY.config.timer = false
		return false
	end,
}):inject()
