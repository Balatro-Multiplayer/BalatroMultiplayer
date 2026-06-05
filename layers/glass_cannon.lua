-- Glass Cannon (built, not stubbed).
--
-- Fragile but devastating: far fewer hands per round, but a flat global multiplier
-- on every hand's final score. Two halves:
--   1. data  — `starting_params.hands` (the applier sets this at run start)
--   2. hook  — a global xmult applied once per hand, gated on the layer
--
-- The mult lever is deterministic (no RNG, same hand -> same score) and rides the
-- existing score sync, so it's MP-safe.

-- Balance knobs (provisional — tune freely).
local GLASS_CANNON_HANDS = 2
local GLASS_CANNON_XMULT = 4

MP.Layer("glass_cannon", {
	starting_params = { hands = GLASS_CANNON_HANDS },
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
