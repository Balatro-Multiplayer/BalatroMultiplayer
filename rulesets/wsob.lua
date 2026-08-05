-- World Series of Balatro Ruleset

-- Layerless on purpose: WSOB is *not* the standard pool (no MP-original
-- content, far fewer reworks), so it declares its bans/reworks directly rather
-- than composing `standard`
MP.Ruleset({
	key = "wsob",
    layers = { "ranked" }, -- let's gate on version though
	multiplayer_content = false,
	banned_silent = {
		"j_hanging_chad",
		"j_bloodstone",
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
		"j_mp_bloodstone",
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass",
	},
	reworked_tags = {},
	reworked_blinds = {},
}):inject()
