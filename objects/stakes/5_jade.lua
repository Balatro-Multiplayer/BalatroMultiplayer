if MP.EXPERIMENTAL.alt_stakes then
	SMODS.Stake({
		mp_alt_stake = true,
		name = "Jade Stake",
		key = "jade",
		unlocked = true,
		applied_stakes = { "pyrite" },
		above_stake = "pyrite",
		atlas = "alt_mp_stakes",
		pos = { x = 0, y = 1 },
		sticker_pos = { x = 3, y = 1 },
		modifiers = function()
			G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1
		end,
		colour = HEX("3EA93C"),
		-- shiny = true,
	})
end
