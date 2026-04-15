MP.Ruleset({
	key = "blitz",
	layers = { "standard" },
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = false,
			description_key = "k_blitz_description",
		})
	end,
}):inject()
