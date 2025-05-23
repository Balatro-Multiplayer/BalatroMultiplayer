if SMODS.Mods["upgrademod"] and SMODS.Mods["upgrademod"].can_load then
    function action_asteroid()
        local hand_priority = {
            ["Flush Five"] = 1,
            ["Flush House"] = 2,
            ["Five of a Kind"] = 3,
            ["Straight Flush"] = 4,
            ["Four of a Kind"] = 5,
            ["Full House"] = 6,
            ["Flush"] = 7,
            ["Straight"] = 8,
            ["Three of a Kind"] = 9,
            ["Two Pair"] = 11,
            ["Pair"] = 12,
            ["High Card"] = 13
        }
        local hand_type = "High Card"
        local max_level = 0

        for k, v in pairs(G.GAME.hands) do
            if v.visible then
                if to_big(v.level) > to_big(max_level) or
                    (to_big(v.level) == to_big(max_level) and
                        hand_priority[k] < hand_priority[hand_type]) then
                    hand_type = k
                    max_level = v.level
                end
            end
        end

        update_hand_text(
            { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
            {
                handname = localize(hand_type, "poker_hands"),
                chips = G.GAME.hands[hand_type].chips,
                mult = G.GAME.hands[hand_type].mult,
                level = G.GAME.hands[hand_type].level,
            }
        )

        level_up_hand(
            nil,
            hand_type,
            false,
            -((asteroid_factor or 1) * (planet_level or 1))
        )

        update_hand_text(
            { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
            { mult = 0, chips = 0, handname = "", level = "" }
        )
    end
end
