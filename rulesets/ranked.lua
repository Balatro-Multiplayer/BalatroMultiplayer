MP.Ruleset({
	key = "ranked",
	multiplayer_content = true,
	multiplayer_content = true,
	banned_jokers = {},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds ={},

	reworked_jokers = {
		"j_hanging_chad",
		"j_mp_conjoined_joker",
		"j_mp_defensive_joker",
		"j_mp_lets_go_gambling",
		--"j_mp_magnet",
		"j_mp_pacifist",
		"j_mp_penny_pincher",
		"j_mp_pizza",
		"j_mp_skip_off",
		"j_mp_speedrun",
		"j_mp_taxes",
	},
	reworked_consumables = {
		"c_mp_asteroid"
	},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass"
	},
	reworked_tags = {},
	reworked_blinds = {
		"bl_mp_nemesis"
	},
	forced_gamemode = "gamemode_mp_attrition",
	forced_lobby_options = true,
	is_disabled = function(self)
		local required_version = "1.0.0~BETA-0506a"
		if SMODS.version ~= required_version then
			return localize({type = "variable", key="k_ruleset_disabled_smods_version", vars = {required_version}})
		end
		if not MP.INTEGRATIONS.TheOrder then
			return localize("k_ruleset_disabled_the_order_required")
		end
		return false
	end
}):inject()
