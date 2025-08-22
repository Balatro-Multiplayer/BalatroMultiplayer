SMODS.Back({
	key = "violet",
	config = {},
	atlas = "mp_decks",
	pos = { x = 0, y = 0 },
	apply = function(self)
		SMODS.change_voucher_limit(1)
		G.GAME.modifiers.mp_violet = true -- i forgot how you get the deck, whatever
	end,
})

local set_cost_ref = Card.set_cost
function Card:set_cost()
	set_cost_ref(self)
	if G.GAME.modifiers.mp_violet and self.config.center.set == "Voucher" then
		if G.GAME.round_resets.ante == 1 then
			self.cost = math.max(
				1,
				math.floor(0.5 * (self.base_cost + self.extra_cost + 0.5) * (100 - G.GAME.discount_percent) / 100)
			)
		end
	end
end
