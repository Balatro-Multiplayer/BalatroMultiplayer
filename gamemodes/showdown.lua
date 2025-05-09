MP.Gamemode({
    key = "showdown",
    get_blinds_by_ante = function(self, ante)
        if ante > 2 then
            return "bl_mp_nemesis", "bl_mp_nemesis", "bl_mp_nemesis"
        end
        return nil, nil, nil
    end,
}):inject()