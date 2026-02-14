if MP.EXPERIMENTAL.alt_stakes then
	SMODS.Stake({
		mp_alt_stake = true,
		name = "Ferrite Stake",
		key = "ferrite",
		unlocked = true,
		applied_stakes = { "pebble" },
		above_stake = "pebble",
		atlas = "alt_mp_stakes",
		pos = { x = 3, y = 0 },
		sticker_pos = { x = 3, y = 1 },
		modifiers = function()
			G.GAME.modifiers.mp_enable_persistent_jokers = true
		end,
		colour = HEX("B2B2B2"),
		-- shiny = true,
	})
end
