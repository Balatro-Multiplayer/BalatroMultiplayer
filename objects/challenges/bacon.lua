SMODS.Challenge({
	key = "bacon",
	rules = {
		custom = {
			{ id = "mp_indigo" },
		},
	},
	restrictions = {
		banned_cards = {
			{
				id = "p_celestial_normal_1",
				ids = {
					"p_celestial_normal_2",
					"p_celestial_normal_3",
					"p_celestial_normal_4",
					"p_celestial_jumbo_1",
					"p_celestial_jumbo_2",
					"p_celestial_mega_1",
					"p_celestial_mega_2",
				},
			},
			{
				id = "p_standard_normal_1",
				ids = {
					"p_standard_normal_2",
					"p_standard_normal_3",
					"p_standard_normal_4",
					"p_standard_jumbo_1",
					"p_standard_jumbo_2",
					"p_standard_mega_1",
					"p_standard_mega_2",
				},
			},
			{
				id = "p_arcana_normal_1",
				ids = {
					"p_arcana_normal_2",
					"p_arcana_normal_3",
					"p_arcana_normal_4",
					"p_arcana_jumbo_1",
					"p_arcana_jumbo_2",
					"p_arcana_mega_1",
					"p_arcana_mega_2",
				},
			},
		}
	},

	apply = function(self)
		G.GAME.selected_back.atlas = "mp_decks"
		G.GAME.selected_back.pos = { x = 1, y = 0 }
		G.GAME.modifiers.booster_choice_mod = (G.GAME.modifiers.booster_choice_mod or 0) + 1
	end,
	unlocked = function(self)
		return true
	end,
})