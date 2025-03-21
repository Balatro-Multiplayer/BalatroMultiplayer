if SMODS.Mods["Pokermon"] and SMODS.Mods["Pokermon"].can_load then
	sendDebugMessage("Pokermon compatibility detected", "MULTIPLAYER")
	MP.DECK.ban_card("j_poke_koffing")
	MP.DECK.ban_card("j_poke_weezing")
	MP.DECK.ban_card("j_poke_mimikyu")
end
