SMODS.Atlas({
	key = "pizza",
	path = "j_pizza.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "pizza",
	atlas = "pizza",
	rarity = 1,
	cost = 4,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = false,
	perishable_compat = true,
	config = { extra = { discards = 2, discards_nemesis = 1 } },
	loc_vars = function(self, info_queue, card)
		MP.UTILS.add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.discards, card.ability.extra.discards_nemesis } }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	add_to_deck = function(self, card, from_debuffed)
		if not from_debuffed and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.send_phantom("j_mp_pizza")
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not from_debuff and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.remove_phantom("j_mp_pizza")
		end
	end,
	calculate = function(self, card, context)
		if context.mp_end_of_pvp and (not card.edition or card.edition.type ~= "mp_phantom") and not context.blueprint then
			-- do things
			MP.GAME.pizza_discards = MP.GAME.pizza_discards + card.ability.extra.discards
			G.GAME.round_resets.discards = G.GAME.round_resets.discards + card.ability.extra.discards
			ease_discard(card.ability.extra.discards)
			MP.ACTIONS.eat_pizza(card.ability.extra.discards_nemesis)
			card:remove_from_deck()
			card:start_dissolve({ G.C.RED }, nil, 1.6)
			return {
				message = localize("k_eaten_ex"),
				colour = G.C.RED,
			}
		end
	end,
	mp_credits = {
		idea = { "Virtualized" },
		art = { "TheTrueRaven" },
		code = { "Virtualized" },
	},
})
