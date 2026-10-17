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
	mutator = {
		category = "HAZARDS",
		order = 1,
		label = "No Easy Money",
		desc = { "Gold and Lucky Cards", "cannot appear." },
		credits = { idea = { "Kars" } },
	},
})

-- Rarity isn't known until every mod's jokers are registered, so the ban list is
-- built at run start instead of as a static array.
MP.Layer("no_uncommons", {
	on_apply_bans = function()
		for key, center in pairs(G.P_CENTERS) do
			if center.set == "Joker" and center.rarity == 2 then G.GAME.banned_keys[key] = true end
		end
	end,
	mutator = {
		category = "HAZARDS",
		order = 2,
		label = "No Uncommons",
		desc = { "Uncommon Jokers cannot appear." },
	},
})
