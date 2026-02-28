-- Extra Credit Utilities Module
-- Shared utility functions for Extra Credit jokers ported to Sandbox
-- This file is prefixed with underscore to ensure it loads before the joker files

MP.EC = MP.EC or {}

-- Talisman Compatibility wrapper
to_big = to_big or function(x)
	return x
end
to_number = to_number or function(x)
	return x
end

--- Resets Tuxedo joker's selected suit for the round
--- Randomly selects a suit different from the current one
local function reset_tuxedo_card()
	local tuxedo_suits = {}
	G.GAME.current_round.tuxedo_card = G.GAME.current_round.tuxedo_card or {}
	for k, suit in pairs(SMODS.Suits) do
		if
			k ~= G.GAME.current_round.tuxedo_card.suit
			and (type(suit.in_pool) ~= "function" or suit:in_pool({ rank = "" }))
		then
			tuxedo_suits[#tuxedo_suits + 1] = k
		end
	end
	local seed = "tux"

	local tuxedo_card = pseudorandom_element(tuxedo_suits, pseudoseed(seed))
	G.GAME.current_round.tuxedo_card.suit = tuxedo_card
end

--- Resets Farmer joker's selected suit for the round
--- Randomly selects a suit different from the current one
local function reset_farmer_card()
	local farmer_suits = {}
	G.GAME.current_round.farmer_card = G.GAME.current_round.farmer_card or {}
	for k, suit in pairs(SMODS.Suits) do
		if
			k ~= G.GAME.current_round.farmer_card.suit
			and (type(suit.in_pool) ~= "function" or suit:in_pool({ rank = "" }))
		then
			farmer_suits[#farmer_suits + 1] = k
		end
	end

	local seed = "farm"

	local farmer_card = pseudorandom_element(farmer_suits, pseudoseed(seed))
	G.GAME.current_round.farmer_card.suit = farmer_card
end

--- Resets Go Fish joker's selected rank for the round
--- Randomly selects a rank different from the current one
local function reset_fish_rank()
	local valid_fish_ranks = {}
	G.GAME.current_round.fish_rank = G.GAME.current_round.fish_rank or {}
	for k, rank in pairs(SMODS.Ranks) do
		if
			k ~= G.GAME.current_round.fish_rank.rank
			and (type(rank.in_pool) ~= "function" or rank:in_pool({ suit = "" }))
		then
			valid_fish_ranks[#valid_fish_ranks + 1] = k
		end
	end

	local seed = "fish"

	local fish_pick = pseudorandom_element(valid_fish_ranks, pseudoseed(seed))
	G.GAME.current_round.fish_rank.rank = fish_pick
end

--- Hook into game globals reset to initialize EC round state
--- Called at start of each round
local original_reset_game_globals = MP.reset_game_globals
MP.reset_game_globals = function(run_start)
	if original_reset_game_globals then original_reset_game_globals(run_start) end

	-- Only initialize EC state when sandbox ruleset is active
	if MP.is_ruleset_active("sandbox") then
		reset_tuxedo_card()
		reset_farmer_card()
		reset_fish_rank()
	end
end

-- EC_ease_dollars context hook for Hoarder joker
-- Wraps ease_dollars to trigger joker evaluation with EC_ease_dollars context
-- (i.e. send a callback to Hoarder each time we earn money)
local original_ease_dollars = ease_dollars
function ease_dollars(mod, x)
	original_ease_dollars(mod, x)

	if MP.is_ruleset_active("sandbox") and G.jokers and G.jokers.cards then
		for i = 1, #G.jokers.cards do
			eval_card(G.jokers.cards[i], { EC_ease_dollars = to_big(mod) })
		end
	end
end
