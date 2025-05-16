SMODS.Atlas({
	key = "magnet",
	path = "j_magnet.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "magnet",
	atlas = "magnet",
	rarity = 3,
	cost = 7,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = false,
	perishable_compat = true,
	config = { extra = { rounds = 2, current_rounds = 0 } },
	loc_vars = function(self, info_queue, card)
		MP.UTILS.add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.rounds, card.ability.extra.current_rounds, card.ability.extra.rounds } }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	add_to_deck = function(self, card, from_debuffed)
		if not from_debuffed and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.send_phantom("j_mp_magnet")
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not from_debuff and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.remove_phantom("j_mp_magnet")
		end
	end,
	calculate = function(self, card, context)
		if context.end_of_round and not context.other_card and not context.blueprint and not context.debuffed and (not card.edition or card.edition.type ~= "mp_phantom") then
			card.ability.extra.current_rounds = card.ability.extra.current_rounds + 1
			if card.ability.extra.current_rounds == card.ability.extra.rounds then
				local eval = function(card)
					return not card.REMOVED
				end
				juice_card_until(card, eval, true)
			end
			return {
				message = (card.ability.extra.current_rounds < card.ability.extra.rounds)
					and (card.ability.extra.current_rounds .. "/" .. card.ability.extra.rounds)
					or localize("k_active_ex"),
				colour = G.C.FILTER,
			}
		end
		if
			context.selling_self
			and (card.ability.extra.current_rounds >= card.ability.extra.rounds)
			and not context.blueprint
		then
			MP.ACTIONS.magnet()
		end
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "Ganpan140" },
		code = { "Virtualized" },
	},
})
