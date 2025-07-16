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
		return (MP.LOBBY.config.ruleset == "ruleset_mp_blitz" or MP.LOBBY.config.ruleset == "ruleset_mp_ranked" or MP.LOBBY.config.ruleset == "ruleset_mp_traditional") and MP.LOBBY.code
	end,
})