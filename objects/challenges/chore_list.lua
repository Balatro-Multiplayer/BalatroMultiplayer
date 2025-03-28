SMODS.Challenge({
	key = "chore_list",
	jokers = {
		{ id = "j_todo_list", eternal = true, rental = true, edition = "negative" },
		{ id = "j_todo_list", eternal = true, rental = true, edition = "negative" },
	},
	restrictions = {
		banned_cards = {
			{ id = "j_trading" },
			{ id = "j_midas_mask" },
			{ id = "j_golden" },
			{ id = "j_todo_list" },
			{ id = "j_rough_gem" },
			{ id = "j_reserved_parking" },
			{ id = "j_to_the_moon" },
			{ id = "j_business" },
			{ id = "j_delayed_grat" },
			{ id = "j_satellite" },
			{ id = "j_egg" },
			{ id = "j_faceless" },
			{ id = "j_mail" },
			{ id = "j_golden" },
			{ id = "j_gift" },
			{ id = "j_riff_raff" },
			{ id = "j_chaos" },
			{ id = "j_mp_penny_pincher" },
		},
	},
	unlocked = function(self)
		return true
	end,
})
