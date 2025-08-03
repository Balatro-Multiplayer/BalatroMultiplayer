MP.Ruleset({
	key = "traditional",
	multiplayer_content = true,
	standard = true,
	banned_jokers = {
		"j_mp_speedrun",
		"j_mp_conjoined_joker",
	},
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
						text = MP.UTILS.wrapText(localize("k_traditional_description"), 100),
						scale = 0.4,
						colour = G.C.UI.TEXT_LIGHT,
					}
				}
			}
		}}
	end,
	force_lobby_options = function(self)
		MP.LOBBY.config.timer = false
		return false
	end
}):inject()
