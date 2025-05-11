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
	config = { extra = { discards = 6, discards_loss = 1 } },
	loc_vars = function(self, info_queue, card)
		MP.UTILS.add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.discards, card.ability.extra.discards_loss } }
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
		if context.setting_blind and not context.blueprint then
			card.ability.extra.discards = card.ability.extra.discards - card.ability.extra.discards_loss
			if card.ability.extra.discards <= 0 and (not card.edition or card.edition.type ~= "mp_phantom") then
				card:remove_from_deck()
				card:start_dissolve({ G.C.RED }, nil, 1.6)
				return {
					message = localize("k_eaten_ex"),
					colour = G.C.FILTER,
				}
			end
			G.E_MANAGER:add_event(Event({
				func = function()
					ease_discard(card.ability.extra.discards, nil, true)
					return true
				end,
			}))
			MP.ACTIONS.eat_pizza(false)
			return {
				message = localize({
					type = "variable",
					key = "a_remaining",
					vars = { card.ability.extra.discards },
				}),
				colour = G.C.RED,
			}
		end
		if context.skip_blind and card.edition and card.edition.type == "mp_phantom" and not context.blueprint then
			MP.ACTIONS.eat_pizza(true)
		end
	end,
	mp_credits = {
		idea = { "Virtualized" },
		art = { "TheTrueRaven" },
		code = { "Virtualized" },
	},
})
