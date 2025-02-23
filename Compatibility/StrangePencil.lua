if next(SMODS.find_mod("StrangePencil")) then
    sendDebugMessage("Strange Pencil compatibility detected", "MULTIPLAYER")
    G.MULTIPLAYER.DECK.ban_card("j_pencil_calendar")   -- potential desync
    G.MULTIPLAYER.DECK.ban_card("j_pencil_stonehenge") -- unfair advantage, also potential desync
    G.MULTIPLAYER.DECK.ban_card("c_pencil_chisel")     -- might break phantom
    G.MULTIPLAYER.DECK.ban_card("c_pencil_peek")       -- same reason as Matador
end
