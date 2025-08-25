-- TODO convert to smods jokers with
-- disable in collection
-- in pool only if sandbox
--
--

SMODS.Atlas({
	key = "misprint_sandbox",
	path = "j_misprint_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Atlas({
	key = "castle_sandbox",
	path = "j_castle_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Atlas({
	key = "photograph_sandbox",
	path = "j_photograph_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "lucky_cat_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 2,
	cost = 6,
	pos = { x = 5, y = 14 },
	config = { extra = { Xmult_gain = 0.25, Xmult = 1 } },
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.m_lucky

		return { vars = { card.ability.extra.Xmult_gain, card.ability.extra.Xmult } }
	end,
	calculate = function(self, card, context)
		if
			context.individual
			and context.cardarea == G.play
			and context.other_card.lucky_trigger
			and not context.blueprint
		then
			card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_gain
			-- TODO verify this
			if SMODS.pseudorandom_probability(card, "j_lucky_cat_mp_sandbox", 1, 3) then
				context.other_card:set_ability("m_glass", nil, true)
			end
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.MULT,
				message_card = card,
			}
		end
		if context.joker_main then return {
			xmult = card.ability.extra.Xmult,
		} end
	end,
	in_pool = function(self, args) --equivalent to `enhancement_gate = 'm_lucky'`
		if not (MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code) then return false end
		for _, playing_card in ipairs(G.playing_cards or {}) do
			if SMODS.has_enhancement(playing_card, "m_lucky") then return true end
		end
		return false
	end,
})

-- TODO ban purchases!
SMODS.Joker({
	key = "stencil_sandbox",
	blueprint_compat = true,
	rarity = 2,
	cost = 8,
	pos = { x = 2, y = 5 },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				G.jokers and math.max(
					1.5,
					((G.jokers.config.card_limit - #G.jokers.cards) + #SMODS.find_card("j_stencil", true)) * 1.5
				) or 1.5,
			},
		}
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = math.max(
					1.5,
					((G.jokers.config.card_limit - #G.jokers.cards) + #SMODS.find_card("j_stencil", true)) * 1.5
				),
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO test and verify!!
--
SMODS.Joker({
	key = "constellation_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 2,
	cost = 6,
	pos = { x = 9, y = 10 },
	config = { extra = { Xmult = 1, Xmult_mod = 0.2, Xmult_loss = 0.1 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.Xmult } }
	end,
	calculate = function(self, card, context)
		-- Gain mult when planet card is used
		if context.using_consumeable and not context.blueprint and context.consumeable.ability.set == "Planet" then
			card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
			return {
				message = localize({ type = "variable", key = "a_xmult", vars = { card.ability.extra.Xmult } }),
			}
		end
		-- Apply mult during main calculation
		if context.joker_main then return {
			xmult = card.ability.extra.Xmult,
		} end
		-- Lose mult at end of round
		if context.end_of_round and not context.individual and not context.repetition then
			card.ability.extra.Xmult = math.max(1, card.ability.extra.Xmult - card.ability.extra.Xmult_loss)
			return {
				message = localize("k_reset"),
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO implement card destruction!
SMODS.Joker({
	key = "chaos_sandbox",
	blueprint_compat = false,
	rarity = 1,
	cost = 4,
	pos = { x = 1, y = 0 },
	config = { extra = { rerolls = 9999 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.rerolls } }
	end,
	add_to_deck = function(self, card, from_debuff)
		SMODS.change_free_rerolls(card.ability.extra.rerolls)
	end,
	remove_from_deck = function(self, card, from_debuff)
		SMODS.change_free_rerolls(-card.ability.extra.rerolls)
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO make rank be set on purchase instead! or when it appears in shop!
SMODS.Joker({
	key = "mail_sandbox",
	blueprint_compat = true,
	rarity = 1,
	cost = 4,
	pos = { x = 7, y = 13 },
	config = { extra = { dollars = 8 } },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.dollars,
				localize((G.GAME.current_round.mail_card or {}).rank or "Ace", "ranks"),
			},
		}
	end,
	calculate = function(self, card, context)
		if
			context.discard
			and not context.other_card.debuff
			and context.other_card:get_id() == G.GAME.current_round.mail_card.id
		then
			G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
			return {
				dollars = card.ability.extra.dollars,
				func = function() -- This is for timing purposes, it runs after the dollar manipulation
					G.E_MANAGER:add_event(Event({
						func = function()
							G.GAME.dollar_buffer = 0
							return true
						end,
					}))
				end,
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO: Show ?? when it appears in shop instead!
SMODS.Joker({
	key = "misprint_sandbox",
	atlas = "misprint_sandbox",
	blueprint_compat = true,
	rarity = 1,
	cost = 4,
	ruleset = "sandbox",
	config = { extra = { max = 46, min = -5, mult = 0 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult } }
	end,
	add_to_deck = function(self, card, from_debuff)
		card.ability.extra.mult = pseudorandom("misprint_sandbox", card.ability.extra.min, card.ability.extra.max) -- TODO replace with steamodded pseudorandom
	end,
	calculate = function(self, card, context)
		if context.joker_main then return {
			mult = card.ability.extra.mult,
		} end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO: Make set on purchase or when in shop!
SMODS.Joker({
	key = "castle_sandbox",
	atlas = "castle_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 2,
	cost = 6,
	config = { extra = { chips = 50, chip_mod = 10 } },
	loc_vars = function(self, info_queue, card)
		local suit = (G.GAME.current_round.castle_card or {}).suit or "Spades"
		return {
			vars = {
				localize(suit, "suits_singular"),
				card.ability.extra.chips,
				colours = { G.C.SUITS[suit] },
			},
		}
	end,
	calculate = function(self, card, context)
		if
			context.discard
			and not context.blueprint
			and not context.other_card.debuff
			and context.other_card:is_suit(G.GAME.current_round.castle_card.suit)
		then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.CHIPS,
			}
		end
		if context.joker_main then return {
			chips = card.ability.extra.chips,
		} end
	end,

	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO: Makes it so we can only play straights
SMODS.Joker({
	key = "runner_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 1,
	cost = 5,
	pos = { x = 3, y = 10 },
	config = { extra = { chips = 0, chip_mod = 50 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips } }
	end,
	calculate = function(self, card, context)
		if context.before and context.main_eval and not context.blueprint and next(context.poker_hands["Straight"]) then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.CHIPS,
			}
		end
		if context.joker_main and next(context.poker_hands["Straight"]) then
			return {
				chips = card.ability.extra.chips,
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO verify
SMODS.Joker({
	key = "loyalty_card_sandbox",
	blueprint_compat = true,
	rarity = 2,
	cost = 5,
	pos = { x = 4, y = 2 },
	config = { extra = { Xmult = 6, every = 4, loyalty_remaining = 4, poker_hand = "???" } },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.poker_hand,
				localize({
					type = "variable",
					key = (card.ability.extra.loyalty_remaining == 0 and "loyalty_active" or "loyalty_inactive"),
					vars = { card.ability.extra.loyalty_remaining },
				}),
			},
		}
	end,
	add_to_deck = function(self, card, from_debuff)
		local _poker_hands = {}
		for handname, _ in pairs(G.GAME.hands) do
			if SMODS.is_poker_hand_visible(handname) then _poker_hands[#_poker_hands + 1] = handname end
		end
		card.ability.extra.poker_hand = pseudorandom_element(_poker_hands, "loyalty_card_sandbox")
	end,
	calculate = function(self, card, context)
		if context.before and context.main_eval then
			if context.scoring_name == card.ability.extra.poker_hand then
				-- Played the loyal hand - decrease loyalty_remaining
				if card.ability.extra.loyalty_remaining > 0 then
					card.ability.extra.loyalty_remaining = card.ability.extra.loyalty_remaining - 1
				end
			else
				-- Played a different hand - relationship broken, reset loyalty
				card.ability.extra.loyalty_remaining = card.ability.extra.every
				return {
					message = localize("k_reset"),
					colour = G.C.RED,
				}
			end
		end
		if context.joker_main then
			if not context.blueprint then
				if card.ability.extra.loyalty_remaining == 0 then
					local eval = function(card)
						return card.ability.extra.loyalty_remaining == 0 and not G.RESET_JIGGLES
					end
					juice_card_until(card, eval, true)
				end
			end
			if card.ability.extra.loyalty_remaining == 0 then return {
				xmult = card.ability.extra.Xmult,
			} end
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO ...
SMODS.Joker({
	key = "faceless_sandbox",
	blueprint_compat = true,
	rarity = 1,
	cost = 4,
	pos = { x = 1, y = 11 },
	config = { extra = { dollars = 5, faces = 3 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.dollars, card.ability.extra.faces } }
	end,
	calculate = function(self, card, context)
		if context.discard and context.other_card == context.full_hand[#context.full_hand] then
			local jacks = 0
			local queens = 0
			local kings = 0

			for _, discarded_card in ipairs(context.full_hand) do
				local rank = discarded_card:get_id()
				if rank == 11 then jacks = jacks + 1 end
				if rank == 12 then queens = queens + 1 end
				if rank == 13 then kings = kings + 1 end
			end

			if jacks == 1 and queens == 1 and kings == 1 then
				G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
				return {
					dollars = card.ability.extra.dollars,
					func = function()
						G.E_MANAGER:add_event(Event({
							func = function()
								G.GAME.dollar_buffer = 0
								return true
							end,
						}))
					end,
				}
			end
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO fix it!
-- MP.ReworkCenter({
-- 	key = "j_flash",
-- 	ruleset = "sandbox",
-- 	config = { extra = { mult_gain = 10, mult = 0, reroll_cost = 10 } },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.mult_gain, card.ability.extra.mult } }
-- 	end,
-- 	add_to_deck = function(self, card, from_debuff)
-- 		print("TODO 10 reroll cost")
-- 		-- SMODS.change_free_rerolls(card.ability.extra.rerolls)
-- 	end,
-- 	remove_from_deck = function(self, card, from_debuff)
-- 		print("TODO 10 now reroll cost should disappear")
-- 		-- SMODS.change_free_rerolls(-card.ability.extra.rerolls)
-- 	end,
-- })

SMODS.Joker({
	key = "photograph_sandbox",
	blueprint_compat = true,
	atlas = "photograph_sandbox",
	rarity = 1,
	cost = 5,
	pixel_size = { h = 95 / 1.2 },
	config = { extra = { xmult = 5 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult } }
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play and context.other_card:is_face() then
			local is_first_face = false
			if context.scoring_hand[1]:is_face() then is_first_face = true end
			if #context.full_hand == 1 and is_first_face then return {
				xmult = card.ability.extra.xmult,
			} end
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

SMODS.Joker({
	key = "cloud_9_sandbox",
	-- no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 2,
	cost = 7,
	pos = { x = 7, y = 12 },
	config = { extra = 2, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		local nine_tally = 0
		if G.playing_cards ~= nil then
			for k, v in pairs(G.playing_cards) do
				if v:get_id() == 9 then nine_tally = nine_tally + 1 end
			end
		end

		return {
			vars = {
				card.ability.extra,
				(math.min(nine_tally, 4) + math.max(nine_tally - 4, 0) * card.ability.extra) or 0,
			},
		}
	end,
	-- in_pool = function(self)
	-- 	return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	-- end,
	calc_dollar_bonus = function(self, card)
		local nine_tally = 0
		for k, v in pairs(G.playing_cards) do
			if v:get_id() == 9 then nine_tally = nine_tally + 1 end
		end
		return (math.min(nine_tally, 4) + math.max(nine_tally - 4, 0) * card.ability.extra) or 0
	end,
})

-- TODO implement "only 4 hands for the rest of your life"
SMODS.Joker({
	key = "square_sandbox",
	blueprint_compat = true,
	perishable_compat = false,
	rarity = 1,
	cost = 4,
	pos = { x = 9, y = 11 },
	pixel_size = { h = 71 },
	config = { extra = { chips = 64, chip_mod = 16 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
	calculate = function(self, card, context)
		if context.before and context.main_eval and not context.blueprint and #context.full_hand == 4 then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.CHIPS,
			}
		end
		if context.joker_main and #context.full_hand == 4 then return {
			chips = card.ability.extra.chips,
		} end
	end,
})

SMODS.Joker({
	key = "to_the_moon_sandbox",
	blueprint_compat = false,
	rarity = 2,
	cost = 5,
	pos = { x = 8, y = 13 },
	config = {
		extra = {
			market_multiplier = 1.0,
			volatility_streak = 0,
			hands_this_round = 0,
			market_mood = "stable", -- "bull", "bear", "crash", "moon"
		},
	},
	loc_vars = function(self, info_queue, card)
		return { vars = { string.upper(card.ability.extra.market_mood) } }
	end,
	calculate = function(self, card, context)
		if context.before and context.main_eval then
			card.ability.extra.hands_this_round = card.ability.extra.hands_this_round + 1

			-- Market reacts to your performance
			if context.scoring_hand and #context.scoring_hand >= 5 then
				-- Big hand = BULL MARKET (60% chance)
				if SMODS.pseudorandom_probability(card, "market_react_bull", 6, 10) then
					card.ability.extra.market_mood = "bull"
				end
			elseif mult < 50 then
				-- Weak hand = BEAR MARKET (40% chance)
				if SMODS.pseudorandom_probability(card, "market_react_bear", 4, 10) then
					card.ability.extra.market_mood = "bear"
				end
			end

			-- Random moon shots (5% chance) and crashes (2% chance)
			if SMODS.pseudorandom_probability(card, "market_react_moon", 1, 20) then
				card.ability.extra.market_mood = "moon"
			elseif SMODS.pseudorandom_probability(card, "market_react_crash", 1, 50) then
				card.ability.extra.market_mood = "crash"
			end
		end

		-- Reroll shop events - market volatility affects costs
		if context.reroll_shop and not context.blueprint then
			local reroll_effects = {
				stable = function()
					return 0
				end,
				bull = function()
					if SMODS.pseudorandom_probability(card, "bull_reroll") < 0.3 then
						return math.floor(1 + SMODS.pseudorandom_probability(card, "bull_reroll_amount") * 3) -- gain 1-3 dollars
					end
					return 0
				end,
				bear = function()
					if SMODS.pseudorandom_probability(card, "bear_reroll") < 0.4 then
						return -math.floor(1 + SMODS.pseudorandom_probability(card, "bear_reroll_amount") * 2) -- lose 1-2 dollars
					end
					return 0
				end,
				moon = function()
					if SMODS.pseudorandom_probability(card, "moon_reroll") < 0.5 then
						return math.floor(5 + SMODS.pseudorandom_probability(card, "moon_reroll_amount") * 10) -- gain 5-15 dollars
					end
					return 0
				end,
				crash = function()
					if SMODS.pseudorandom_probability(card, "crash_reroll") < 0.7 then
						return -math.floor(3 + SMODS.pseudorandom_probability(card, "crash_reroll_amount") * 5) -- lose 3-8 dollars
					end
					return 0
				end,
			}

			local dollar_change = reroll_effects[card.ability.extra.market_mood]()
			if dollar_change ~= 0 then
				G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + dollar_change
				return {
					dollars = dollar_change,
					message = dollar_change > 0 and "MARKET SURGE!" or "MARKET DIP!",
					colour = dollar_change > 0 and G.C.MONEY or G.C.RED,
				}
			end
		end

		-- Blind selection events - market anticipation
		if context.setting_blind and not context.blueprint then
			local blind_effects = {
				stable = function()
					return 0
				end,
				bull = function()
					if SMODS.pseudorandom_probability(card, "bull_blind") < 0.2 then
						return math.floor(2 + SMODS.pseudorandom_probability(card, "bull_blind_amount") * 4) -- gain 2-6 dollars
					end
					return 0
				end,
				bear = function()
					if SMODS.pseudorandom_probability(card, "bear_blind") < 0.3 then
						return -math.floor(1 + SMODS.pseudorandom_probability(card, "bear_blind_amount") * 3) -- lose 1-4 dollars
					end
					return 0
				end,
				moon = function()
					if SMODS.pseudorandom_probability(card, "moon_blind") < 0.15 then
						return math.floor(10 + SMODS.pseudorandom_probability(card, "moon_blind_amount") * 20) -- gain 10-30 dollars
					end
					return 0
				end,
				crash = function()
					if SMODS.pseudorandom_probability(card, "crash_blind") < 0.5 then
						return -math.floor(2 + SMODS.pseudorandom_probability(card, "crash_blind_amount") * 6) -- lose 2-8 dollars
					end
					return 0
				end,
			}

			local dollar_change = blind_effects[card.ability.extra.market_mood]()
			if dollar_change ~= 0 then
				G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + dollar_change
				return {
					dollars = dollar_change,
					message = dollar_change > 0 and "PRE-MARKET!" or "MARKET FEAR!",
					colour = dollar_change > 0 and G.C.MONEY or G.C.RED,
				}
			end
		end
	end,
	calc_dollar_bonus = function(self, card)
		local base_interest = G.GAME.interest_amount
		local multipliers = {
			stable = 1.0,
			bull = 2.5 + SMODS.pseudorandom_probability(card, "bull_bonus") * 2, -- 2.5x to 4.5x
			bear = 0.1 + SMODS.pseudorandom_probability(card, "bear_penalty") * 0.4, -- 0.1x to 0.5x
			moon = 8 + SMODS.pseudorandom_probability(card, "moon_bonus") * 7, -- 8x to 15x
			crash = 0,
		}
		return math.floor(base_interest * multipliers[card.ability.extra.market_mood])
	end,

	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
