if SMODS.Mods["CodexArcanum"] and SMODS.Mods["CodexArcanum"].can_load then
	sendDebugMessage("Codex Arcanum compatibility detected", "MULTIPLAYER")
	PVP.DECK.ban_card("j_breaking_bozo")
	PVP.DECK.ban_card("c_alchemy_terra")
end
