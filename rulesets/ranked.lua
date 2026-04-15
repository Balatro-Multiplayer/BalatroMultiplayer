MP.Ruleset({
	key = "standard_ranked",
	layers = { "standard" },
	forced_gamemode = "gamemode_mp_attrition",
	forced_lobby_options = true,
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = true,
			forced_gamemode_text = "k_attrition",
			description_key = "k_standard_ranked_description",
		})
	end,
	is_disabled = function(self)
		return MP.UTILS.check_smods_version() or MP.UTILS.check_lovely_version()
	end,
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return true
	end,
}):inject()
