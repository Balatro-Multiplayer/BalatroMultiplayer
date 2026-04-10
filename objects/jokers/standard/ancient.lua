SMODS.Joker:take_ownership("j_ancient", {
    loc_vars = function(self, info_queue, card)
        local vars, main_start, main_end = card:generate_UIBox_ability_table(true)
        if card.area and card.area.config.type == "title" and MP.LOBBY.code then
            vars[2] = "???"
            if vars.colours then
                vars.colours[1] = G.C.ORANGE
            end
        end
        return {
            vars = vars,
            main_start = main_start,
            main_end = main_end,
        }
    end
}, true)