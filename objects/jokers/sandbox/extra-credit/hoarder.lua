SMODS.Joker({
	key = "hoarder_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,

	rarity = 2,
	cost = 5,
	atlas = "ec_jokers_sandbox",
	pos = { x = 9, y = 3 },

	config = {
		extra = 1,
		mp_sticker_balanced = true,
		mp_sticker_extra_credit = true,
	},

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,

	calculate = function(self, card, context)
		if context.EC_ease_dollars and not context.blueprint then
			if context.EC_ease_dollars > to_big(0) then
				card.ability.extra_value = card.ability.extra_value + card.ability.extra
				card:set_cost()
				card_eval_status_text(card, "extra", nil, nil, nil, {
					message = localize("k_val_up"),
					colour = G.C.MONEY,
					card = card,
				})
			end
		end
	end,

	mp_credits = {
		code = { "CampfireCollective" },
		art = { "neatoqueen" },
	},
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
