-- Credit to @MathIsFun_ for creating TheOrder, which this integration is a copy of
-- Patches card creation to not be ante-based and use a single pool for every type/rarity
local cc = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    if MP.INTEGRATIONS.TheOrder then
        local a = G.GAME.round_resets.ante
        G.GAME.round_resets.ante = 0
        local c = cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, _rarity)
        G.GAME.round_resets.ante = a
        return c
    end
    return cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, _rarity)
end