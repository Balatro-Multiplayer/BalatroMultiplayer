SMODS.Atlas({
	key = "lets_go_gambling",
	path = "j_lets_go_gambling.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "lets_go_gambling",
	atlas = "lets_go_gambling",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { odds = 4, xmult = 4, dollars = 10, nemesis_odds = 4, nemesis_dollars = 10 } },
	loc_vars = function(self, info_queue, card)
		local numerator, denominator =
			SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "j_mp_lets_go_gambling")
		local nem_numerator, nem_denominator =
			SMODS.get_probability_vars(card, 1, card.ability.extra.nemesis_odds, "j_mp_lets_go_gambling_misfire")
		return {
			vars = {
				numerator,
				denominator,
				card.ability.extra.xmult,
				card.ability.extra.dollars,
				nem_numerator,
				nem_denominator,
				card.ability.extra.nemesis_dollars,
			},
		}
	end,
	mp_include = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	calculate = function(self, card, context)
		if
			context.cardarea == G.jokers
			and context.joker_main
			and (not card.edition or card.edition.type ~= "mp_phantom")
		then
			local returns = nil
			if SMODS.pseudorandom_probability(card, "j_mp_lets_go_gambling", 1, card.ability.extra.odds) then
				returns = {}
				returns.x_mult = card.ability.extra.xmult
				returns.dollars = card.ability.extra.dollars
			end
			if
				MP.is_pvp_boss()
				and SMODS.pseudorandom_probability(
					card,
					"j_mp_lets_go_gambling_misfire",
					1,
					card.ability.extra.nemesis_odds
				)
			then
				returns = returns or {}
				MP.ACTIONS.lets_go_gambling_nemesis()
				returns.message = localize("k_oops_ex")
			end
			return returns
		end
	end,
	add_to_deck = function(self, card, from_debuffed)
		if not from_debuffed and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.send_phantom("j_mp_lets_go_gambling")
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not from_debuff and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.remove_phantom("j_mp_lets_go_gambling")
		end
	end,
	mp_credits = {
		idea = { "Dr. Monty" },
		art = { "Carter" },
		code = { "Virtualized" },
	},
})
