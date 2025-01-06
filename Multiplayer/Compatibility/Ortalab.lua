if SMODS.Mods["ortalab"] and SMODS.Mods["ortalab"].can_load then
	sendDebugMessage("Ortalab compatibility detected", "MULTIPLAYER")
	G.MULTIPLAYER.DECK.ban_card("j_ortalab_flashback")
	G.MULTIPLAYER.DECK.ban_card("j_ortalab_miracle_cure")
	G.MULTIPLAYER.DECK.ban_card("j_ortalab_grave_digger")
	G.MULTIPLAYER.DECK.ban_card("v_ortalab_abacus")
	G.MULTIPLAYER.DECK.ban_card("v_ortalab_calculator")
	G.MULTIPLAYER.DECK.ban_card("v_ortalab_home_delivery")
	G.MULTIPLAYER.DECK.ban_card("v_ortalab_hoarding")

	G.MULTIPLAYER.DECK.ban_tag("tag_ortalab_minion")
end
