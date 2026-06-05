-- Economy mutator layers (the "big bag" — green knobs).
--
-- Pure data. Each declares `game_modifiers` (copied onto G.GAME.modifiers at run
-- start by the generic applier) and/or `banned_*` arrays (merged via
-- current_ruleset). No runtime code lives here — these are all engine-native
-- modifier fields Balatro already reads, so they're deterministic across both
-- clients (set once at run start).
--
-- Contract with the applier: a layer's `game_modifiers = { <id> = value }` is
-- written to G.GAME.modifiers[<id>]; `starting_params = { <id> = value }` to
-- G.GAME.starting_params[<id>] (with round_resets propagation handled there).

-- Shop prices climb +$1 per purchase, compounding across the run.
-- (card.lua: `if G.GAME.modifiers.inflation then G.GAME.inflation = ... + 1`)
MP.Layer("inflation", {
	game_modifiers = { inflation = true },
})

-- No interest paid on held money. Pure economic pressure.
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
MP.Layer("spartan", {
	game_modifiers = { no_blind_reward = { Small = true, Big = true } },
})

-- Booster packs cost +$1 more for each ante you're into the run.
-- (card.lua set_cost: cost + round_resets.ante - 1 when booster_ante_scaling)
MP.Layer("pricey_packs", {
	game_modifiers = { booster_ante_scaling = true },
})
