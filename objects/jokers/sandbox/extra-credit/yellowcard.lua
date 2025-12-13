-- Yellow Card - Extra Credit Joker ported to Sandbox
-- Gain $5 when any Booster Pack is skipped

SMODS.Joker({
	key = "yellowcard_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	rarity = 1,
	cost = 6,
	atlas = "ec_jokers_sandbox",
	pos = { x = 0, y = 1 },
	config = { extra = { money = 5 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.money } }
	end,

	calculate = function(self, card, context)
		if context.skipping_booster and not context.open_booster then
			card_eval_status_text(context.blueprint_card or card, "extra", nil, nil, nil, { message = "$" .. tostring(card.ability.extra.money), colour = G.C.MONEY })
			ease_dollars(card.ability.extra.money)
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
