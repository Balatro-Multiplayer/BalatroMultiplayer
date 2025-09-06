SMODS.Stake({
	name = "Spectral Stake",
	unlocked = true,
	key = "spectral",
	applied_stakes = { "planet" },
	pos = { x = 3, y = 1 },
	sticker_pos = { x = 3, y = 1 },
	modifiers = function()
		G.GAME.modifiers.enable_rentals_in_shop = true -- gold
		G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1 -- yeehaw
	end,
	colour = HEX("000000"),
	shiny = true,
})
