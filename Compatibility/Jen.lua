if SMODS.Mods["jen"] and SMODS.Mods["jen"].can_load then
	sendDebugMessage("Jen's compatibility detected", "MULTIPLAYER")
	G.MULTIPLAYER.DECK.ban_card("j_jen_hydrangea")
	G.MULTIPLAYER.DECK.ban_card("j_jen_gamingchair")
	G.MULTIPLAYER.DECK.ban_card("j_jen_kosmos")
	G.MULTIPLAYER.DECK.ban_card("c_jen_entropy")
end
