SMODS.Atlas({
	key = "magnet",
	path = "j_magnet.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "magnet_sandbox",
	atlas = "magnet",
	rarity = 3,
	cost = 7,
	unlocked = true,
	discovered = true,
	no_collection = MP.sandbox_no_collection,
	blueprint_compat = false,
	eternal_compat = false,
	perishable_compat = true,
	config = { extra = { rounds = 2, current_rounds = 0, max_rounds = 5 } },
	loc_vars = function(self, info_queue, card)
		MP.UTILS.add_nemesis_info(info_queue)
		return {
			vars = {
				card.ability.extra.rounds,
				card.ability.extra.current_rounds,
				card.ability.extra.max_rounds,
			},
		}
	end,
	add_to_deck = function(self, card, from_debuffed)
		if not from_debuffed and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.send_phantom("j_mp_magnet_sandbox")
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not from_debuff and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.remove_phantom("j_mp_magnet_sandbox")
		end
	end,
	calculate = function(self, card, context)
		if
			context.end_of_round
			and not context.other_card
			and not context.blueprint
			and not context.debuffed
			and (not card.edition or card.edition.type ~= "mp_phantom")
		then
			local removed = false
			card.ability.extra.current_rounds = card.ability.extra.current_rounds + 1
			if card.ability.extra.current_rounds > card.ability.extra.max_rounds then
				removed = true
				G.E_MANAGER:add_event(Event({
					func = function()
						play_sound("tarot1")
						card.T.r = -0.2
						card:juice_up(0.3, 0.4)
						card.states.drag.is = false
						card.children.center.pinch.x = true
						G.E_MANAGER:add_event(Event({
							trigger = "after",
							delay = 0.3,
							blockable = false,
							func = function()
								G.jokers:remove_card(card)
								card:remove()
								card = nil
								return true
							end,
						}))
						return true
					end,
				}))
				card_eval_status_text(card, "extra", nil, nil, nil, { message = localize("k_no_reward") })
			end
			if card.ability.extra.current_rounds == card.ability.extra.rounds then
				local eval = function(card)
					return not card.REMOVED
				end
				juice_card_until(card, eval, true)
			end
			if not removed then
				return {
					message = (card.ability.extra.current_rounds < card.ability.extra.rounds)
							and (card.ability.extra.current_rounds .. "/" .. card.ability.extra.rounds)
						or localize("k_active_ex"),
					colour = G.C.FILTER,
				}
			end
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
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key) and MP.LOBBY.config.multiplayer_jokers
	end,
})
