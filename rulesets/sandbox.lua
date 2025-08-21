MP.SANDBOX = {}

MP.Ruleset({
	key = "sandbox",
	standard = true,
	multiplayer_content = true,
	banned_jokers = {
		"j_cloud_9",
		"j_hanging_chad",
		"j_bloodstone",
	},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = { "tag_rare" },
	banned_blinds = {},

	reworked_jokers = {
		"j_mp_cloud_9",
		"j_mp_bloodstone2",
		"j_mp_hanging_chad",
		"j_lucky_cat",
		"j_stencil",
		"j_constellation",
		"j_bloodstone",
		"j_reserved_parking",
		"j_egg",
		"j_chaos",
		"j_turtle_bean",
		"j_juggler",
		"j_mail",
		"j_hit_the_road",
		"j_red_card",
		"j_misprint",
		"j_castle",
		"j_business",
		"j_runner",
		"j_delayed_grat",
		"j_photograph",
		"j_ride_the_bus",
		"j_golden",
		"j_loyalty_card",
		"j_scary_face",
		"j_faceless",
		"j_flash",
		"j_throwback",
		"j_gros_michel",
		-- "j_idol",
		-- "j_square",
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		-- "m_glass",
	},
	reworked_blinds = {},
	reworked_tags = { "tag_mp_sandbox_rare" },

	create_info_menu = function()
		return {
			{
				n = G.UIT.R,
				config = {
					align = "tm",
				},
				nodes = {
					MP.UI.BackgroundGrouping(localize("k_has_multiplayer_content"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_yes"),
								scale = 0.8,
								colour = G.C.GREEN,
							},
						},
					}, { col = true, text_scale = 0.6 }),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1,
						},
					},
					MP.UI.BackgroundGrouping(localize("k_forces_lobby_options"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							},
						},
					}, { col = true, text_scale = 0.6 }),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1,
						},
					},
					MP.UI.BackgroundGrouping(localize("k_forces_gamemode"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							},
						},
					}, { col = true, text_scale = 0.6 }),
				},
			},
			{
				n = G.UIT.R,
				config = {
					minw = 0.05,
					minh = 0.05,
				},
			},
			{
				n = G.UIT.R,
				config = {
					align = "cl",
					padding = 0.1,
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_sandbox_description"),
							scale = 0.6,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
		}
	end,

	forced_lobby_options = true,

	force_lobby_options = function(self)
		MP.LOBBY.config.preview_disabled = true
		MP.LOBBY.config.different_seeds = false
		return true
	end,
}):inject()

-- TODO broken:
-- loyalty card
-- some joker in collection crashes

SMODS.Joker:take_ownership("lucky_cat", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

MP.ReworkCenter({
	key = "j_lucky_cat",
	ruleset = "sandbox",
	config = { extra = { Xmult_gain = 0.25, Xmult = 1 } },
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.m_lucky
		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.Xmult_gain, card.ability.extra.Xmult } } -- Append "_mp_sandbox" to key AND pass relevant vars
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
})

-- Take ownership of all jokers that will be reworked
SMODS.Joker:take_ownership("stencil", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("runner", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("constellation", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("bloodstone", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("chaos", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.rerolls } }
	end,
})

SMODS.Joker:take_ownership("ride_the_bus", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("reserved_parking", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("egg", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("flash", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("turtle_bean", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("juggler", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("mail", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("hit_the_road", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("red_card", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("misprint", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("castle", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("business", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("delayed_grat", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("photograph", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("golden", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("loyalty_card", {
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra } }
	end,
})

SMODS.Joker:take_ownership("scary_face", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("faceless", {
	loc_vars = function(self, info_queue, card)
		return {}
	end,
})

SMODS.Joker:take_ownership("throwback", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

SMODS.Joker:take_ownership("gros_michel", {
	loc_vars = function(self, info_queue, card)
		return { vars = {} }
	end,
})

-- Rework all jokers with sandbox implementations
MP.ReworkCenter({
	key = "j_stencil",
	ruleset = "sandbox",
	config = { extra = { Xmult = 1.5 } },
	loc_vars = function(self, info_queue, card)
		return {
			key = self.key .. "_mp_sandbox",
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
})

MP.ReworkCenter({
	key = "j_constellation",
	ruleset = "sandbox",
	config = { extra = { Xmult = 1, Xmult_gain = 0.2, Xmult_loss = 0.1 } },
	loc_vars = function(self, info_queue, card)
		return {
			key = self.key .. "_mp_sandbox",
			vars = { card.ability.extra.Xmult },
		}
	end,
	calculate = function(self, card, context)
		-- Gain mult when planet card is used
		if context.using_consumeable and not context.blueprint and context.consumeable.ability.set == "Planet" then
			card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_gain
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
			card.ability.extra.Xmult = math.max(0.1, card.ability.extra.Xmult - card.ability.extra.Xmult_loss)
			return {
				message = localize("k_reset"),
			}
		end
	end,
})

MP.ReworkCenter({
	key = "j_bloodstone",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_reserved_parking",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_egg",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_chaos",
	ruleset = "sandbox",
	config = { extra = { rerolls = 9999 } },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
	add_to_deck = function(self, card, from_debuff)
		SMODS.change_free_rerolls(card.ability.extra.rerolls)
	end,
	remove_from_deck = function(self, card, from_debuff)
		SMODS.change_free_rerolls(-card.ability.extra.rerolls)
	end,
})

MP.ReworkCenter({
	key = "j_turtle_bean",
	ruleset = "sandbox",
	config = { extra = { rounds = 5 } },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.rounds } }
	end,
})

MP.ReworkCenter({
	key = "j_juggler",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_mail",
	ruleset = "sandbox",
	config = { extra = { discards = 0 } },
	loc_vars = function(self, info_queue, card)
		return {
			key = self.key .. "_mp_sandbox",
			vars = {
				card.ability.extra.discards,
				(localize((G.GAME.current_round.mail_card or {}).rank or "Ace", "ranks")) .. "s",
			},
		}
	end,
})

MP.ReworkCenter({
	key = "j_hit_the_road",
	ruleset = "sandbox",
	config = { extra = { xmult_gain = 0.5, xmult = 1 } },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.xmult_gain, card.ability.extra.xmult } }
	end,
})

MP.ReworkCenter({
	key = "j_red_card",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_misprint",
	ruleset = "sandbox",
	config = { extra = { max = 46, min = -5, mult = 0 } },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.mult } }
	end,
	add_to_deck = function(self, card, from_debuff)
		card.ability.extra.mult = pseudorandom("misprint_sandbox", card.ability.extra.min, card.ability.extra.max) -- TODO replace with steamodded pseudorandom
	end,
	calculate = function(self, card, context)
		if context.joker_main then return {
			mult = card.ability.extra.mult,
		} end
	end,
})

MP.ReworkCenter({
	key = "j_castle",
	ruleset = "sandbox",
	config = { extra = { chips = 0, suit = "Diamonds" } },
	loc_vars = function(self, info_queue, card)
		local suit = (G.GAME.current_round.castle_card or {}).suit or "Diamonds"
		return {
			key = self.key .. "_mp_sandbox",
			vars = {
				card.ability.extra.chips,
				colours = { G.C.SUITS[suit] },
			},
		}
	end,
})

MP.ReworkCenter({
	key = "j_business",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_runner",
	ruleset = "sandbox",
	config = { extra = { chips = 0, chip_mod = 50 } },
	loc_vars = function(self, info_queue, card)
		return {
			key = self.key .. "_mp_sandbox",
			vars = { (card.ability.extra.chips / card.ability.extra.chip_mod) or 0 },
		}
	end,
})

MP.ReworkCenter({
	key = "j_delayed_grat",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_ride_the_bus",
	ruleset = "sandbox",
	config = { extra = { mult_gain = 5, mult = 0 } },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.mult_gain, card.ability.extra.mult } }
	end,
})

MP.ReworkCenter({
	key = "j_golden",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_loyalty_card",
	ruleset = "sandbox",
	config = { extra = { Xmult = 6, every = 4, loyalty_remaining = 4, poker_hand = "High Card" } },
	loc_vars = function(self, info_queue, card)
		return {
			key = self.key .. "_mp_sandbox",
			vars = {
				localize(card.ability.extra.poker_hand, "poker_hands"),
				card.ability.extra.Xmult,
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
})

MP.ReworkCenter({
	key = "j_scary_face",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_faceless",
	ruleset = "sandbox",
	config = { extra = { dollars = 20, faces = 9 } },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox" }
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
})

MP.ReworkCenter({
	key = "j_flash",
	ruleset = "sandbox",
	config = { extra = { mult_gain = 10, mult = 0, reroll_cost = 10 } },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.mult_gain, card.ability.extra.mult } }
	end,
	add_to_deck = function(self, card, from_debuff)
		print("TODO 10 reroll cost")
		-- SMODS.change_free_rerolls(card.ability.extra.rerolls)
	end,
	remove_from_deck = function(self, card, from_debuff)
		print("TODO 10 now reroll cost should disappear")
		-- SMODS.change_free_rerolls(-card.ability.extra.rerolls)
	end,
	-- calculate = function(self, card, context)
	-- 	if context.reroll_shop and not context.blueprint then
	-- 		card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_gain
	-- 		return {
	-- 			message = localize({ type = "variable", key = "a_mult", vars = { card.ability.extra.mult } }),
	-- 			colour = G.C.MULT,
	-- 		}
	-- 	end
	-- 	if context.joker_main then return {
	-- 		mult = card.ability.extra.mult,
	-- 	} end
	-- end,
})

MP.ReworkCenter({
	key = "j_photograph",
	ruleset = "sandbox",
	config = { extra = 5 },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra } }
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play and context.other_card:is_face() then
			local is_first_face = false
			if context.scoring_hand[1]:is_face() then is_first_face = true end
			if #context.full_hand == 1 and is_first_face then return {
				xmult = card.ability.extra,
			} end
		end
		return nil, true
	end,
})

MP.ReworkCenter({
	key = "j_throwback",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

MP.ReworkCenter({
	key = "j_gros_michel",
	ruleset = "sandbox",
	config = { extra = {} },
	loc_vars = function(self, info_queue, card)
		return { key = self.key .. "_mp_sandbox", vars = {} }
	end,
})

-- Global state for persistent bias across bloodstone calls
if not MP.bloodstone_bias then
	MP.starting_bloodstone_bias = 0.2
	MP.bloodstone_bias = MP.starting_bloodstone_bias
end

-- your rng complaints have been noted and filed accordingly
function cope_and_seethe_check(actual_odds)
	if actual_odds >= 1 then return true end

	-- how much easier (30%) do we make it for each successive roll?
	local step = -0.3
	local roll = pseudorandom("bloodstone") + MP.bloodstone_bias

	if roll < actual_odds then
		MP.bloodstone_bias = MP.starting_bloodstone_bias
		return true
	else
		MP.bloodstone_bias = MP.bloodstone_bias + step
		return false
	end
end

SMODS.Joker({
	key = "bloodstone2",
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 3,
	cost = 7,
	pos = { x = 0, y = 8 },
	no_collection = true,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
	config = { extra = { odds = 2, Xmult = 1.5 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				"" .. (G.GAME and G.GAME.probabilities.normal or 1),
				card.ability.extra.odds,
				card.ability.extra.Xmult,
			},
		}
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.play and context.individual then
			if context.other_card:is_suit("Hearts") then
				local bloodstone_hit = cope_and_seethe_check(G.GAME.probabilities.normal / card.ability.extra.odds)
				if bloodstone_hit then
					return {
						extra = { x_mult = card.ability.extra.Xmult },
						message = G.GAME.probabilities.normal < 2 and "Cope!" or nil,
						sound = "voice2",
						volume = 0.3,
						card = card,
					}
				end
			end
		end
	end,
})

SMODS.Joker({
	key = "cloud_9",
	no_collection = true,
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
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
	calc_dollar_bonus = function(self, card)
		local nine_tally = 0
		for k, v in pairs(G.playing_cards) do
			if v:get_id() == 9 then nine_tally = nine_tally + 1 end
		end
		return (math.min(nine_tally, 4) + math.max(nine_tally - 4, 0) * card.ability.extra) or 0
	end,
})

SMODS.Atlas({
	key = "sandbox_rare",
	path = "tag_rare.png",
	px = 32,
	py = 32,
})

-- Tag: 1 in 2 chance to generate a rare joker in shop
SMODS.Tag({
	key = "sandbox_rare",
	atlas = "sandbox_rare",
	object_type = "Tag",
	dependencies = {
		items = {},
	},
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
	name = "Rare Tag",
	discovered = true,
	order = 2,
	min_ante = 2, -- less degeneracy
	no_collection = true,
	config = {
		type = "store_joker_create",
		odds = 2,
	},
	requires = "j_blueprint",
	loc_vars = function(self)
		return { vars = { G.GAME.probabilities.normal or 1, self.config.odds } }
	end,
	apply = function(self, tag, context)
		if context.type == "store_joker_create" then
			local card = nil
			-- 1 in 2 chance to proc
			if pseudorandom("tagroll") < G.GAME.probabilities.normal / tag.config.odds then
				-- count owned rare jokers to prevent duplicates
				local rares_owned = { 0 }
				for k, v in ipairs(G.jokers.cards) do
					if v.config.center.rarity == 3 and not rares_owned[v.config.center.key] then
						rares_owned[1] = rares_owned[1] + 1
						rares_owned[v.config.center.key] = true
					end
				end

				-- only proc if unowned rares exist
				-- funny edge case that i've never seen happen, but if localthunk saw it i will obey
				if #G.P_JOKER_RARITY_POOLS[3] > rares_owned[1] then
					card = create_card("Joker", context.area, nil, 1, nil, nil, nil, "rta")
					create_shop_card_ui(card, "Joker", context.area)
					card.states.visible = false
					tag:yep("+", G.C.RED, function()
						card:start_materialize()
						card.ability.couponed = true -- free card
						card:set_cost()
						return true
					end)
				else
					tag:nope() -- all rares owned
				end
			else
				tag:nope() -- failed roll
			end
			tag.triggered = true
			return card
		end
	end,
})

-- Standard pack card creation for sandbox ruleset
-- Skips glass enhancement (excluded from enhancement pool)
-- 40% chance (0.6 threshold) for any enhancement to be applied (like vanilla)
-- function sandbox_create_card(self, card, i)
-- 	local enhancement_pool = {}

-- 	-- Skip glass
-- 	for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
-- 		if v.key ~= "m_glass" then
-- 			enhancement_pool[#enhancement_pool + 1] = v.key
-- 		end
-- 	end

-- 	local ante_rng = MP.ante_based()
-- 	local roll = pseudorandom(pseudoseed("stdc1" .. ante_rng))
-- 	local enhancement = roll > 0.6 and pseudorandom_element(enhancement_pool, pseudoseed("stdc2" .. ante_rng)) or nil

-- 	local s_append = ""
-- 	local b_append = ante_rng .. s_append

-- 	local _edition = poll_edition("standard_edition" .. b_append, 2, true)
-- 	local _seal = SMODS.poll_seal({ mod = 10, key = "stdseal" .. ante_rng })

-- 	return {
-- 		set = "Base",
-- 		edition = _edition,
-- 		seal = _seal,
-- 		enhancement = enhancement,
-- 		area = G.pack_cards,
-- 		skip_materialize = true,
-- 		soulable = true,
-- 		key_append = "sta" .. s_append,
-- 	}
-- end

-- for k, v in ipairs(G.P_CENTER_POOLS.Booster) do
-- 	if v.kind and v.kind == "Standard" then
-- 		MP.ReworkCenter({
-- 			key = v.key,
-- 			ruleset = "sandbox",
-- 			silent = true,
-- 			create_card = sandbox_create_card,
-- 		})
-- 	end
-- end
