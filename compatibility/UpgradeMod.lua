if SMODS.Mods["upgrademod"] and SMODS.Mods["upgrademod"].can_load then
    function action_asteroid()
        local hand_type = "High Card"
        local max_level = 0
        for k, v in pairs(G.GAME.hands) do
            if to_big(v.level) > to_big(max_level) then
                hand_type = k
                max_level = v.level
            end
        end
        update_hand_text({ sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, {
            handname = localize(hand_type, "poker_hands"),
            chips = G.GAME.hands[hand_type].chips,
            mult = G.GAME.hands[hand_type].mult,
            level = G.GAME.hands[hand_type].level,
        })
        level_up_hand(nil, hand_type, false, -((asteroid_factor or 1) * (planet_level or 1)))
        update_hand_text(
            { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
            { mult = 0, chips = 0, handname = "", level = "" }
        )
    end
end
