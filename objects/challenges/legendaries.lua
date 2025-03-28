SMODS.Challenge({
	key = "legendaries",
	jokers = {
		{ id = "j_caino" },
		{ id = "j_perkeo" },
		{ id = "j_triboulet" },
		{ id = "j_yorick" },
		{ id = "j_joker" },
	},
	restrictions = {
		banned_cards = {
			{ id = "j_selzer" },
			{ id = "j_dusk" },
			{ id = "j_sock_and_buskin" },
			{ id = "j_hanging_chad" },
			{ id = "j_mp_hanging_chad" },
		},
	},
	unlocked = function(self)
		return true
	end,
})
