-- Effect lives in layers/score_instability.lua (via rules.custom -> mp_score_instability).
SMODS.Challenge({
	key = "balancing_act",
	rules = {
		custom = {
			{ id = "mp_score_instability" },
			{ id = "mp_score_instability_EXAMPLE" }, -- ?????????????????????
			{ id = "mp_score_instability_LOC1" },
			{ id = "mp_score_instability_LOC2" },
			{ id = "mp_ante_scaling", value = 0.25 }, -- this would be in modifiers table if it actually worked
		},
	},
	unlocked = function(self)
		return true
	end,
})
