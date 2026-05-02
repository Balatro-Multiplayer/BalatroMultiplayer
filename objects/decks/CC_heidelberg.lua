SMODS.Atlas({
	key = "b_heidelberg",
	path = "b_heidelberg.png",
	px = 71,
	py = 95,
})

SMODS.Back({
	key = "heidelberg",
	atlas = "b_heidelberg",
	mp_credits = { art = { "aura!" }, code = { "steph" } },
	calculate = function(self, back, context)
		if context.ending_shop and G.consumeables.cards[1] then
			G.E_MANAGER:add_event(Event({
				func = function()
					local card_to_copy, _ = pseudorandom_element(G.consumeables.cards, "mp_heidelberg")
					local copied_card = copy_card(card_to_copy)
					copied_card:set_edition("e_negative", true)
					copied_card:add_to_deck()
					G.consumeables:emplace(copied_card)
					return true
				end,
			}))
			return { message = localize("k_duplicated_ex") }
		end
	end,
})
