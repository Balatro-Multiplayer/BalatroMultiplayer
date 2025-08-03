MP.Ruleset({
	key = "vanilla",
	multiplayer_content = false,
	banned_jokers = {},
	banned_consumables = {},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	reworked_jokers = {},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {},
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
						text = MP.UTILS.wrapText(localize("k_vanilla_description"), 100),
						scale = 0.4,
						colour = G.C.UI.TEXT_LIGHT,
					}
				}
			}
		}}
	end,
}):inject()
