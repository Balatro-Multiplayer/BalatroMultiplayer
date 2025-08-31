SMODS.Back({
	key = "oracle",
	config = { vouchers = { "v_clearance_sale" }, consumables = { "c_medium" } },
	atlas = "mp_decks",
	pos = { x = 1, y = 1 },
	apply = function(self)
		G.GAME.modifiers.oracle_max = 50
	end,
})
