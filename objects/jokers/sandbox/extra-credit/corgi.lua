-- Toby the Corgi - Extra Credit Joker ported to Sandbox
-- Destroys random consumable when Blind selected, gains +4 Mult

SMODS.Joker({
	key = "corgi_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = false,
	rarity = 1,
	cost = 4,
	atlas = "ec_jokers_sandbox",
	pos = { x = 0, y = 2 },
	config = { extra = { mult = 0, mult_mod = 4 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod } }
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and card.ability.extra.mult > 1 then
			return {
				message = localize({ type = "variable", key = "a_mult", vars = { card.ability.extra.mult } }),
				mult_mod = card.ability.extra.mult,
			}
		elseif context.setting_blind and not card.getting_sliced and not context.blueprint and G.consumeables.cards[1] then
			local snack = pseudorandom_element(G.consumeables.cards, pseudoseed("toby"))
			if snack ~= nil then
				card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
				G.E_MANAGER:add_event(Event({
					func = function()
						play_sound("tarot1")
						snack.T.r = -0.2
						snack:juice_up(0.3, 0.4)
						snack.states.drag.is = true
						snack.children.center.pinch.x = true
						snack:start_dissolve()
						snack = nil
						delay(0.3)
						return true
					end,
				}))
				card_eval_status_text(card, "extra", nil, nil, nil, { message = localize({ type = "variable", key = "a_mult", vars = { card.ability.extra.mult } }), colour = G.C.MULT })
			end
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
