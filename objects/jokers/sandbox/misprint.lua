SMODS.Atlas({
	key = "misprint_sandbox",
	path = "j_misprint_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "misprint_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	atlas = "misprint_sandbox",
	blueprint_compat = true,
	rarity = 1,
	cost = 4,
	ruleset = "sandbox",
	config = { extra = { max = 46, min = -23, mult = "???", color = G.C.MULT }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult, colours = { card.ability.extra.color } } }
	end,
	add_to_deck = function(self, card, from_debuff)
		local numerator, denominator = SMODS.get_probability_vars(card, 1, 2, "j_mp_misprint_sandbox")
		card.ability.extra.mult = numerator
			* pseudorandom("misprint_sandbox", card.ability.extra.min, card.ability.extra.max)
		if numerator > 1 then card.ability.extra.color = G.C.GREEN end
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
