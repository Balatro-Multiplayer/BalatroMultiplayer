SMODS.Joker:take_ownership("hanging_chad", {
	loc_vars = function(self, info_queue, card) -- This is dumb but there's no original loc_vars to override, if i knew how to fix that i would
		return { vars = { card.ability.extra } }
	end,
}, true)

-- This is the example for defining a center rework
MP.ReworkCenter({
	key = "j_hanging_chad", -- Required, format is how it appears in G.P_CENTERS (prefixes are required)
	ruleset = MP.UTILS.get_standard_rulesets(), -- Required, list of strings, string format is the same as the ruleset key
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