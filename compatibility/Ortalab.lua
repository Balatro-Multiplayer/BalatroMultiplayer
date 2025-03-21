if SMODS.Mods["ortalab"] and SMODS.Mods["ortalab"].can_load then
	sendDebugMessage("Ortalab compatibility detected", "MULTIPLAYER")
	MP.DECK.ban_card("j_ortalab_miracle_cure")
	MP.DECK.ban_card("j_ortalab_grave_digger")
	MP.DECK.ban_card("v_ortalab_abacus")
	MP.DECK.ban_card("v_ortalab_calculator")
end
