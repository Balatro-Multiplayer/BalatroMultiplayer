-- Reworked Wraith: random Uncommon joker + $5 (vanilla = random Rare, money to $0).
SMODS.Consumable({
	key = "wraith",
	set = "Spectral",
	pos = { x = 5, y = 4 },
	cost = 4,
	unlocked = true,
	discovered = true,
	config = { extra = { dollars = 5 }, mp_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.dollars } }
	end,
	use = function(self, card, area, copier)
		local used_tarot = copier or card
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				play_sound("timpani")
				SMODS.add_card({ set = "Joker", rarity = "Uncommon", key_append = "mp_wra" })
				used_tarot:juice_up(0.3, 0.5)
				ease_dollars(card.ability.extra.dollars, true)
				return true
			end,
		}))
		delay(0.6)
	end,
	can_use = function(self, card)
		return #G.jokers.cards < G.jokers.config.card_limit or card.area == G.jokers
	end,
})
