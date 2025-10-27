SMODS.Back({
	key = "white",
	config = {},
	atlas = "mp_decks",
	pos = { x = 2, y = 1 },
	mp_credits = { art = { "aura!" }, code = { "Toneblock" } },
	apply = function(self)
		G.GAME.modifiers.mp_white = true
	end,
})
