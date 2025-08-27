SMODS.Atlas({
	key = "castle_sandbox",
	path = "j_castle_sandbox.png",
	px = 71,
	py = 95,
})
SMODS.Joker({
	key = "castle_sandbox",
	atlas = "castle_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 2,
	cost = 6,
	config = { extra = { chips = 50, chip_mod = 10 } },
	loc_vars = function(self, info_queue, card)
		local suit = (G.GAME.current_round.castle_card or {}).suit or "Spades"
		return {
			vars = {
				localize(suit, "suits_singular"),
				card.ability.extra.chips,
				colours = { G.C.SUITS[suit] },
			},
		}
	end,
	calculate = function(self, card, context)
		if
			context.discard
			and not context.blueprint
			and not context.other_card.debuff
			and context.other_card:is_suit(G.GAME.current_round.castle_card.suit)
		then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.CHIPS,
			}
		end
		if context.joker_main then return {
			chips = card.ability.extra.chips,
		} end
	end,

	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
