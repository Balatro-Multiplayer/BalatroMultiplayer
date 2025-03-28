local deck_cards = {}
for i = 1, 52 do
	deck_cards[i] = { s = "S", r = "T" }
end

SMODS.Challenge({
	key = "misprint_deck",
	deck = {
		type = "Challenge Deck",
		cards = deck_cards,
	},
	unlocked = function(self)
		return true
	end,
})
