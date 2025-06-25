if TMJ then
    TMJ.ALLOW_HIGHLIGHT = false --this is implemented in a hook, can't move it over here
    G.FUNCS.tmj_spawn = function() error("This is not allowed in Multiplayer") end
end