SMODS.Challenge({
	key = "lets_go_gambling",
	jokers = {
		{ id = "j_oops", eternal = true, edition = "negative" },
		{ id = "j_mp_lets_go_gambling", eternal = true, edition = "negative" },
	},
	restrictions = {
		banned_cards = {
			{ id = "c_high_priestess" },
			{ id = "c_empress" },
			{ id = "c_heirophant" },
			{ id = "c_chariot" },
			{ id = "c_justice" },
			{ id = "c_hermit" },
			{ id = "c_strength" },
			{ id = "c_hanged_man" },
			{ id = "c_death" },
			{ id = "c_temperance" },
			{ id = "c_devil" },
			{ id = "c_tower" },
			{ id = "c_star" },
			{ id = "c_moon" },
			{ id = "c_sun" },
			{ id = "c_world" },
		},
	},
	unlocked = function(self)
		return true
	end,
})
