MP.Ruleset({
	key = "ranked",
	multiplayer_content = true,
	standard = true,
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
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass"
	},
	reworked_tags = {},
	reworked_blinds = {},
	create_info_menu = function ()
		return {{
			n = G.UIT.R,
			config = {
				align = "tm"
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = MP.UTILS.wrapText(localize("k_ranked_description"), 100),
						scale = 0.4,
						colour = G.C.UI.TEXT_LIGHT,
					}
				}
			}
		}}
	end,
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
