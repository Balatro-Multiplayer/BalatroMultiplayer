MP.ReworkCenter("m_glass", {
	rulesets = MP.UTILS.get_standard_rulesets(),
	config = { Xmult = 1.5, extra = 4 },
})

MP.ReworkCenter("m_glass", {
	rulesets = "sandbox",
	config = { Xmult = 1.5, extra = 3 },
})

MP.ReworkCenter("m_glass", {
	rulesets = "legacy_ranked",
	config = { Xmult = 1.5, extra = 4 },
})

-- This is a glass that is permanently at X1.5 to be shown in ruleset descriptions
-- (Because glass will show at X2 in rulesets otherwise)
SMODS.Enhancement({
	key = "display_glass",
	config = { extra = { Xmult = 1.5, extra = 4 }, mp_sticker_balanced = true },
	pos = { x = 5, y = 1 },
	no_collection = true,
	shatters = true,
	loc_vars = function(self, info_queue, card)
		local num, denom = SMODS.get_probability_vars(card, 1, card.ability.extra.extra, "glass")
		return {
			vars = {
				card.ability.extra.Xmult,
				num,
				denom,
			},
		}
	end,
	in_pool = function(self, args)
		return false
	end,
})

SMODS.Enhancement({
	key = "sandbox_display_glass",
	config = { extra = { Xmult = 1.5, extra = 3 }, mp_sticker_balanced = true },
	pos = { x = 5, y = 1 },
	no_collection = true,
	shatters = true,
	loc_vars = function(self, info_queue, card)
		local num, denom = SMODS.get_probability_vars(card, 1, card.ability.extra.extra, "glass")
		return {
			vars = {
				card.ability.extra.Xmult,
				num,
				denom,
			},
		}
	end,
	in_pool = function(self, args)
		return false
	end,
})
