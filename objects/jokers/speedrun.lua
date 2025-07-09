SMODS.Atlas({
	key = "speedrun",
	path = "j_speedrun.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "speedrun",
	atlas = "speedrun",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	loc_vars = function(self, info_queue, card)
		MP.UTILS.add_nemesis_info(info_queue)
		return { vars = {} }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	calculate = function(self, card, context)
		if context.mp_speedrun and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
			G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
			G.E_MANAGER:add_event(Event({
				trigger = 'before',
				delay = 0.0,
				func = function()
					local card = create_card('Spectral',G.consumeables, nil, nil, nil, nil, nil, 'mp_speedrun')
					card:add_to_deck()
					G.consumeables:emplace(card)
					G.GAME.consumeable_buffer = 0
					return true
				end,
			}))
			return {
				message = localize('k_plus_spectral'),
				colour = G.C.SECONDARY_SET.Spectral,
				card = card
			}
		end
	end,
	mp_credits = {
		idea = { "Virtualized" },
		art = { "Aura!" },
		code = { "Virtualized" },
	},
})
