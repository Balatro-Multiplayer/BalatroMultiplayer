MP.Ruleset({
	key = "standard_ranked",
	multiplayer_content = true,
	standard = true,
	banned_silent = {
		"j_hanging_chad",
		"j_ticket",
		"j_selzer",
		"j_turtle_bean",
		"j_bloodstone",
		"c_ouija",
	},
	banned_jokers = {},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	reworked_jokers = {
		"j_mp_hanging_chad",
		"j_mp_ticket",
		"j_mp_seltzer",
		"j_mp_turtle_bean",
	},
	reworked_consumables = {
		"c_mp_ouija_standard",
	},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_mp_display_glass",
	},
	reworked_tags = {},
	reworked_blinds = {},
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = true,
			forced_gamemode_text = "k_attrition",
			description_key = "k_standard_ranked_description",
		})
	end,
	forced_gamemode = "gamemode_mp_attrition",
	forced_lobby_options = true,
	is_disabled = function(self)
		if SMODS.version ~= MP.SMODS_VERSION then
			return localize({ type = "variable", key = "k_ruleset_disabled_smods_version", vars = { MP.SMODS_VERSION } })
		end
		local ok, lovely_mod = pcall(require, "lovely")
		local lovely_ver = ok and lovely_mod.version or ""
		if not lovely_ver:match("^" .. MP.REQUIRED_LOVELY_VERSION:gsub("%.", "%%.")) then
			return localize({
				type = "variable",
				key = "k_ruleset_disabled_lovely_version",
				vars = { MP.REQUIRED_LOVELY_VERSION },
			})
		end
		return false
	end,
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return true
	end,
}):inject()
