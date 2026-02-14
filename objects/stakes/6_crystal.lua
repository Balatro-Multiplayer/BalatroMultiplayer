if MP.EXPERIMENTAL.alt_stakes then
	SMODS.Stake({
		mp_alt_stake = true,
		name = "Crystal Stake",
		key = "crystal",
		unlocked = true,
		applied_stakes = { "jade" },
		above_stake = "jade",
		atlas = "alt_mp_stakes",
		pos = { x = 1, y = 1 },
		sticker_pos = { x = 3, y = 1 },
		modifiers = function()
			G.GAME.modifiers.mp_enable_unreliable_jokers = true
		end,
		colour = HEX("BCF9FF"),
		shiny = true,
	})
end
