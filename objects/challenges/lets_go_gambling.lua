SMODS.Challenge({
	key = "lets_go_gambling",
	rules = {
		custom = {
			{ id = "no_reward_specific", value = "Small" },
			{ id = "no_reward_specific", value = "Big" },
		},
	},
	jokers = {
		{ id = "j_oops", eternal = true, rental = true },
		{ id = "j_mp_lets_go_gambling", eternal = true, edition = "negative", rental = true },
	},
	restrictions = {
		banned_cards = {
			{ id = "j_selzer" },
			{ id = "j_dusk" },
			{ id = "j_hanging_chad" },
			{ id = "j_bloodstone" },
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
	deck = {
		type = "Challenge Deck",
		enhancement = "m_lucky"
	},
	unlocked = function(self)
		return true
	end,
})
