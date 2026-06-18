-- Balance knobs (provisional — tune freely).
-- TODO XMult works, but hand size change doesn't work
local GLASS_CANNON_HANDS = 2 -- doesn't work
local GLASS_CANNON_XMULT = 4

MP.Layer("glass_cannon", {
	starting_params = { hands = GLASS_CANNON_HANDS }, -- doesn't work
})

-- final_scoring_step is the canonical once-per-hand seam: vanilla calls it after
-- all jokers to let the deck rebalance chips/mult (it's where Plasma halves and
-- recombines). We wrap it, let the real deck run, then scale mult on top when the
-- layer is live. nu_mult can come back nil (most decks), in which case the engine
-- falls back to the incoming mult — so we base our scale on (nu_mult or args.mult).
local _back_trigger_effect = Back.trigger_effect
function Back:trigger_effect(args)
	local nu_chip, nu_mult = _back_trigger_effect(self, args)
	if args and args.context == "final_scoring_step" and MP.is_layer_active("glass_cannon") then
		local base_mult = nu_mult or args.mult
		return nu_chip, base_mult * GLASS_CANNON_XMULT
	end
	return nu_chip, nu_mult
end
