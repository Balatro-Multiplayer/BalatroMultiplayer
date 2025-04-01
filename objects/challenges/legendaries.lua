SMODS.Challenge({
	key = "legendaries",
	rules = {
		modifiers = {
			{
				id = "joker_slots",
				value = 6
			}
		}
	},
	jokers = {
		{ id = "j_caino", eternal = true },
		{ id = "j_perkeo", eternal = true },
		{ id = "j_triboulet", eternal = true },
		{ id = "j_yorick", eternal = true },
		{ id = "j_joker" },
	},
	restrictions = {
		banned_cards = {
			{ id = "j_selzer" },
			{ id = "j_dusk" },
			{ id = "j_sock_and_buskin" },
			{ id = "j_hanging_chad" },
			{ id = "j_mp_hanging_chad" },
			{ id = "j_blueprint" },
			{ id = "j_brainstorm" },
		},
	},
	unlocked = function(self)
		return true
	end,
})
