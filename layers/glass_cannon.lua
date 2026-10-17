local GLASS_CANNON_HANDS = -2 -- relative, so Black Deck's -1 still lands (4 -> 2, 3 -> 1)
local GLASS_CANNON_XMULT = 4

MP.Layer("glass_cannon", {
	round_deltas = { hands = GLASS_CANNON_HANDS },
	flag = "mp_glass_cannon",
	mutator = {
		category = "CHAOS",
		order = 1,
		label = "Glass Cannon",
		clock = { at = "ante", lasts = "ante", severity = 2 },
		desc = { "X4 Mult.", "-2 hands each round,", "down to a minimum of 1." },
	},
})

-- final_scoring_step called after jokers to let the deck rebalance chips/mult
-- (it's where Plasma does its math)
-- so we wrap that burrito and then scale the mult on top
local _back_trigger_effect = Back.trigger_effect
function Back:trigger_effect(args)
	-- magic. don't ask
	local nu_chip, nu_mult = _back_trigger_effect(self, args)
	if args and args.context == "final_scoring_step" and G.GAME.modifiers.mp_glass_cannon then
		local base_mult = nu_mult or args.mult
		return nu_chip, base_mult * GLASS_CANNON_XMULT
	end
	return nu_chip, nu_mult
end
