-- Vanilla challenge modifiers. MP.ApplyGameModifiers (layers/_mutators.lua)
-- copies `game_modifiers` into G.GAME.modifiers at run start; vanilla reads them.

-- Shop prices climb +$1 per purchase, compounding across the run.
-- (card.lua: `if G.GAME.modifiers.inflation then G.GAME.inflation = ... + 1`)

MP.Layer("inflation", {
	game_modifiers = { inflation = true },
	mutator = {
		category = "ECONOMY",
		order = 1,
		label = "Inflation",
		clock = { at = "ante", lasts = "ante", severity = 2 },
		desc = { "Each purchase increases", "shop prices by $1." },
		credits = { idea = { "Kars" } },
	},
})

-- No interest paid on held money
MP.Layer("no_interest", {
	game_modifiers = { no_interest = true },
	mutator = {
		category = "ECONOMY",
		order = 2,
		label = "No Interest",
		clock = { at = "ante", lasts = "ante", severity = 2 },
		desc = { "Earn no interest." },
	},
})

-- Every discard costs $1
MP.Layer("discard_tax", {
	game_modifiers = { discard_cost = 1 },
	mutator = {
		category = "ECONOMY",
		order = 3,
		label = "Discard Tax",
		clock = { at = "blind", lasts = "blind", severity = 1 },
		desc = { "Each discard costs $1." },
	},
})

-- Leftover discards pay out at end of round
MP.Layer("frugal", {
	game_modifiers = { money_per_discard = 1 },
	mutator = {
		category = "ECONOMY",
		order = 4,
		label = "Waste Not",
		clock = { at = "blind", lasts = "blind", severity = 1 },
		desc = { "Earn $1 for each unused discard", "at end of round." },
	},
})

-- No cash reward from Small or Big blinds (Boss/PvP payout left intact).
-- (blind.lua: dollars zeroed when no_blind_reward[blind_type] is set)
MP.Layer("spartan", {
	game_modifiers = { no_blind_reward = { Small = true, Big = true } },
	mutator = {
		category = "CHAOS",
		order = 3,
		label = "Spartan",
		clock = { at = "ante", lasts = "ante", severity = 1 },
		desc = { "Small and Big Blinds", "give no reward money." },
	},
})

-- Booster packs cost +$1 more for each ante you're into the run.
-- (card.lua set_cost: cost + round_resets.ante - 1 when booster_ante_scaling)
MP.Layer("pricey_packs", {
	game_modifiers = { booster_ante_scaling = true },
	mutator = {
		category = "CHAOS",
		order = 4,
		label = "Pricey Packs",
		clock = { at = "ante", lasts = "ante", severity = 1 },
		desc = { "Booster Packs cost $1 extra", "for each Ante after Ante 1." },
	},
})
