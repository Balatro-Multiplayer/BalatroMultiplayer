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
