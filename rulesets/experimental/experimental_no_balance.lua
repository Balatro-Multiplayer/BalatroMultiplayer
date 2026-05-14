MP.Ruleset({
	key = "experimental_no_balance",
	layers = { "standard" },
	forced_gamemode = "gamemode_mp_attrition",
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return false
	end,
	hide_continue_button = true,
	get_modifiers_ui = function(self, mode)
		return G.UIDEF.mp_experimental_modifiers_ui(self, mode)
	end,
}):inject()
