SMODS.Atlas({
	key = "ouija_2",
	path = "c_ouija_2.png",
	px = 71,
	py = 95,
})

SMODS.Consumable({
	key = "ouija_standard",
	set = "Spectral",
	atlas = "ouija_2",
	cost = 4,
	pos = { x = 0, y = 0 },
	unlocked = true,
	discovered = true,
	config = { extra = { destroy = 3 }, mp_sticker_balanced = true },
	in_pool = function(self)
		return MP.is_layer_active("sandbox") or MP.is_layer_active("standard")
	end,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.destroy } }
	end,
	use = function(self, card, area, copier)
		local used_tarot = copier or card
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("tarot1")
				used_tarot:juice_up(0.3, 0.5)
				return true
			end,
		}))

		local cards_to_destroy = {}
		local temp_hand = {}
		for k, v in ipairs(G.hand.cards) do
			temp_hand[#temp_hand + 1] = v
		end
		table.sort(temp_hand, function(a, b)
			return not a.playing_card or not b.playing_card or a.playing_card < b.playing_card
		end)
		pseudoshuffle(temp_hand, pseudoseed("ouija_destroy"))

		for i = 1, card.ability.extra.destroy do
			cards_to_destroy[#cards_to_destroy + 1] = temp_hand[i]
			temp_hand[i].ouija_queue_destroy = true
		end
		for i = 1, #G.hand.cards do
			local _card = G.hand.cards[i]
			local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				delay = 0.15,
				func = function()
					_card:flip()
					play_sound("card1", percent)
					_card:juice_up(0.3, 0.3)
					return true
				end,
			}))
		end
		delay(0.2)
		SMODS.destroy_cards(cards_to_destroy)
		delay(0.3)
		local _rank = pseudorandom_element(SMODS.Ranks, "ouija")
		for i = 1, #G.hand.cards do
			local _card = G.hand.cards[i]
			if not _card.ouija_queue_destroy then
				G.E_MANAGER:add_event(Event({
					func = function()
						if _card and not _card.destroyed then assert(SMODS.change_base(_card, nil, _rank.key)) end
						return true
					end,
				}))
			end
		end
		for i = 1, #G.hand.cards do
			local _card = G.hand.cards[i]
			if not _card.ouija_queue_destroy then
				local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
				G.E_MANAGER:add_event(Event({
					trigger = "after",
					delay = 0.15,
					func = function()
						_card:flip()
						play_sound("tarot2", percent, 0.6)
						_card:juice_up(0.3, 0.3)
						return true
					end,
				}))
			end
		end
		delay(0.5)
	end,
	can_use = function(self, card)
		return G.hand and #G.hand.cards >= card.ability.extra.destroy
	end,
	mp_credits = {
		art = { "aura!" },
		code = { "steph" },
	},
})
