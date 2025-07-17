MP.Ruleset({
	key = "standard",
	multiplayer_content = true,
	banned_jokers = {},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds ={},

	reworked_jokers = {
		"j_hanging_chad",
		"j_mp_conjoined_joker",
		"j_mp_defensive_joker",
		"j_mp_lets_go_gambling",
		--"j_mp_magnet",
		"j_mp_pacifist",
		"j_mp_penny_pincher",
		"j_mp_pizza",
		"j_mp_skip_off",
		"j_mp_speedrun",
		"j_mp_taxes",
	},
	reworked_consumables = {
		"c_mp_asteroid"
	},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass"
	},
	reworked_tags = {},
	reworked_blinds = {
		"bl_mp_nemesis"
	},
}):inject()

SMODS.Joker:take_ownership("hanging_chad", {
	loc_vars = function(self, info_queue, card) -- This is dumb but there's no original loc_vars to override, if i knew how to fix that i would
		return { vars = { card.ability.extra } }
	end,
}, true)


-- This is the example for defining a center rework
MP.ReworkCenter({
	key = "j_hanging_chad", -- Required, format is how it appears in G.P_CENTERS (prefixes are required)
	ruleset = "standard", -- Required, format is the same as the ruleset key
	config = { extra = 1 }, -- We can add whatever value in the center we want to override, here we're changing the config
	loc_vars = function(self, info_queue, card) -- We will need to return a modified localization key here due to the effect change
		return {
			key = self.key.."_mp_standard",
			vars = { card.ability.extra } 
		}
	end,
	calculate = function(self, card, context) -- This overrides the calculate, same format as SMODS.Joker
		if context.cardarea == G.play and context.repetition then
			if context.other_card == context.scoring_hand[1] 
			or context.other_card == context.scoring_hand[2] then
				return {
					message = localize("k_again_ex"),
					repetitions = card.ability.extra,
					card = card,
				}
			end
		end
	end,
})

-- Using this, we can rework everything in G.P_CENTERS, so let's rework glass too
MP.ReworkCenter({
	key = "m_glass",
	ruleset = "standard",
	config = { Xmult = 1.5, extra = 4 }, -- Couldn't be simpler
})
