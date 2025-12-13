-- Hold Your Breath - Extra Credit Joker ported to Sandbox
-- Gains +30 Chips each hand played, resets on discard, destroyed after +180 Chips

SMODS.Joker({
	key = "holdyourbreath_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = false,
	rarity = 1,
	cost = 4,
	atlas = "ec_jokers_sandbox",
	pos = { x = 8, y = 1 },
	config = { extra = { chips = 0, chip_mod = 30, chip_limit = 180 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod, card.ability.extra.chip_limit } }
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main and card.ability.extra.chips > 0 then
			return {
				message = localize({ type = "variable", key = "a_chips", vars = { card.ability.extra.chips } }),
				chip_mod = card.ability.extra.chips,
			}
		elseif context.before and not context.blueprint then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.CHIPS,
			}
		elseif context.after and not context.blueprint and card.ability.extra.chips > card.ability.extra.chip_limit then
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
				message = localize("k_extinct_ex"),
				colour = G.C.CHIPS,
			}
		elseif context.discard and not context.blueprint and card.ability.extra.chips > 0 then
			card.ability.extra.chips = 0
			return {
				message = localize("k_reset"),
				colour = G.C.RED,
			}
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
