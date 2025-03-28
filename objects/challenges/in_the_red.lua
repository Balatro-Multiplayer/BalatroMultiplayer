SMODS.Challenge({
	key = "in_the_red",
	rules = {
		custom = {
			{ id = "no_reward_specific", value = "Small" },
			{ id = "no_reward_specific", value = "Big" },
		},
	},
	jokers = {
		{ id = "j_credit_card", eternal = true, edition = "negative", rental = true },
	},
	unlocked = function(self)
		return true
	end,
})
