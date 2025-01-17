function apply_phantom(card)
	if card.cardarea then
		card.cardarea.config.card_limit = card.cardarea.config.card_limit + 1
	end
	card.ability.eternal = true
end

function remove_phantom(card)
	if card.cardarea then
		card.cardarea.config.card_limit = card.cardarea.config.card_limit - 1
	end
	card.ability.eternal = false
end

SMODS.Edition({
	key = "phantom",
	shader = "voucher",
	discovered = true,
	unlocked = true,
	in_shop = false,
	apply_to_float = true,
	badge_colour = G.C.PURPLE,
	sound = { sound = "negative", per = 1.5, vol = 0.4 },
	disable_shadow = false,
	disable_base_shader = true,
	extra_cost = 0, -- Min sell value is set to -1 by Multiplayer (1 by default) so this is a hack to make the card this is applied to not have a sell value
	on_apply = apply_phantom,
	on_remove = remove_phantom,
	on_load = apply_phantom,
	prefix_config = { shader = false },
	mp_credits = {
		idea = { "Virtualized" },
		art = {},
		code = { "Virtualized" },
	},
})

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
		art = { "Carter" },
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
