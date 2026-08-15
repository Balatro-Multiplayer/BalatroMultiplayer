MP.Ruleset({
	key = "sandbox",
	layers = { "sandbox" },

	forced_lobby_options = true,

	force_lobby_options = function(self)
		MP.LOBBY.config.preview_disabled = true
		MP.LOBBY.config.the_order = true
		MP.LOBBY.config.starting_lives = 4
		return false
	end,
}):inject()
