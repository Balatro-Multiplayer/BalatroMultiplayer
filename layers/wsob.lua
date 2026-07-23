-- §9.2 ruleset/layer purity migration: WSOB used to declare all of this
-- directly on the ruleset (deliberately not composing `standard`, since WSOB
-- bans/reworks substantially less than the standard pool). Moved verbatim
-- into its own layer so the ruleset is purely `layers = {...}`.
MPAPI.Layer("wsob", {
	banned_silent = {
		"j_hanging_chad",
		"j_bloodstone",
	},
	banned_consumables = {
		"c_justice",
	},
	reworked_jokers = {
		"j_mp_hanging_chad",
		"j_mp_bloodstone",
	},
	reworked_enhancements = {
		"m_glass",
	},
})
