-- Effect lives in layers/eeeee.lua; activated here via rules.custom -> mp_eeeee.
SMODS.Challenge({
	key = "mp_eeeee",
	rules = {
		custom = {
			{ id = "mp_eeeee" },
		},
	},
	unlocked = function(self)
		return true
	end,
})
