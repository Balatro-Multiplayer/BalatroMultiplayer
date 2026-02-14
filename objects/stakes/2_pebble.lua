if MP.EXPERIMENTAL.alt_stakes then
	SMODS.Stake({
		mp_alt_stake = true,
		name = "Pebble Stake",
		key = "pebble",
		unlocked = true,
		applied_stakes = { "plastic" },
		above_stake = "plastic",
		atlas = "alt_mp_stakes",
		pos = { x = 2, y = 0 },
		sticker_pos = { x = 3, y = 1 },
		modifiers = function()
			G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1
		end,
		colour = HEX("949494"),
		-- shiny = true,
	})
end
