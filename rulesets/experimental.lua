-- TODO fix weird crash in ruleset overview
-- TODO maybe function in MP.Ruleset that defines the functions we call afterwards etc

MP.Ruleset({
	key = "experimental",
	multiplayer_content = true,
	banned_jokers = {
		"j_hanging_chad",
		"j_idol",
		"j_cloud_9",
		-- "j_delayed_grat",
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
		"j_mp_hanging_chad",
		"j_mp_idol",
		"j_mp_cloud_9",
		"j_mp_bloodstone",
		-- "j_mp_delayed_grat",
		"j_mp_conjoined_joker",
		"j_mp_defensive_joker",
		"j_mp_lets_go_gambling",
		"j_mp_pacifist",
		"j_mp_penny_pincher",
		"j_mp_pizza",
		"j_mp_skip_off",
		"j_mp_speedrun",
		"j_mp_taxes",
	},
	reworked_consumables = {
		"c_mp_asteroid",
	},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass",
	},
	reworked_tags = {},
	reworked_blinds = {
		"bl_mp_nemesis",
	},
}):inject()

SMODS.Joker({
	key = "hanging_chad",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 1,
	cost = 4,
	pos = { x = 9, y = 6 },
	config = { extra = 1, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = {
			card.ability.extra,
		} }
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.play and context.repetition then
			if context.other_card == context.scoring_hand[1] then
				return {
					message = localize("k_again_ex"),
					repetitions = card.ability.extra,
					card = card,
				}
			end
			if context.other_card == context.scoring_hand[2] then
				return {
					message = localize("k_again_ex"),
					repetitions = card.ability.extra,
					card = card,
				}
			end
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_experimental" and MP.LOBBY.code
	end,
})

-- j_idol=             {order = 127,  unlocked = false, discovered = false, blueprint_compat = true, perishable_compat = true, eternal_compat = true, rarity = 2, cost = 6, name = "The Idol", pos = {x=6,y=7}, set = "Joker", effect = "", config = {extra = 2}, unlock_condition = {type = 'chip_score', chips = 1000000}},
SMODS.Joker({
	key = "idol",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 3,
	cost = 8,
	pos = { x = 6, y = 7 },
	config = { extra = 2, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra,
				localize(G.GAME.current_round.idol_card.rank, "ranks"),
				localize(G.GAME.current_round.idol_card.suit, "suits_plural"),
				colours = { G.C.SUITS[G.GAME.current_round.idol_card.suit] },
			},
		}
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_experimental" and MP.LOBBY.code
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.play and context.individual then
			if
				context.other_card:get_id() == G.GAME.current_round.idol_card.id
				and context.other_card:is_suit(G.GAME.current_round.idol_card.suit)
			then
				return {
					x_mult = card.ability.extra,
					colour = G.C.RED,
				}
			end
		end
	end,
})

-- Global state for persistent bias across bloodstone calls
if not MP.bloodstone_bias then
	MP.starting_bloodstone_bias = 0.2
	MP.bloodstone_bias = MP.starting_bloodstone_bias
end

-- your rng complaints have been noted and filed accordingly
function cope_and_seethe_check(actual_odds)
	if actual_odds >= 1 then
		return true
	end

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
	key = "bloodstone",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 2,
	cost = 7,
	pos = { x = 0, y = 8 },
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
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_experimental" and MP.LOBBY.code
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.play and context.individual then
			if context.other_card:is_suit("Hearts") then
				local bloodstone_hit = cope_and_seethe_check(G.GAME.probabilities.normal / card.ability.extra.odds)
				if bloodstone_hit then
					return {
						extra = { x_mult = card.ability.extra.Xmult },
						message = "Cope!",
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
	-- todo not sure if we actually should need to tally nines twice
	loc_vars = function(self, info_queue, card)
		local nine_tally = 0
		if G.playing_cards ~= nil then
			for k, v in pairs(G.playing_cards) do
				if v:get_id() == 9 then
					nine_tally = nine_tally + 1
				end
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
		return MP.LOBBY.config.ruleset == "ruleset_mp_experimental" and MP.LOBBY.code
	end,
	calc_dollar_bonus = function(self, card)
		local nine_tally = 0
		for k, v in pairs(G.playing_cards) do
			if v:get_id() == 9 then
				nine_tally = nine_tally + 1
			end
		end
		return (math.min(nine_tally, 4) + math.max(nine_tally - 4, 0) * card.ability.extra) or 0
	end,
})

-- Tag: 1 in 2 chance to generate a rare joker in shop
-- Only triggers if player doesn't already own all available rares
SMODS.Tag({
	key = "sandbox_rare",
	object_type = "Tag",
	dependencies = {
		items = {},
	},
	-- in_pool = function(self)
	-- 	return MP.LOBBY.config.ruleset == "ruleset_mp_experimental" and MP.LOBBY.code
	-- end,
	pos = { x = 1, y = 0 },
	name = "Rare Tag",
	discovered = true,
	order = 2,
	min_ante = nil,
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
			-- 50% chance to proc
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

--
-- SMODS.Joker({
-- 	key = "delayed_grat",
-- 	no_collection = true,
-- 	unlocked = true,
-- 	discovered = true,
-- 	blueprint_compat = false,
-- 	perishable_compat = true,
-- 	eternal_compat = true,
-- 	rarity = 1,
-- 	cost = 4,
-- 	pos = { x = 4, y = 3 },
-- 	config = { extra = 3, mp_sticker_balanced = true },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { vars = {
-- 			card.ability.extra,
-- 		} }
-- 	end,
-- 	in_pool = function(self)
-- 		return MP.LOBBY.config.ruleset == "ruleset_mp_experimental" and MP.LOBBY.code
-- 	end,

-- 	calc_dollar_bonus = function(self, card)
-- 		if G.GAME.current_round.discards_used == 0 and G.GAME.current_round.discards_left > 0 then
-- 			return G.GAME.current_round.discards_left * card.ability.extra
-- 		end
-- 	end,
-- })

-- Overrides are now handled dynamically in _rulesets.lua via MP.apply_ruleset_overrides()
-- This ensures they are evaluated when the ruleset is selected, not at file load time
-- But they should probably be moved here if required
