if SMODS.Mods["jen"] and SMODS.Mods["jen"].can_load then
	sendDebugMessage("Jen's compatibility detected", "MULTIPLAYER")
	MP.DECK.ban_card("j_jen_hydrangea")
	MP.DECK.ban_card("j_jen_gamingchair")
	MP.DECK.ban_card("j_jen_kosmos")
	MP.DECK.ban_card("c_jen_entropy")
end
