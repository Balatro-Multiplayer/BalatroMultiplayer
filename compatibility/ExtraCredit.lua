if SMODS.Mods["ExtraCredit"] and SMODS.Mods["ExtraCredit"].can_load then
	sendDebugMessage("ExtraCredit compatibility detected", "MULTIPLAYER")
	PVP.DECK.ban_card("j_ExtraCredit_permanentmarker")
end
