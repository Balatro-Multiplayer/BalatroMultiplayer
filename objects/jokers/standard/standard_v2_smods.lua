-- TODO split up into separate files
SMODS.Joker({
	key = "idol",
	unlocked = false,
	blueprint_compat = true,
	rarity = 2,
	cost = 6,
	pos = { x = 6, y = 7 },
	config = { extra = { xmult = 1.5 } },
	loc_vars = function(self, info_queue, card)
		local idol_card = G.GAME.current_round.idol_card or { rank = "Ace", suit = "Spades" }
		return {
			vars = {
				card.ability.extra.xmult,
				localize(idol_card.rank, "ranks"),
				localize(idol_card.suit, "suits_plural"),
				colours = { G.C.SUITS[idol_card.suit] },
			},
		}
	end,
	calculate = function(self, card, context)
		if
			context.individual
			and context.cardarea == G.play
			and context.other_card:get_id() == G.GAME.current_round.idol_card.id
			and context.other_card:is_suit(G.GAME.current_round.idol_card.suit)
		then
			return {
				xmult = card.ability.extra.xmult,
			}
		end
	end,
	mp_include = function(self)
		return MP.UTILS.is_standard_ruleset() and MP.LOBBY.code
	end,
})

SMODS.Joker({
	key = "ticket",
	unlocked = false,
	blueprint_compat = true,
	rarity = 2,
	cost = 6,
	pos = { x = 5, y = 3 },
	config = { extra = { dollars = 4 } },
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.m_gold
		return { vars = { card.ability.extra.dollars } }
	end,
	calculate = function(self, card, context)
		if
			context.individual
			and context.cardarea == G.play
			and SMODS.has_enhancement(context.other_card, "m_gold")
		then
			G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
			return {
				dollars = card.ability.extra.dollars,
				func = function() -- This is for timing purposes, it runs after the dollar manipulation
					G.E_MANAGER:add_event(Event({
						func = function()
							G.GAME.dollar_buffer = 0
							return true
						end,
					}))
				end,
			}
		end
	end,
	mp_include = function(self)
		return MP.UTILS.is_standard_ruleset() and MP.LOBBY.code
	end,
})

SMODS.Joker({
	key = "seltzer",
	blueprint_compat = true,
	eternal_compat = false,
	rarity = 1,
	cost = 5,
	pos = { x = 3, y = 15 },
	config = { extra = { hands_left = 10 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.hands_left } }
	end,
	-- todo replace with new stuff from standard v2
	calculate = function(self, card, context)
		if context.first_hand_drawn then
			if MP.is_pvp_boss() then card.ability.extra.effect_disabled = true end
			local eval = function()
				return not MP.is_pvp_boss()
			end
			juice_card_until(card, eval, true)
		end
		if context.repetition and context.cardarea == G.play and not MP.is_pvp_boss() then
			return {
				repetitions = 1,
			}
		end
		if context.after and not context.blueprint and not MP.is_pvp_boss() then
			if card.ability.extra.hands_left - 1 <= 0 then
				SMODS.destroy_cards(card, nil, nil, true)
				return {
					message = localize("k_drank_ex"),
					colour = G.C.FILTER,
				}
			else
				card.ability.extra.hands_left = card.ability.extra.hands_left - 1
				return {
					message = card.ability.extra.hands_left .. "",
					colour = G.C.FILTER,
				}
			end
		end
		if context.end_of_round and context.game_over == false and context.main_eval then
			card.ability.extra.effect_disabled = false
		end
	end,
	mp_include = function(self)
		return MP.UTILS.is_standard_ruleset() and MP.LOBBY.code
	end,
})

SMODS.Joker({
	key = "turtle_bean",

	-- no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = false,
	rarity = 1,
	cost = 5,
	pos = { x = 4, y = 13 },
	config = { extra = { h_size = 5, h_mod = 1 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.h_size, card.ability.extra.h_mod } }
	end,
	calculate = function(self, card, context)
		if context.first_hand_drawn and MP.is_pvp_boss() and not context.blueprint then
			G.hand:change_size(-card.ability.extra.h_size)
			card.ability.extra.effect_disabled = true
		end
		if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
			if MP.is_pvp_boss() then
				G.hand:change_size(card.ability.extra.h_size)
				card.ability.extra.effect_disabled = false
			else
				if card.ability.extra.h_size - card.ability.extra.h_mod <= 0 then
					SMODS.destroy_cards(card, nil, nil, true)
					return {
						message = localize("k_eaten_ex"),
						colour = G.C.FILTER,
					}
				else
					card.ability.extra.h_size = card.ability.extra.h_size - card.ability.extra.h_mod
					G.hand:change_size(-card.ability.extra.h_mod)
					return {
						message = localize({
							type = "variable",
							key = "a_handsize_minus",
							vars = { card.ability.extra.h_mod },
						}),
						colour = G.C.FILTER,
					}
				end
			end
		end
	end,
	add_to_deck = function(self, card, from_debuff)
		if not MP.is_pvp_boss() then
			G.hand:change_size(card.ability.extra.h_size)
		else
			card.ability.extra.effect_disabled = true
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not card.ability.extra.effect_disabled then G.hand:change_size(-card.ability.extra.h_size) end
	end,
	mp_include = function(self)
		return MP.UTILS.is_standard_ruleset() and MP.LOBBY.code
	end,
})
