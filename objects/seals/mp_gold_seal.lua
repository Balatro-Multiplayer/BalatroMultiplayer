MP.ReworkCenter("Gold", {
	center_table = "P_SEALS",
	layers = "standard",
	config = { extra = { p_dollars = 4 } },
	get_p_dollars = function(self, card)
		return card.ability.seal.extra.p_dollars
	end,
})
