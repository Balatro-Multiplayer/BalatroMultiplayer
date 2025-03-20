-- Some functions below are marked as "Adapted from Pokermon"
-- Marked functions are licensed under GPL3 license and come from the Pokermon project
-- uifunctions original source: https://github.com/InertSteak/Pokermon/blob/main/functions/uifunctions.lua on 2025-03-19

-- Adapted from Pokermon (uifunctions)
MP.create_misprint_cardarea = function()
	local config = { card_limit = 0, type = "misprint" }
	config.major = G.deck
	local misprint_view = CardArea(0, 0, G.CARD_W, 0.5 * G.CARD_H, config)
	misprint_view.T.x = G.TILE_W - G.deck.T.w / 2 - misprint_view.T.w / 2 - 0.4
	misprint_view.T.y = G.TILE_H - G.deck.T.h - misprint_view.T.h
	misprint_view:hard_set_VT()

	G.GAME.misprint_amount = 1
	return misprint_view
end

-- Adapted from Pokermon (uifunctions)
MP.cards_dont_match = function(card1, card2)
	if type(card1) ~= type(card2) then
		return true
	end
	if card1.config.card_key ~= card2.config.card_key then
		return true
	end
	if card1.base.name ~= card2.base.name then
		return true
	end
	if card1.base.suit ~= card2.base.suit then
		return true
	end
	if card1.base.value ~= card2.base.value then
		return true
	end
	return false
end

-- Adapted from Pokermon (uifunctions)
MP.update_misprint_cardarea = function(misprint_view)
	if not misprint_view.states.visible then
		local to_kill = #misprint_view.cards
		for i = 1, to_kill do
			misprint_view.cards[i] = nil
		end
		misprint_view.states.visible = true
	end
	if misprint_view.children.area_uibox then
		misprint_view.children.area_uibox.states.visible = false
	end
	if misprint_view.adjusting_cards then
		return
	end
	misprint_view.adjusting_cards = true

	local deck = {}
	for i = 1, G.GAME.misprint_amount do
		if #G.deck.cards + 1 <= i then
			break
		end
		deck[i] = G.deck.cards[#G.deck.cards + 1 - i]
	end
	-- blank card that will cause the removal of any extra cards
	deck[G.GAME.misprint_amount + 1] = true

	local i = 1
	for k, card in pairs(deck) do
		while i <= #misprint_view.cards and MP.cards_dont_match(card, misprint_view.cards[i]) do
			misprint_view.cards[i]:start_dissolve({ G.C.PURPLE })
			i = i + 1
		end
		if k <= G.GAME.misprint_amount and MP.cards_dont_match(card, misprint_view.cards[i]) then
			local temp_card = copy_card(card, nil, 0.7)
            temp_card:set_ability(G.P_CENTERS.c_base)
            temp_card.edition = nil
            temp_card.seal = nil
            temp_card.debuff = nil
            temp_card.pinned = nil
			temp_card.states.drag.can = false
			temp_card.states.hover.can = false
			misprint_view:emplace(temp_card)
			temp_card:start_materialize({ G.C.PURPLE })
		end
		i = i + 1
	end
	G.E_MANAGER:add_event(Event({
		func = function()
			misprint_view.adjusting_cards = false
			return true
		end,
	}))
end
