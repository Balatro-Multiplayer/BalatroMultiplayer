MP.Ruleset({
	key = "minorleague",
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
						text = MP.UTILS.wrapText(localize("k_minorleague_description"), 100),
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
		if not MP.INTEGRATIONS.TheOrder then
			return localize("k_ruleset_disabled_the_order_required")
		end
		return false
	end
}):inject()
