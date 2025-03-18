SMODS.Atlas({
	key = "defensive_joker",
	path = "j_defensive_joker.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "defensive_joker",
	atlas = "defensive_joker",
	rarity = 1,
	cost = 4,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { t_chips = 0, extra = { extra = 125 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.extra, card.ability.t_chips } }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	update = function(self, card, dt)
		if G.LOBBY.code then
			if G.STAGE == G.STAGES.RUN then
				card.ability.t_chips = (G.LOBBY.config.starting_lives - G.MULTIPLAYER_GAME.lives)
					* card.ability.extra.extra
			end
		else
			card.ability.t_chips = 0
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main then
			return {
				message = localize({
					type = "variable",
					key = "a_chips",
					vars = { card.ability.t_chips },
				}),
				chip_mod = card.ability.t_chips,
			}
		end
	end,
	mp_credits = {
		idea = { "didon't" },
		art = { "TheTrueRaven" },
		code = { "Virtualized" },
	},
})

SMODS.Atlas({
	key = "skip_off",
	path = "j_skip_off.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "skip_off",
	atlas = "skip_off",
	rarity = 2,
	cost = 5,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	config = { h_size = 0, d_size = 0, extra = { extra_hands = 1, extra_discards = 1 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return {
			vars = {
				card.ability.extra.extra_hands,
				card.ability.extra.extra_discards,
				card.ability.h_size,
				card.ability.d_size,
				G.GAME.skips ~= nil and G.MULTIPLAYER_GAME.enemy.skips ~= nil and localize({
					type = "variable",
					key = G.MULTIPLAYER_GAME.enemy.skips > G.GAME.skips and "mp_skips_behind"
						or G.MULTIPLAYER_GAME.enemy.skips == G.GAME.skips and "mp_skips_tied"
						or "mp_skips_ahead",
					vars = { math.abs(G.MULTIPLAYER_GAME.enemy.skips - G.GAME.skips) },
				})[1] or "",
			},
		}
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	update = function(self, card, dt)
		if G.STAGE == G.STAGES.RUN and G.GAME.skips ~= nil and G.MULTIPLAYER_GAME.enemy.skips ~= nil then
			local skip_diff = (math.max(G.GAME.skips - G.MULTIPLAYER_GAME.enemy.skips, 0))
			card.ability.h_size = skip_diff * card.ability.extra.extra_hands
			card.ability.d_size = skip_diff * card.ability.extra.extra_discards
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.setting_blind and not context.blueprint then
			G.E_MANAGER:add_event(Event({
				func = function()
					ease_hands_played(card.ability.h_size)
					ease_discard(card.ability.d_size, nil, true)
					return true
				end,
			}))
		end
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = { "Aura!" },
		code = { "Virtualized" },
	},
})

SMODS.Atlas({
	key = "lets_go_gambling",
	path = "j_lets_go_gambling.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "lets_go_gambling",
	atlas = "lets_go_gambling",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { denominator = 4, xmult = 4, dollars = 10, nemesis_denominator = 8, nemesis_dollars = 5 } },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				G.GAME.probabilities.normal,
				card.ability.extra.denominator,
				card.ability.extra.xmult,
				card.ability.extra.dollars,
				G.GAME.probabilities.normal,
				card.ability.extra.nemesis_denominator,
				card.ability.extra.nemesis_dollars,
			},
		}
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	calculate = function(self, card, context)
		
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = { "Carter" },
		code = { "Virtualized" },
	},
})

SMODS.Atlas({
	key = "speedrun",
	path = "j_speedrun.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "speedrun",
	atlas = "speedrun",
	rarity = 3,
	cost = 8,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = {} }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = { "Aura!" },
		code = { "Virtualized" },
	},
})

SMODS.Atlas({
	key = "conjoined_joker",
	path = "j_conjoined_joker.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "conjoined_joker",
	atlas = "conjoined_joker",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { xmult_gain = 1, max_xmult = 5, xmult = 1 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.xmult_gain, card.ability.extra.max_xmult, card.ability.extra.xmult } }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "Nas4xou" },
		code = { "Virtualized" },
	},
})

SMODS.Atlas({
	key = "copycat",
	path = "j_copycat.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "copycat",
	atlas = "copycat",
	rarity = 3,
	cost = 8,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = {} }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "zeathemays" },
		code = { "Virtualized" },
	},
})

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
	cost = 8,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { rounds = 2, current_rounds = 0 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.rounds, card.ability.extra.current_rounds, card.ability.extra.rounds } }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "Ganpan140" },
		code = { "Virtualized" },
	},
})

SMODS.Atlas({
	key = "penny_pincher",
	path = "j_penny_pincher.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "penny_pincher",
	atlas = "penny_pincher",
	rarity = 1,
	cost = 4,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { dollars = 1, nemesis_dollars = 3 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.dollars, card.ability.extra.nemesis_dollars } }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Nxkoozie" },
		art = { "Coo29" },
		code = { "Virtualized" },
	},
})

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
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { discards = 6, discards_loss = 1 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.discards, card.ability.extra.discards_loss } }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Virtualized" },
		art = { "TheTrueRaven" },
		code = { "Virtualized" },
	},
})

SMODS.Atlas({
	key = "taxes",
	path = "j_taxes.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "taxes",
	atlas = "taxes",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { mult_gain = 5, mult = 1 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.mult_gain, card.ability.extra.mult } }
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Zwei" },
		art = { "Kittyknight" },
		code = { "Virtualized" },
	},
})
