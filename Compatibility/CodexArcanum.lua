if SMODS.Mods["CodexArcanum"] and SMODS.Mods["CodexArcanum"].can_load then
    sendDebugMessage("Codex Arcanum compatibility detected", "MULTIPLAYER")
    G.MULTIPLAYER.DECK.ban_card("j_breaking_bozo")
    G.MULTIPLAYER.DECK.ban_card("c_alchemy_terra")
end