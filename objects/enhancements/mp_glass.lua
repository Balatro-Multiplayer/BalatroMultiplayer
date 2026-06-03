-- Canonical multi-layer Path-B rework. Same three declarative lines as before;
-- the mechanism underneath now derives effective config purely from the active
-- context (frozen baseline ⊕ active layers), so standard/classic resolve to
-- Xmult 1.5 / extra 4 and sandbox to Xmult 1.5 / extra 3 no matter what the
-- player browsed first.
MP.ReworkCenter("m_glass", {
	layers = { "standard", "classic" },
	config = { Xmult = 1.5, extra = 4 },
})

MP.ReworkCenter("m_glass", {
	layers = "sandbox",
	config = { Xmult = 1.5, extra = 3 },
})
