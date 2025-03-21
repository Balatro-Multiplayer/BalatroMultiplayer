if next(SMODS.find_mod("StrangePencil")) then
    sendDebugMessage("Strange Pencil compatibility detected", "MULTIPLAYER")
    MP.DECK.ban_card("j_pencil_calendar")   -- potential desync
    MP.DECK.ban_card("j_pencil_stonehenge") -- unfair advantage, also potential desync
    MP.DECK.ban_card("c_pencil_chisel")     -- might break phantom
    MP.DECK.ban_card("c_pencil_peek")       -- same reason as Matador
end
