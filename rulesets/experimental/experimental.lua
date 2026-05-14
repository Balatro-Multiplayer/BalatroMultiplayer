MP.Ruleset({
	key = "experimental",
	layers = { "experimental" },
	forced_gamemode = "gamemode_mp_attrition",
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return false
	end,
}):inject()
