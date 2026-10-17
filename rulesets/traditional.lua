MP.Ruleset({
	key = "traditional",
	layers = { "multiplayer_jokers", "standard" },
	banned_jokers = {
		"j_mp_speedrun",
		"j_mp_conjoined_joker",
	},
	force_lobby_options = function(self)
		MP.LOBBY.config.timer = false
		return false
	end,
}):inject()
