----------------------------------------------
------------MOD DECK--------------------------

local c_multiplayer_1 = {
	name = "Multiplayer Deck",
	id = "c_multiplayer_1",
	rules = {
		custom = {},
		modifiers = {},
	},
	jokers = {},
	consumeables = {},
	vouchers = {},
	deck = {
		type = "Challenge Deck",
	},
	restrictions = {
		banned_cards = {
			{ id = "j_diet_cola" },
			{ id = "j_mr_bones" },
			{ id = "j_throwback" },
			{ id = "v_hieroglyph" },
			{ id = "v_petroglyph" },
		},
		banned_tags = {},
		banned_other = {},
	},
}

local c_multiplayer_1_index = #G.CHALLENGES + 1
G.CHALLENGES[c_multiplayer_1_index] = c_multiplayer_1

local localize_ref = localize
function localize(args, misc_cat)
	if args == "c_multiplayer_1" and misc_cat == "challenge_names" then
		return "Multiplayer"
	end
	return localize_ref(args, misc_cat)
end

local set_discover_tallies_ref = set_discover_tallies
function set_discover_tallies()
	G.CHALLENGES[c_multiplayer_1_index] = nil
	local res = set_discover_tallies_ref()
	G.CHALLENGES[c_multiplayer_1_index] = c_multiplayer_1
	return res
end

local challenge_list_ref = G.FUNCS.challenge_list
G.FUNCS.challenge_list = function(e)
	G.CHALLENGES[c_multiplayer_1_index] = nil
	challenge_list_ref(e)
	G.CHALLENGES[c_multiplayer_1_index] = c_multiplayer_1
end

local challenges_ref = G.UIDEF.challenges
function G.UIDEF.challenges(from_game_over)
	G.CHALLENGES[c_multiplayer_1_index] = nil
	local res = challenges_ref(from_game_over)
	G.CHALLENGES[c_multiplayer_1_index] = c_multiplayer_1
	return res
end

----------------------------------------------
------------MOD DECK END----------------------
