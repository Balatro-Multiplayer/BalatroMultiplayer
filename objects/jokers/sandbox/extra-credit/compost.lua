-- Compost - Extra Credit Joker ported to Sandbox
-- +2 Mult per 3 discards, self-destructs at +30 Mult

SMODS.Joker({
	key = "compost_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = false,
	rarity = 1,
	cost = 5,
	atlas = "ec_jokers_sandbox",
	pos = { x = 8, y = 0 },
	config = { extra = { mult = 0, mod = 2, fill = 0, do_once = true }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult, card.ability.extra.mod } }
	end,

	calculate = function(self, card, context)
		if context.discard and not context.blueprint then
			card.ability.extra.fill = card.ability.extra.fill + 1
			if card.ability.extra.fill >= 3 then
				card.ability.extra.fill = 0
				card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mod

				if card.ability.extra.mult >= 30 then
					G.E_MANAGER:add_event(Event({
						func = function()
							play_sound("tarot1")
							card.T.r = -0.2
							card:juice_up(0.3, 0.4)
							card.states.drag.is = true
							card.children.center.pinch.x = true
							G.E_MANAGER:add_event(Event({
								trigger = "after",
								delay = 0.3,
								blockable = false,
								func = function()
									G.jokers:remove_card(card)
									card:remove()
									card = nil
									return true
								end,
							}))
							return true
						end,
					}))
					return {
						message = localize("k_eaten_ex"),
						colour = G.C.MULT,
					}
				else
					return {
						message = localize({ type = "variable", key = "a_mult", vars = { card.ability.extra.mod } }),
						colour = G.C.MULT,
					}
				end
			end
		end

		if context.cardarea == G.jokers and context.joker_main then
			if card.ability.extra.mult > 0 then
				return {
					message = localize({ type = "variable", key = "a_mult", vars = { card.ability.extra.mult } }),
					mult_mod = card.ability.extra.mult,
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
