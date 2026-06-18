-- Shop prices climb +$1 per purchase, compounding across the run.
-- (card.lua: `if G.GAME.modifiers.inflation then G.GAME.inflation = ... + 1`)
-- TODO doesn't work
MP.Layer("inflation", {
	game_modifiers = { inflation = true },
})

-- No interest paid on held money
MP.Layer("no_interest", {
	game_modifiers = { no_interest = true },
})

-- Every discard costs $1. (state_events.lua: ease_dollars(-discard_cost) per discard)
MP.Layer("discard_tax", {
	game_modifiers = { discard_cost = 1 },
})

-- Leftover discards pay out at end of round, like unused hands do. A positive
-- knob to pair against the punishing ones. (default money_per_discard is 0)
MP.Layer("frugal", {
	game_modifiers = { money_per_discard = 1 },
})

-- No cash reward from Small or Big blinds (Boss/PvP payout left intact).
-- (blind.lua: dollars zeroed when no_blind_reward[blind_type] is set)
-- TODO doesn't work
MP.Layer("spartan", {
	game_modifiers = { no_blind_reward = { Small = true, Big = true } },
})

-- Booster packs cost +$1 more for each ante you're into the run.
-- (card.lua set_cost: cost + round_resets.ante - 1 when booster_ante_scaling)
-- TODO doesn't work
MP.Layer("pricey_packs", {
	game_modifiers = { booster_ante_scaling = true },
})
