SMODS.Challenge({
	key = "vantablack",
	rules = {
		custom = {
			{ id = "mp_vantablack_CREDITS" },
		},
		modifiers = {
			{ id = "joker_slots", value = 8 },
			{ id = "hands", value = 1 },
		},
	},
	apply = function(self)
		G.GAME.selected_back.atlas = "mp_decks"
		G.GAME.selected_back.pos = { x = 3, y = 1 }
	end,
	unlocked = function(self)
		return true
	end,
})