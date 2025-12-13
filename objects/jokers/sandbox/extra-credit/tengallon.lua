-- Ten Gallon - Extra Credit Joker ported to Sandbox
-- X0.4 Mult for every $25 you have

SMODS.Joker({
	key = "tengallon_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	rarity = 3,
	cost = 8,
	atlas = "ec_jokers_sandbox",
	pos = { x = 2, y = 1 },
	config = { extra = { Xmult = 0.4, dollars = 25 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		local current_xmult = to_big(1) + to_big(card.ability.extra.Xmult) * math.floor((G.GAME.dollars + (G.GAME.dollar_buffer or to_big(0))) / to_big(card.ability.extra.dollars))
		return { vars = { card.ability.extra.Xmult, card.ability.extra.dollars, current_xmult } }
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main then
			local xmult = to_big(card.ability.extra.Xmult) * math.floor((G.GAME.dollars + (G.GAME.dollar_buffer or to_big(0))) / to_big(card.ability.extra.dollars))
			if xmult > to_big(0) then
				return {
					message = localize({ type = "variable", key = "a_xmult", vars = { to_big(1) + xmult } }),
					Xmult_mod = to_big(1) + xmult,
				}
			end
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
