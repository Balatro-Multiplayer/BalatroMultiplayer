MP.Ruleset({
	key = "speedlatro",
	layers = { "standard" },
	forced_gamemode = "gamemode_mp_attrition",
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = false,
			forced_gamemode_text = "k_attrition",
			description_key = "k_speedlatro_description",
		})
	end,
}):inject()
