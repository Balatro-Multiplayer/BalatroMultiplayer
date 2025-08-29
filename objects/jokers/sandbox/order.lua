SMODS.Atlas({
	key = "order_sandbox",
	path = "j_order_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "order",
	unlocked = false,
	blueprint_compat = true,
	rarity = 3,
	cost = 8,
	atlas = "order_sandbox",
	config = { extra = { Xmult = 3, type = "Straight" }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult, localize(card.ability.extra.type, "poker_hands") } }
	end,
	calculate = function(self, card, context)
		if context.joker_main and next(context.poker_hands[card.ability.extra.type]) then
			return {
				xmult = card.ability.extra.Xmult,
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
