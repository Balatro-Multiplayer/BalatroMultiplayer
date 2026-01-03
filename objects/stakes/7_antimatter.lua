if MP.EXPERIMENTAL.alt_stakes then
	SMODS.Stake({
		mp_alt_stake = true,
		name = "Antimatter Stake",
		key = "antimatter",
		unlocked = true,
		applied_stakes = { "crystal" },
		above_stake = "crystal",
		atlas = "alt_mp_stakes",
		pos = { x = 2, y = 1 },
		sticker_pos = { x = 3, y = 1 },
		modifiers = function()
			G.GAME.modifiers.mp_enable_draining_jokers = true
		end,
		colour = HEX("4F6367"),
		shiny = true,
	})
end
