if SMODS.Mods["HotPotato"] and SMODS.Mods["HotPotato"].can_load then
	sendDebugMessage("HotPotato compatibility detected", "MULTIPLAYER")
	MP.DECK.ban_card("j_hpot_antidsestablishmentarianism") -- sic
	MP.DECK.ban_card("j_hpot_brainfuck")
	MP.DECK.ban_card("j_hpot_goldenchicot")
	MP.DECK.ban_card("j_hpot_lockin")
	MP.DECK.ban_card("j_hpot_lotus")
	MP.DECK.ban_card("j_hpot_c_sharp")

	MP.DECK.ban_card("j_hpot_goblin_tinkerer") -- too easy to infinite
end
