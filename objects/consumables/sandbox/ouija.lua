-- Ouija
SMODS.Consumable({
	key = "ouija_sandbox",
	set = "Spectral",
	pos = { x = 7, y = 4 },
	config = { extra = { destroy = 3 }, mp_sticker_balanced = true },
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_sandbox"
	end,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.destroy } }
	end,
	use = function(self, card, area, copier)
		local used_tarot = copier or card
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.2,
			func = function()
				play_sound("tarot1")
				used_tarot:juice_up(0.3, 0.5)
				return true
			end,
		}))

		local cards_to_destroy = {}
		for i = 1, math.min(card.ability.extra.destroy, #G.hand.cards) do
			local remaining_cards = {}
			for j, hand_card in ipairs(G.hand.cards) do
				local already_marked = false
				for k, marked_card in ipairs(cards_to_destroy) do
					if marked_card == hand_card then
						already_marked = true
						break
					end
				end
				if not already_marked then table.insert(remaining_cards, hand_card) end
			end
			if #remaining_cards > 0 then
				local card_to_destroy = pseudorandom_element(remaining_cards, "ouija_destroy")
				table.insert(cards_to_destroy, card_to_destroy)
			end
		end

		-- Destroy the selected cards
		for i, destroy_card in ipairs(cards_to_destroy) do
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				delay = 0.1,
				func = function()
					destroy_card:start_dissolve()
					return true
				end,
			}))
		end

		-- Wait for destruction, then flip remaining cards
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 1,
			func = function()
				for i = 1, #G.hand.cards do
					local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
					G.E_MANAGER:add_event(Event({
						trigger = "after",
						delay = 0.15,
						func = function()
							if G.hand.cards[i] and not G.hand.cards[i].destroyed then
								G.hand.cards[i]:flip()
								play_sound("card1", percent)
								G.hand.cards[i]:juice_up(0.3, 0.3)
							end
							return true
						end,
					}))
				end
				return true
			end,
		}))

		-- Convert remaining cards to same rank
		local _rank = pseudorandom_element(SMODS.Ranks, "ouija")
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.8,
			func = function()
				for i = 1, #G.hand.cards do
					if G.hand.cards[i] and not G.hand.cards[i].destroyed then
						G.E_MANAGER:add_event(Event({
							func = function()
								local _card = G.hand.cards[i]
								if _card and not _card.destroyed then
									assert(SMODS.change_base(_card, nil, _rank.key))
								end
								return true
							end,
						}))
					end
				end
				return true
			end,
		}))

		-- Flip cards back
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 1.2,
			func = function()
				for i = 1, #G.hand.cards do
					if G.hand.cards[i] and not G.hand.cards[i].destroyed then
						local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
						G.E_MANAGER:add_event(Event({
							trigger = "after",
							delay = 0.15,
							func = function()
								if G.hand.cards[i] and not G.hand.cards[i].destroyed then
									G.hand.cards[i]:flip()
									play_sound("tarot2", percent, 0.6)
									G.hand.cards[i]:juice_up(0.3, 0.3)
								end
								return true
							end,
						}))
					end
				end
				return true
			end,
		}))
		delay(0.5)
	end,
	can_use = function(self, card)
		return G.hand and #G.hand.cards >= card.ability.extra.destroy
	end,
	-- draw = function(self, card, layer)
	-- 	-- This is for the Spectral shader. You don't need this with `set = "Spectral"`
	-- 	-- Also look into SMODS.DrawStep if you make multiple cards that need the same shader
	-- 	if (layer == "card" or layer == "both") and card.sprite_facing == "front" then
	-- 		card.children.center:draw_shader("booster", nil, card.ARGS.send_to_shader)
	-- 	end
	-- end,
})
