MP.Ruleset({
	key = "legacy_ranked",
	layers = { "classic" },
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = false,
			forced_lobby_options = true,
			forced_gamemode_text = "k_attrition",
			description_key = "k_legacy_ranked_description",
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
