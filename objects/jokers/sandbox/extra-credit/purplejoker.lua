-- Purple Joker - Extra Credit Joker ported to Sandbox
-- Gains +Mult = hands_left + discards_left per round

SMODS.Joker({
	key = "purplejoker_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = false,
	rarity = 1,
	cost = 4,
	atlas = "ec_jokers_sandbox",
	pos = { x = 7, y = 0 },
	config = { extra = { mulchs = 0 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mulchs } }
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.end_of_round and not context.blueprint then
			local gain = G.GAME.current_round.hands_left + G.GAME.current_round.discards_left
			card.ability.extra.mulchs = card.ability.extra.mulchs + gain
			return {
				message = localize({ type = "variable", key = "a_mult", vars = { gain } }),
				colour = G.C.MULT,
			}
		end

		if context.cardarea == G.jokers and context.joker_main then
			if card.ability.extra.mulchs > 0 then
				return {
					message = localize({ type = "variable", key = "a_mult", vars = { card.ability.extra.mulchs } }),
					mult_mod = card.ability.extra.mulchs,
					colour = G.C.MULT,
				}
			end
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
