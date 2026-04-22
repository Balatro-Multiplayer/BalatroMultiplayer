MP.ReworkCenter("m_gold", {
	layers = "standard",
	config = { h_dollars = 4, mp_balanced = true },
})

-- Display-only gold for ruleset descriptions
SMODS.Enhancement({
	key = "display_gold",
	config = { h_dollars = 4, mp_balanced = true },
	pos = { x = 6, y = 0 },
	no_collection = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.h_dollars } }
	end,
	in_pool = function(self, args)
		return false
	end,
})
