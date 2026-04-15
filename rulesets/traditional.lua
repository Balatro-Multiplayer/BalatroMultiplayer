MP.Ruleset({
	key = "traditional",
	layers = { "standard" },
	banned_jokers = {
		"j_mp_speedrun",
		"j_mp_conjoined_joker",
	},
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = false,
			description_key = "k_traditional_description",
		})
	end,
	force_lobby_options = function(self)
		MP.LOBBY.config.timer = false
		return false
	end,
}):inject()
