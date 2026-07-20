MPAPI.Layer("bigger_shop", {
	calculate = function(self, context)
		if context.apply_bans then
			change_shop_size(1)
		end
	end,
})
