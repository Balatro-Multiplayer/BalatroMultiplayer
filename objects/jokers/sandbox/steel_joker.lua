SMODS.Joker({
	key = "steel_joker_sandbox",
	blueprint_compat = true,
	rarity = 2,
	cost = 7,
	pos = { x = 7, y = 2 },
	config = { extra = { repetitions = 1 } },
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.m_steel
	end,
	calculate = function(self, card, context)
		if
			context.repetition
			and context.cardarea == G.play
			and SMODS.has_enhancement(context.other_card, "m_steel")
		then
			return {
				repetitions = card.ability.extra.repetitions,
			}
		end
	end,
	in_pool = function(self)
		 if not (MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code) return false end;
		for _, playing_card in ipairs(G.playing_cards or {}) do
			if SMODS.has_enhancement(playing_card, "m_steel") then return true end
		end
		return false
	end,
})
