MP.Layer("bigger_shop", {
	on_apply_bans = function()
		change_shop_size(1)
	end,
	mutator = {
		category = "ECONOMY",
		order = 6,
		label = "Bigger Shop",
		desc = { "+1 card slot in the shop." },
		credits = { code = { "steph" } },
	},
})
