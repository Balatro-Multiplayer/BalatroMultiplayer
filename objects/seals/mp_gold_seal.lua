MP.ReworkCenter("Gold", {
	rulesets = MP.UTILS.get_standard_rulesets(),
	config = { extra = { money = 4 } },
	get_p_dollars = function(self, card)
		return card.ability.seal.extra.money
	end,
})
