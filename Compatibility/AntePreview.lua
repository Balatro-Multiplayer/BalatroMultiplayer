if next(SMODS.find_mod("AntePreview")) then
    sendDebugMessage("Next Ante Preview compatibility detected", "MULTIPLAYER")
    local predict_next_ante_ref = predict_next_ante
    function predict_next_ante()
        local predictions = predict_next_ante_ref()
        if G.LOBBY.code then
            if G.LOBBY.config.gamemode == "attrition" and G.GAME.round_resets.ante > 1 then
                predictions.Boss.blind = "bl_pvp"
            elseif G.LOBBY.config.gamemode == "showdown" and G.GAME.round_resets.ante >= G.LOBBY.config.showdown_starting_antes then
                predictions.Small.blind = "bl_pvp"
                predictions.Big.blind = "bl_pvp"
                predictions.Boss.blind = "bl_pvp"
            end
        end
        return predictions
    end
end
