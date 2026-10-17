-- Glass Cannon on Black Deck: -2 hands stacks with the deck's -1, so 1 hand.
local SEED = "GLASS01"

return {
	{
		wait = 2,
		run = function(S)
			MP.MODIFIERS = {}
			MP.add_modifier("glass_cannon")
			MP.SP.practice = true
			MP.SP.ruleset = "ruleset_mp_blitz"
			MP.LOBBY.config.ruleset = nil
			MP.LoadReworks("blitz")
			G.GAME.viewed_back = Back(G.P_CENTERS.b_black)
			G.FUNCS.start_run(nil, { seed = SEED, stake = 1 })
		end,
	},
	{
		wait = 1,
		until_ = function()
			return G.STATE == G.STATES.BLIND_SELECT and G.blind_select_opts and G.blind_select_opts.small
		end,
		timeout = 15,
		run = function(S)
			S.check(G.GAME.selected_back.name == "Black Deck", "on Black Deck")
			S.check(G.GAME.modifiers.mp_glass_cannon == true, "glass_cannon flag set")
			S.check(G.GAME.round_resets.hands == 1, "round_resets.hands == 1 (got " .. G.GAME.round_resets.hands .. ")")
			G.FUNCS.select_blind(G.blind_select_opts.small:get_UIE_by_ID("select_blind_button"))
		end,
	},
	{
		wait = 1,
		until_ = function()
			return G.STATE == G.STATES.SELECTING_HAND and G.hand and #G.hand.cards > 0
		end,
		timeout = 15,
		run = function(S)
			S.check(
				G.GAME.current_round.hands_left == 1,
				"hands_left == 1 in the blind (got " .. G.GAME.current_round.hands_left .. ")"
			)
			S.shot("small_blind")
		end,
	},
}
