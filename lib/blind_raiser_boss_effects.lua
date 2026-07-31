-------------------------------------------------------------------
-- BLIND RAISER: STACKABLE VANILLA BOSS EFFECT COMPONENTS
--
-- These are effect modules, not SMODS.Blind objects.
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS = MP.BLIND_RAISER_COMPONENTS or {}

-------------------------------------------------------------------
-- THE HOOK
-------------------------------------------------------------------

-- Not part of The Devil's own roll pool, but available as a Platinum
-- replacement/stack component. Mirrors vanilla's two random discards when a
-- hand is played.
MP.BLIND_RAISER_COMPONENTS.bl_hook_the_hook = {
    loc_name = "The Hook",

    calculate = function(self, blind, context)
        if not context.press_play then return end
        G.E_MANAGER:add_event(Event({ func = function()
            local available = {}
            for _, card in ipairs((G.hand and G.hand.cards) or {}) do
                available[#available + 1] = card
            end
            local selected = false
            for _ = 1, math.min(2, #available) do
                local card, index = pseudorandom_element(available, pseudoseed("mp_blind_raiser_hook"))
                if not card then break end
                G.hand:add_to_highlighted(card, true)
                table.remove(available, index)
                selected = true
                play_sound("card1", 1)
            end
            if selected then G.FUNCS.discard_cards_from_highlighted(nil, true) end
            return true
        end }))
        blind.triggered = true
        delay(0.7)
    end,
}


-------------------------------------------------------------------
-- THE OX
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_ox = {
    loc_name = "The Ox",

    calculate = function(self, blind, context)
        if context.debuff_hand
            and context.scoring_name == G.GAME.current_round.most_played_poker_hand
        then
            blind.triggered = true
            if not context.check then
                ease_dollars(-G.GAME.dollars, true)
                blind:wiggle()
            end
        end
    end,
}


-------------------------------------------------------------------
-- THE ARM
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_arm = {
    loc_name = "The Arm",

    calculate = function(self, blind, context)
        local hand = context.debuff_hand and context.scoring_name
        if hand and G.GAME.hands[hand] and G.GAME.hands[hand].level > 1 then
            blind.triggered = true
            if not context.check then
                level_up_hand(blind.children.animatedSprite, hand, nil, -1)
                blind:wiggle()
            end
        end
    end,
}



-------------------------------------------------------------------
-- THE HOUSE
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_house = {


    loc_name = "The House",



    set_blind = function(self)

        self.active = true

    end,



    calculate = function(self, blind, context)



        if context.blind_disabled then


            for _,card in ipairs(G.hand.cards) do

                if card.facing == "back" then

                    card:flip()

                end

            end


            for _,card in ipairs(G.playing_cards) do

                card.ability.wheel_flipped = nil
            end


        end




        if context.stay_flipped
        and context.to_area == G.hand
        and G.GAME.current_round.hands_played == 0
        and G.GAME.current_round.discards_used == 0
        then


            return {

                stay_flipped = true

            }


        end


    end


}






-------------------------------------------------------------------
-- THE WALL
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_wall = {


    loc_name = "The Wall",



    calculate = function(self, blind, context)



        if context.blind_disabled then


            G.GAME.blind.chips =
                G.GAME.blind.chips / 2


            G.GAME.blind.chip_text =
                number_format(
                    G.GAME.blind.chips
                )


        end



    end


}






-------------------------------------------------------------------
-- THE WHEEL
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_wheel = {


    loc_name = "The Wheel",



    calculate = function(self, blind, context)


        if context.stay_flipped
        and context.to_area == G.hand
        and SMODS.pseudorandom_probability(
            blind,
            "devil_wheel",
            1,
            7
        )
        then


            return {

                stay_flipped = true

            }


        end


    end


}






-------------------------------------------------------------------
-- THE CLUB
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_club = {


    loc_name = "The Club",


    debuff = {
        suit = "Clubs"
    },

    calculate = function(self, blind, context)
        if context.debuff_card and context.debuff_card:is_suit("Clubs") then
            return { debuff = true }
        end
    end,
}






-------------------------------------------------------------------
-- THE FISH
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_fish = {

    loc_name = "The Fish",

    set_blind = function(self)
        self.prepped = false
        self.cards_to_flip = 0
    end,

    calculate = function(self, blind, context)
        -- Playing a hand arms The Fish for the next draw-to-hand batch.
        if context.press_play then
            self.prepped = true
            self.cards_to_flip = 0
        end

        -- Capture only the next draw batch, then disarm the effect so draws
        -- caused by a later discard are face up.
        if context.drawing_cards and self.prepped then
            self.cards_to_flip = context.amount or 0
            self.prepped = false
        end

        if context.stay_flipped
            and context.to_area == G.hand
            and (self.cards_to_flip or 0) > 0
        then
            self.cards_to_flip = self.cards_to_flip - 1
            return { stay_flipped = true }
        end

        if context.blind_disabled or context.blind_defeated then
            self.prepped = false
            self.cards_to_flip = 0
        end
    end,
}


-------------------------------------------------------------------
-- THE PSYCHIC
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_psychic = {


    loc_name = "The Psychic",


    debuff = {

        h_size_ge = 5

    }


}






-------------------------------------------------------------------
-- THE GOAD
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_goad = {


    loc_name = "The Goad",


    debuff = {
        suit = "Spades"
    },

    calculate = function(self, blind, context)
        if context.debuff_card and context.debuff_card:is_suit("Spades") then
            return { debuff = true }
        end
    end,
}






-------------------------------------------------------------------
-- THE WINDOW
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_window = {


    loc_name = "The Window",


    debuff = {
        suit = "Diamonds"
    },

    calculate = function(self, blind, context)
        if context.debuff_card
        and context.debuff_card:is_suit("Diamonds")
        then
            return {
                debuff = true
            }
        end
    end


}






-------------------------------------------------------------------
-- THE MANACLE
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_manacle = {


    loc_name = "The Manacle",



    set_blind = function(self)
        -- Component tables are singletons, so keep the adjustment idempotent.
        -- This prevents Chicot/Luchador cleanup and round-end cleanup from
        -- restoring the same -1 hand-size penalty twice.
        if not self.handsize_penalty_applied then
            G.hand:change_size(-1)
            self.handsize_penalty_applied = true
        end
    end,

    calculate = function(self, blind, context)
        if (context.blind_disabled or context.blind_defeated)
            and self.handsize_penalty_applied
        then
            G.hand:change_size(1)
            self.handsize_penalty_applied = false
        end
    end


}







-------------------------------------------------------------------
-- THE EYE
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_eye = {


    loc_name = "The Eye",



    set_blind = function(self)


        self.hands = {}


        for _,hand in ipairs(G.handlist) do

            self.hands[hand] = false

        end


    end,



    calculate = function(self, blind, context)



        if context.debuff_hand then



            if self.hands[context.scoring_name] then



                return {


                    debuff = true


                }



            end




            if not context.check then


                self.hands[context.scoring_name] = true



            end



        end



    end


}








-------------------------------------------------------------------
-- THE MOUTH
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_mouth = {


    loc_name = "The Mouth",



    set_blind = function(self)

        self.only_hand = nil

    end,



    calculate = function(self, blind, context)



        if context.debuff_hand then



            if self.only_hand
            and self.only_hand ~= context.scoring_name
            then


                return {


                    debuff = true


                }


            end





            if not context.check then


                self.only_hand =
                    context.scoring_name



            end



        end



    end


}








-------------------------------------------------------------------
-- THE PLANT
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_plant = {


    loc_name = "The Plant",



    set_blind = function(self)


        self.active = true


    end,



    calculate = function(self, blind, context)



        if context.debuff_card
        and context.debuff_card:is_face(true)
        then


            return {


                debuff = true


            }


        end



    end



}







-------------------------------------------------------------------
-- THE SERPENT
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_serpent = {


    loc_name = "The Serpent",



    calculate = function(self, blind, context)



        if context.drawing_cards
        and (
            G.GAME.current_round.hands_played ~= 0
            or
            G.GAME.current_round.discards_used ~= 0
        )
        then


            return {


                cards_to_draw = 3


            }


        end


    end


}








-------------------------------------------------------------------
-- THE PILLAR
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_pillar = {


    loc_name = "The Pillar",



    calculate = function(self, blind, context)



        if context.debuff_card
        and context.debuff_card.area ~= G.jokers
        and context.debuff_card.ability.played_this_ante
        then



            return {


                debuff = true


            }


        end


    end


}








-------------------------------------------------------------------
-- THE NEEDLE
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_needle = {

    loc_name = "The Needle",

    calculate = function(self, blind, context)
        -- Match the vanilla Blind lifecycle instead of directly assigning
        -- hands_left in set_blind. In particular, this leaves round-start Tag
        -- processing (including Juggle Tag's hand-size change) untouched.
        if context.setting_blind then
            local hands_left = G.GAME.current_round.hands_left
                or G.GAME.round_resets.hands
                or 1

            self.hands_sub = math.max(0, hands_left - 1)
            self.hands_restored = false

            if self.hands_sub > 0 then
                ease_hands_played(-self.hands_sub)
            end
        end

        if (context.blind_disabled or context.blind_defeated)
            and not self.hands_restored
        then
            if (self.hands_sub or 0) > 0 then
                ease_hands_played(self.hands_sub)
            end
            self.hands_restored = true
        end
    end,
}


-------------------------------------------------------------------
-- THE HEAD
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_head = {


    loc_name = "The Head",



    debuff = {
        suit = "Hearts"
    },

    calculate = function(self, blind, context)
        if context.debuff_card and context.debuff_card:is_suit("Hearts") then
            return { debuff = true }
        end
    end,
}







-------------------------------------------------------------------
-- THE MARK
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_mark = {


    loc_name = "The Mark",



    calculate = function(self, blind, context)



        if context.stay_flipped
        and context.to_area == G.hand
        and context.other_card
        and context.other_card:is_face(true)
        then



            return {


                stay_flipped = true


            }



        end


    end


}








-------------------------------------------------------------------
-- THE FLINT
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_flint = {


    loc_name = "The Flint",



    calculate = function(self, blind, context)



        if context.modify_hand then



            blind.triggered = true



            mult =
                mod_mult(
                    math.max(
                        math.floor(
                            mult * 0.5 + 0.5
                        ),
                        1
                    )
                )



            hand_chips =
                mod_chips(
                    math.max(
                        math.floor(
                            hand_chips * 0.5 + 0.5
                        ),
                        0
                    )
                )



            update_hand_text(

                {
                    sound = 'chips2',
                    modded = true
                },

                {
                    chips = hand_chips,
                    mult = mult
                }

            )



        end


    end


}







-------------------------------------------------------------------
-- THE WATER
-------------------------------------------------------------------

MP.BLIND_RAISER_COMPONENTS.bl_hook_the_water = {


    loc_name = "The Water",



    set_blind = function(self)



        self.discards_sub =
            G.GAME.current_round.discards_left



        ease_discard(
            -self.discards_sub
        )


    end,



    calculate = function(self, blind, context)



        if context.blind_disabled then



            ease_discard(
                self.discards_sub
            )



        end


    end


}








-------------------------------------------------------------------
-- THE TOOTH
-------------------------------------------------------------------

-- Kept out of The Devil's own roll pool, but exposed as a stackable Platinum
-- Boss effect. The selected cards are still in G.hand.highlighted when the
-- press_play context fires.
MP.BLIND_RAISER_COMPONENTS.bl_hook_the_tooth = {
    loc_name = "The Tooth",

    calculate = function(self, blind, context)
        if context.press_play then
            local count = G.hand and G.hand.highlighted and #G.hand.highlighted or 0
            if count > 0 then
                blind.triggered = true
                ease_dollars(-count)
            end
        end
    end,
}
