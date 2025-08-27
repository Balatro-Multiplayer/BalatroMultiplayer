SMODS.Joker({
	key = "chaos_sandbox",
	blueprint_compat = false,
	rarity = 1,
	cost = 4,
	pos = { x = 1, y = 0 },
	config = { extra = { rerolls = 9999 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.rerolls } }
	end,
	add_to_deck = function(self, card, from_debuff)
		SMODS.change_free_rerolls(card.ability.extra.rerolls)
	end,
	remove_from_deck = function(self, card, from_debuff)
		SMODS.change_free_rerolls(-card.ability.extra.rerolls)
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

