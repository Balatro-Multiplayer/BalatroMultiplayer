SMODS.Joker({
	key = "idol_rare",
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 3,
	cost = 8,
	pos = { x = 5, y = 8 },
	no_collection = true,
	config = { extra = { Xmult = 2 }, mp_balanced = true },
	loc_vars = function(self, info_queue, card)
		local idol = G.GAME.current_round.idol_card or { rank = "Ace", suit = "Spades" }
		return {
			key = "j_idol",
			vars = {
				card.ability.extra.Xmult,
				localize(idol.rank, "ranks"),
				localize(idol.suit, "suits_singular"),
				colours = { G.C.SUITS[idol.suit] },
			},
		}
	end,
	calculate = function(self, card, context)
		if
			context.individual
			and context.cardarea == G.play
			and not context.blueprint
			and G.GAME.current_round.idol_card
			and context.other_card:get_id() == G.GAME.current_round.idol_card.id
			and context.other_card:is_suit(G.GAME.current_round.idol_card.suit)
		then
			return {
				x_mult = card.ability.extra.Xmult,
				card = card,
			}
		end
	end,
})
