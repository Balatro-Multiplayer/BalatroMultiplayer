if SMODS.Mods["draft"] and SMODS.Mods["draft"].can_load then
	sendDebugMessage("Draft compatibility detected", "MULTIPLAYER")
	G.MULTIPLAYER.DECK_TYPE = "draft-sealeddeck"
end
