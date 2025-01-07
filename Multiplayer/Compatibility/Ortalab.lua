if SMODS.Mods["ortalab"] and SMODS.Mods["ortalab"].can_load then
	sendDebugMessage("Ortalab compatibility detected", "MULTIPLAYER")
	G.MULTIPLAYER.DECK.ban_card("j_ortalab_miracle_cure")
	G.MULTIPLAYER.DECK.ban_card("j_ortalab_grave_digger")
	G.MULTIPLAYER.DECK.ban_card("v_ortalab_abacus")
	G.MULTIPLAYER.DECK.ban_card("v_ortalab_calculator")
end
