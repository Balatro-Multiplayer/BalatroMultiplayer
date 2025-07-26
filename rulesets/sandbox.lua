MP.Ruleset({
	key = "sandbox",
	multiplayer_content = true,
	banned_jokers = {
		"j_cloud_9",
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
		"j_mp_bloodstone",
		"j_hanging_chad",
		"j_idol",
		"j_square",
		"j_mp_conjoined_joker",
		"j_mp_defensive_joker",
		-- "j_mp_magnet", -- can't decide if we want this or not
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
	reworked_blinds = {
		"bl_mp_nemesis",
	},
	reworked_tags = { "tag_mp_sandbox_rare" },

	is_disabled = function(self)
		if not MP.INTEGRATIONS.TheOrder then
			return localize("k_ruleset_disabled_the_order_required")
		end
		return false
	end,

	-- todo this would be sick
	overrides = function()
		print("Override for sandbox called")
	end,
}):inject()

MP.ReworkCenter({
	key = "j_square",
	ruleset = "sandbox",
	config = { extra = { chips = 64, chip_mod = 4 } },
})

MP.ReworkCenter({
	key = "j_idol",
	ruleset = "sandbox",
	rarity = 3,
	cost = 8,
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

-- TODO I don't want to do this right now as I don't want to do loc_vars magic to get it to work
-- MP.ReworkCenter({
-- 	key = "j_bloodstone",
-- 	rarity = 3,
-- 	calculate = function(self, card, context)
-- 		if context.cardarea == G.play and context.individual then
-- 			if context.other_card:is_suit("Hearts") then
-- 				local bloodstone_hit = cope_and_seethe_check(G.GAME.probabilities.normal / card.ability.extra.odds)
-- 				if bloodstone_hit then
-- 					return {
-- 						extra = { x_mult = card.ability.extra.Xmult },
-- 						message = G.GAME.probabilities.normal < 2 and "Cope!" or nil,
-- 						sound = "voice2",
-- 						volume = 0.3,
-- 						card = card,
-- 					}
-- 				end
-- 			end
-- 		end
-- 	end,
-- })

SMODS.Joker({
	key = "bloodstone",
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
	-- NOTE: Shouldn't need to tally this twice but here we are!
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
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
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
	-- pos = { x = 1, y = 0 },
	object_type = "Tag",
	dependencies = {
		items = {},
	},
	-- in_pool = function(self)
	-- 	return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	-- end,
	name = "Rare Tag",
	discovered = true,
	order = 2,
	min_ante = 2, -- less degeneracy
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
