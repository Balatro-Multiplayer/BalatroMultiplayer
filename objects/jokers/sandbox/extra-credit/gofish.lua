SMODS.Joker({
    key = "gofish_sandbox",
    no_collection = MP.sandbox_no_collection,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,

    rarity = 2,
    cost = 6,
    atlas = "ec_jokers_sandbox",
    pos = { x = 9, y = 2 },

    config = {
        extra = {
            fished = false
        },
        mp_sticker_balanced = true,
		mp_sticker_extra_credit = true,
    },

    loc_vars = function(self, info_queue, card)
        local current_rank = G.GAME.current_round.fish_rank and G.GAME.current_round.fish_rank.rank or "Ace"
        return {vars = {current_rank}}
    end,

    calculate = function(self, card, context)
        local contains = function(table_, value)
            for _, v in pairs(table_) do
                if v == value then
                    return true
                end
            end
            return false
        end

        if context.first_hand_drawn and not context.blueprint then
            card.ability.extra.fished = false
            local eval = function() return not card.ability.extra.fished end
            juice_card_until(card, eval, true)

        elseif context.before and not context.blueprint then
            card.ability.extra.fish = {}
            if not card.ability.extra.fished then
                for i=1, #context.scoring_hand do
                    if context.scoring_hand[i].base.value == G.GAME.current_round.fish_rank.rank and not context.scoring_hand[i].debuff then
                        card.ability.extra.fish[#card.ability.extra.fish + 1] = context.scoring_hand[i]
                        card.ability.extra.fished = true
                    end
                end
            end

        elseif context.destroying_card and not context.blueprint then
            return contains(card.ability.extra.fish, context.destroying_card)

        elseif context.after and not context.blueprint then
            card.ability.extra.fish = nil

        elseif context.end_of_round then
            card.ability.extra.fished = true
        end
    end,

    mp_credits = {
        code = { "extracredit" },
        art = { "bishopcorrigan" }
    },
    mp_include = function(self)
        return MP.SANDBOX.is_joker_allowed(self.key)
    end,
})
