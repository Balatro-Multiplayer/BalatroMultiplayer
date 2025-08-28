SMODS.Atlas({
	key = "misprint_sandbox",
	path = "j_misprint_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "misprint_sandbox",
	atlas = "misprint_sandbox",
	blueprint_compat = true,
	rarity = 1,
	cost = 4,
	ruleset = "sandbox",
	config = { extra = { max = 46, min = -5, mult = "???" }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult } }
	end,
	add_to_deck = function(self, card, from_debuff)
		card.ability.extra.mult = pseudorandom("misprint_sandbox", card.ability.extra.min, card.ability.extra.max) -- TODO replace with steamodded pseudorandom or not
	end,
	calculate = function(self, card, context)
		if context.joker_main then return {
			mult = card.ability.extra.mult,
		} end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
