MP.ReworkCenter("Gold", {
	rulesets = MP.UTILS.get_standard_rulesets(),
	config = { extra = { p_dollars = 4 } },
	loc_key = "mp_gold_seal",
	loc_vars = function(self, info_queue, card)
		return { vars = { self.config.extra.p_dollars } }
	end,
	get_p_dollars = function(self, card)
		return card.ability.seal.extra.p_dollars
	end,
})
