if TMJ then
    --TMJ v3
    TMJ.ALLOW_HIGHLIGHT = false --this is implemented in a hook, can't move it over here
    G.FUNCS.tmj_spawn = function() error("This is not allowed in Multiplayer") end

    --TMJ v4
    TMJ.FUNCS.CHEAT_TOGGLE = function() return end --this would otherwise return the toggle which allows below config to be changed
    TMJ.config.disable_ctrl_enter = true 
end
