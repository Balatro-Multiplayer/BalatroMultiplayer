-- Esoteric mutator layers (green knobs — the genuinely weird ones).
--
-- All engine-native G.GAME.modifiers flags, so they're pure data and
-- deterministic. See economy_mutators.lua for the applier contract.

-- Hand is dealt face-down. You play blind. (cardarea.lua / common_events.lua
-- read modifiers.flipped_cards when drawing.)
MP.Layer("flipped_cards", {
	game_modifiers = { flipped_cards = true },
})

-- Played cards contribute nothing — you win purely on jokers and mult.
-- (state_events.lua: modifiers.debuff_played_cards)
MP.Layer("debuff_played_cards", {
	game_modifiers = { debuff_played_cards = true },
})

-- Every joker is eternal: can't be sold or destroyed. Your build locks in.
-- (common_events.lua: modifiers.all_eternal)
MP.Layer("all_eternal", {
	game_modifiers = { all_eternal = true },
})

-- The shop sells jokers carrying eternal / perishable / rental stickers —
-- roguelike risk on every purchase. (common_events.lua: enable_*_in_shop)
MP.Layer("sticker_shop", {
	game_modifiers = {
		enable_eternals_in_shop = true,
		enable_perishables_in_shop = true,
		enable_rentals_in_shop = true,
	},
})

-- Scoring chips are capped at your current money. Hoarding cash literally raises
-- your ceiling. Brutal in PvP — opt-in only. (misc_functions.lua mod_chips:
-- _chips = min(_chips, max(dollars, 0)))
MP.Layer("chip_cap", {
	game_modifiers = { chips_dollar_cap = true },
})

-- Hand size shrinks by 1 for every $10 you hold. Rich = clumsy.
-- (cardarea.lua: minus_hand_size_per_X_dollar)
MP.Layer("shrinking_hand", {
	game_modifiers = { minus_hand_size_per_X_dollar = 10 },
})
