SMODS.Challenge({
	key = "c_multiplayer_1",
	loc_txt = {
		name = mp_localize("multiplayer_c", "Multiplayer Deck"),
	},
	rules = {
		custom = {},
		modifiers = {},
	},
	jokers = {},
	consumeables = {},
	vouchers = {},
	restrictions = {
		banned_cards = {
			{ id = "j_diet_cola" },
			{ id = "j_mr_bones" },
			{ id = "j_throwback" },
			{ id = "j_luchador" },
			{ id = "j_matador" },
			{ id = "j_chicot" },
			{ id = "v_hieroglyph" },
			{ id = "v_petroglyph" },
		},
		banned_tags = {},
		banned_other = {},
	},
	deck = {
		type = "Challenge Deck",
	},
	unlocked = function(self)
		return false
	end,
})

--local set_discover_tallies_ref = set_discover_tallies
--function set_discover_tallies()
--	G.CHALLENGES[c_multiplayer_1_index] = nil
--	local res = set_discover_tallies_ref()
--	G.CHALLENGES[c_multiplayer_1_index] = c_multiplayer_1
--	return res
--end
--
--local challenge_list_ref = G.FUNCS.challenge_list
--G.FUNCS.challenge_list = function(e)
--	G.CHALLENGES[c_multiplayer_1_index] = nil
--	challenge_list_ref(e)
--	G.CHALLENGES[c_multiplayer_1_index] = c_multiplayer_1
--end
--
--local challenges_ref = G.UIDEF.challenges
--function G.UIDEF.challenges(from_game_over)
--	G.CHALLENGES[c_multiplayer_1_index] = nil
--	local res = challenges_ref(from_game_over)
--	G.CHALLENGES[c_multiplayer_1_index] = c_multiplayer_1
--	return res
--end
