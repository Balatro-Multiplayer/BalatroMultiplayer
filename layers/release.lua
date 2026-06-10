-- The 1.0.0-release rebalance layer. Still WIP (most of its center reworks live
-- commented in rulesets/release.lua), but the layer itself is defined so reworks
-- can target it by name. No live ruleset composes it yet, so enabling it here
-- changes nothing in shipped play.
MP.Layer("release", {
	multiplayer_content = false,
	-- Allan please add details
})
