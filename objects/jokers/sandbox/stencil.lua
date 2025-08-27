SMODS.Joker({
	key = "stencil_sandbox",
	blueprint_compat = true,
	rarity = 2,
	cost = 8,
	pos = { x = 2, y = 5 },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				G.jokers and math.max(
					1.5,
					((G.jokers.config.card_limit - #G.jokers.cards) + #SMODS.find_card("j_stencil", true)) * 1.5
				) or 1.5,
			},
		}
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = math.max(
					1.5,
					((G.jokers.config.card_limit - #G.jokers.cards) + #SMODS.find_card("j_stencil", true)) * 1.5
				),
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

-- TODO test and verify!!
