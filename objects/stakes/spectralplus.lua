SMODS.Stake({
	name = "Spectral+ Stake",
	unlocked = true,
	key = "spectralplus",
	applied_stakes = { "spectral" },
	pos = { x = 4, y = 1 },
	sticker_pos = { x = 3, y = 1 },
	modifiers = function()
		G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1
	end,
	colour = HEX("000000"),
	shiny = true,
})
