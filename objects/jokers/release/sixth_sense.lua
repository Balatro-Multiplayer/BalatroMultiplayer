-- Sixth Sense, bumped Common→Rare for the release layer. The canonical
-- rarity-rework-via-ReworkCenter case: under the new mechanism the rarity pools
-- are rebuilt from scratch (stable-sorted) at run start, so two clients on the
-- same context land on byte-identical pool order — no incremental re-sort, no
-- preview residue. Mirrors rulesets/release.lua's commented entry, retargeted to
-- the (now-defined) release layer so it has a live context to resolve under.
MP.ReworkCenter("j_sixth_sense", {
	layers = "release",
	rarity = 3,
})
