-- Using this, we can rework everything in G.P_CENTERS, so let's rework glass too
MP.ReworkCenter({
	key = "m_glass",
	ruleset = MP.UTILS.get_standard_rulesets(),
	config = { Xmult = 1.5, extra = 4 }, -- Couldn't be simpler
})