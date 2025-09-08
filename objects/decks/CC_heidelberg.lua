SMODS.Atlas({
	key = "b_heidelberg",
	path = "b_heidelberg.png",
	px = 71,
	py = 95,
})

SMODS.Back({
	key = "heidelberg",
	config = {},
	atlas = "b_heidelberg",
	mp_credits = { art = { "aura!" }, code = { "steph" } },
	-- apply = function(self)
	-- 	SMODS.change_voucher_limit(1)
	-- 	G.GAME.modifiers.mp_violet = true -- i forgot how you get the deck, whatever
	-- end,
	-- loc_vars = function(self, info_queue, card)
	-- info_queue[#info_queue + 1] = { key = "e_negative_consumable", set = "Edition", config = { extra = 1 } }
	-- end,
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

-- TODO: Perkeo effect on calculate on this deck
-- this is legendary deck
