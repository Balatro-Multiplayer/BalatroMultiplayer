MP.Gamemode({
    key = "attrition",
    get_blinds_by_ante = function(self, ante)
        if ante > 1 then
            if not MP.LOBBY.config.normal_bosses then
                return nil, nil, "bl_mp_nemesis"
            else
                G.GAME.round_resets.pvp_blind_choices.Boss = true
            end
        end
        return nil, nil, nil
    end,
}):inject()
