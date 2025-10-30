SMODS.Back({
	key = "white",
	config = {},
	atlas = "mp_decks",
	pos = { x = 2, y = 1 },
	mp_credits = { art = { "aura!" }, code = { "Toneblock" } },
	apply = function(self)
		if MP.LOBBY.code then
			G.GAME.modifiers.view_nemesis_deck = true
		end
	end,
})
