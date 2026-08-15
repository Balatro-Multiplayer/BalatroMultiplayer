-- Ban mutator layers (green knobs — pure ban deltas).
--
-- These are just `banned_*` arrays. When a layer is active (baked into a ruleset
-- or picked as a runtime modifier), current_ruleset() unions its ban arrays into
-- ApplyBans, so no extra wiring is needed.

-- "Gambling Opportunity" (Handsome-Devils): no easy money. Bans the
-- money-generating enhancements. (Gold-seal / money-edition bans need a card-set
-- hook, so they're out of the pure-data version — enhancements cover the bulk.)
MP.Layer("gambling_opportunity", {
	banned_enhancements = {
		"m_gold",
		"m_lucky",
	},
})


MP.Layer("no_uncommons", {
    banned_jokers = {},
})
