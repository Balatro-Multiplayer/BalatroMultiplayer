if SMODS.Mods["Pokermon"] and SMODS.Mods["Pokermon"].can_load then
	sendDebugMessage("Pokermon compatibility detected", "MULTIPLAYER")
	G.MULTIPLAYER.DECK.ban_card("j_poke_koffing")
	G.MULTIPLAYER.DECK.ban_card("j_poke_weezing")
	G.MULTIPLAYER.DECK.ban_card("j_poke_mimikyu")
end
