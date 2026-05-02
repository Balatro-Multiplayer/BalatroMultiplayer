MP.Ruleset({
	key = "experimental",
	layers = { "experimental", "pressure_timer" },
	forced_gamemode = "gamemode_mp_attrition",
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return false
	end,
}):inject()

-- TODO: instead of forking experimental into N rulesets per timer/balance combo,
-- expose toggles in lobby options (e.g. timer variant: pressure | no_animation,
-- experimental balance: on | off) and let one ruleset cover the matrix.
