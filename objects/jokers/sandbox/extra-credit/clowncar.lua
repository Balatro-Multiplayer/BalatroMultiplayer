SMODS.Joker({
	key = "clowncar_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,

	rarity = 3,
	cost = 7,
	atlas = "ec_jokers_sandbox",
	pos = { x = 6, y = 2 },

	config = {
		extra = {
			mult = 44,
			money = 3,
		},
		mp_sticker_balanced = true,
		mp_sticker_extra_credit = true,
	},

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult, card.ability.extra.money } }
	end,

	calculate = function(self, card, context)
		if context.before_but_not_as_much then
			ease_dollars(-card.ability.extra.money)
			card_eval_status_text(
				card,
				"jokers",
				nil,
				percent,
				nil,
				{ message = "-$" .. tostring(card.ability.extra.money), colour = G.C.MONEY }
			)
			--Manually give +44 Mult
			-- todo port to proper smods style
			mult = mod_mult(mult + card.ability.extra.mult)
			update_hand_text({ delay = 0 }, { mult = mult })
			card_eval_status_text(card, "jokers", nil, percent, nil, {
				message = localize({ type = "variable", key = "a_mult", vars = { card.ability.extra.mult } }),
				mult_mod = card.ability.extra.mult,
			})
		end
	end,

	mp_credits = {
		code = { "CampfireCollective" },
		art = { "R3venantR3mnant" },
	},
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
