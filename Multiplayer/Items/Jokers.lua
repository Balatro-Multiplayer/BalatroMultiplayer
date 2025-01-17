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
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	ability = { extra = 60, chips = 0 },
	loc_vars = function(self, info_queue, card)
		return { vars = { self.ability.extra, self.ability.chips } }
	end,
	in_pool = function(self)
		return G.LOBBY.code
	end,
	update = function(self, card, dt)
		if G.STAGE == G.STAGES.RUN then
			self.ability.chips = (G.LOBBY.config.starting_lives - G.MULTIPLAYER_GAME.lives) * self.ability.extra
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main then
			return {
				message = localize({
					type = "variable",
					key = "a_chips",
					vars = { self.ability.chips },
				}),
				chip_mod = self.ability.chips,
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
	ability = { extra_hands = 1, extra_discards = 1, hands = 0, discards = 0 },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return {
			vars = {
				self.ability.extra_hands,
				self.ability.extra_discards,
				self.ability.hands,
				self.ability.discards,
				localize({
					type = "variable",
					key = G.MULTIPLAYER_GAME.enemy.skips > G.GAME.skips and "mp_skips_behind"
						or G.MULTIPLAYER_GAME.enemy.skips == G.GAME.skips and "mp_skips_tied"
						or "mp_skips_ahead",
					vars = { math.abs(G.MULTIPLAYER_GAME.enemy.skips - G.GAME.skips) },
				})[1],
			},
		}
	end,
	in_pool = function(self)
		return G.LOBBY.code
	end,
	update = function(self, card, dt)
		if G.STAGE == G.STAGES.RUN then
			local skip_diff = (math.max(G.GAME.skips - G.MULTIPLAYER_GAME.enemy.skips, 0))
			self.ability.hands = skip_diff * self.ability.extra_hands
			self.ability.discards = skip_diff * self.ability.extra_discards
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.setting_blind then
			G.E_MANAGER:add_event(Event({
				func = function()
					ease_hands_played(self.ability.hands)
					ease_discard(self.ability.discards, nil, true)
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

SMODS.Joker({
	key = "lets_go_gambling",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { 1, 4, 0.5, 0.2, 1 } }
	end,
	in_pool = function(self)
		return G.LOBBY.code
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = {},
		code = { "Virtualized" },
	},
})

SMODS.Joker({
	key = "hanging_bad",
	rarity = 1,
	cost = 4,
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
		return G.LOBBY.code
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = {},
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
		return G.LOBBY.code
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = { "Aura!" },
		code = { "Virtualized" },
	},
})
