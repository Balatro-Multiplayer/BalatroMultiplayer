-- Vanilla challenge modifiers, wired through MP.ApplyGameModifiers.

-- flipped_cards is a 1-in-N face-down chance in vanilla; 1 = every card.
MP.Layer("flipped_cards", {
	game_modifiers = { flipped_cards = 1 },
	mutator = {
		category = "MAYHEM",
		order = 1,
		label = "Blind Poker",
		clock = { at = "blind", lasts = "blind", severity = 2 },
		desc = { "All cards are drawn face down." },
	},
})

MP.Layer("debuff_played_cards", {
	game_modifiers = { debuff_played_cards = true },
	mutator = {
		category = "MAYHEM",
		order = 2,
		label = "Dead Cards",
		clock = { at = "ante", lasts = "ante", severity = 3 },
		desc = { "After scoring, cards become", "debuffed for the rest of the run." },
		clock_note = { "Cards already debuffed", "stay debuffed." },
	},
})

MP.Layer("all_eternal", {
	game_modifiers = { all_eternal = true },
	mutator = {
		category = "MAYHEM",
		order = 3,
		label = "No Takebacks",
		clock = { at = "ante", lasts = "ante", severity = 3 },
		desc = { "All newly created Jokers", "are Eternal." },
		clock_note = { "Jokers already made Eternal", "stay Eternal." },
	},
})

MP.Layer("chip_cap", {
	game_modifiers = { chips_dollar_cap = true },
	mutator = {
		category = "HAZARDS",
		order = 4,
		label = "Cash Ceiling",
		clock = { at = "blind", lasts = "blind", severity = 2 },
		desc = { "Before multiplying, Chips", "cannot exceed your money." },
	},
})

MP.Layer("shrinking_hand", {
	game_modifiers = { minus_hand_size_per_X_dollar = 10 },
	mutator = {
		category = "MAYHEM",
		order = 4,
		label = "Heavy Pockets",
		clock = { at = "ante", lasts = "ante", severity = 2 },
		desc = { "-1 hand size for every", "$10 you have." },
	},
})

-- Vanilla shrinks the hand as money grows (cardarea.lua, last_poll_size) but
-- never gives it back when the modifier goes away. When Heavy Pockets is
-- switched off mid-run, return what it took.
local cardarea_update_ref = CardArea.update
function CardArea:update(dt)
	if
		self == G.hand
		and not G.GAME.modifiers.minus_hand_size_per_X_dollar
		and (self.config.last_poll_size or 0) ~= 0
	then
		self:change_size(self.config.last_poll_size)
		self.config.last_poll_size = 0
	end
	return cardarea_update_ref(self, dt)
end
