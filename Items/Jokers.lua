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
	config = { t_chips = 0, extra = { extra = 60 } },
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
	config = { x_mult = 1, extra = { denominator = 4, extra = 0.3, extra_extra = 0.2 } },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				G.GAME.probabilities.normal,
				card.ability.extra.denominator,
				card.ability.extra.extra,
				card.ability.extra.extra_extra,
				card.ability.x_mult,
			},
		}
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers then
			if context.joker_main then
				return {
					message = localize({
						type = "variable",
						key = "a_xmult",
						vars = { card.ability.x_mult },
					}),
					Xmult_mod = card.ability.x_mult,
				}
			end
			if context.end_of_round and not context.blueprint and not context.repetition and G.GAME.blind.boss then
				card.ability.extra.extra = card.ability.extra.extra + card.ability.extra.extra_extra
				return {
					message = localize({
						type = "variable",
						key = "a_xmult_plus",
						vars = { card.ability.extra.extra_extra },
					}),
				}
			end
		end
		if context.selling_self and not context.blueprint then
			if pseudorandom(self.key) > G.GAME.probabilities.normal / card.ability.extra.denominator then
				local new_card = copy_card(card)
				new_card:start_materialize()
				new_card:add_to_deck()
				G.jokers:emplace(new_card)
				new_card.ability.x_mult = card.ability.x_mult + card.ability.extra.extra
				new_card.ability.extra.extra = card.ability.extra.extra
			else
				G.E_MANAGER:add_event(Event({
					trigger = "after",
					delay = 0.06 * G.SETTINGS.GAMESPEED,
					blockable = false,
					blocking = false,
					func = function()
						play_sound("tarot2", 0.76, 0.4)
						return true
					end,
				}))
				play_sound("tarot2", 1, 0.4)
				attention_text({
					text = localize("k_nope_ex"),
					scale = 0.8,
					hold = 0.8,
					major = card,
					backdrop_colour = G.C.SECONDARY_SET.Tarot,
					align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and "tm" or "cm",
					offset = {
						x = 0,
						y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0,
					},
					silent = true,
				})
			end
		end
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = { "Carter" },
		code = { "Virtualized" },
	},
})

SMODS.Atlas({
	key = "hanging_bad",
	path = "j_hanging_bad.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "hanging_bad",
	atlas = "hanging_bad",
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
	add_to_deck = function(self, card, from_debuff)
		if card.edition and card.edition.type ~= "e_mp_phantom" then
			return
		end
		G.MULTIPLAYER.send_phantom("j_mp_hanging_bad")
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and is_pvp_boss() then
			if context.before and context.scoring_hand then
				context.scoring_hand[1]:set_debuff(true)
			end
			if context.after and context.scoring_hand then
				context.scoring_hand[1]:set_debuff(false)
			end
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if card.edition and card.edition.type ~= "e_mp_phantom" then
			return
		end
		G.MULTIPLAYER.remove_phantom("j_mp_hanging_bad")
	end,
	in_pool = function(self)
		return G.LOBBY.code and G.LOBBY.config.multiplayer_jokers
	end,
	mp_credits = {
		idea = { "Dr. Monty", "Carter" },
		art = { "TheTrueRaven" },
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
