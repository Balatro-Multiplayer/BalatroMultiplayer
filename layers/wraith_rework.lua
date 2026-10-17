-- Wraith Rework: swaps vanilla Wraith for c_mp_wraith (random Uncommon + $5).
MP.Layer("wraith_rework", {
	reworked_consumables = {
		"c_mp_wraith",
	},
	banned_silent = {
		"c_wraith",
	},
	mutator = {
		category = "ECONOMY",
		order = 5,
		label = "Kind Wraith",
		desc = { "Wraith creates a random", "Uncommon Joker and gives $5.", "Keeps your current money." },
		credits = { code = { "steph" } },
	},
})
