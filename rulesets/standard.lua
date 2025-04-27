MP.Ruleset({
	key = "standard",
	multiplayer_content = true,
	banned_jokers = {
		"j_hanging_chad",
	},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},

	reworked_jokers = {
		"j_mp_hanging_chad",
		"j_mp_conjoined_joker",
		"j_mp_defensive_joker",
		"j_mp_lets_go_gambling",
		"j_mp_magnet",
		"j_mp_pacifist",
		"j_mp_penny_pincher",
		"j_mp_pizza",
		"j_mp_skip_off",
		"j_mp_speedrun",
		"j_mp_taxes",
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass"
	},
	reworked_tags = {},
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
		return MP.LOBBY.config.ruleset == "ruleset_mp_standard" and MP.LOBBY.code
	end,
})

SMODS.Enhancement:take_ownership("glass", {
	set_ability = function(self, card, initial, delay_sprites)
		local x = MP.LOBBY.config.ruleset == "ruleset_mp_standard" and (MP.LOBBY.code or MP.LOBBY.ruleset_preview) and 1.5 or 2
		-- Xmult is display, x_mult is internal. don't ask why, i don't know
		card.ability.Xmult = x
		card.ability.x_mult = x
	end,
}, true)
