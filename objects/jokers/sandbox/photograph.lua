SMODS.Atlas({
	key = "photograph_sandbox",
	path = "j_photograph_sandbox.png",
	px = 71,
	py = 95,
})
SMODS.Joker({
	key = "photograph_sandbox",
	blueprint_compat = true,
	atlas = "photograph_sandbox",
	rarity = 1,
	cost = 5,
	pixel_size = { h = 95 / 1.2 },
	config = { extra = { xmult = 5 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult } }
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play and context.other_card:is_face() then
			local is_first_face = false
			if context.scoring_hand[1]:is_face() then is_first_face = true end
			if #context.full_hand == 1 and is_first_face then return {
				xmult = card.ability.extra.xmult,
			} end
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})

SMODS.Joker({
	key = "photograph_2_sandbox",
	blueprint_compat = true,
	atlas = "photograph_sandbox",
	rarity = 2,
	cost = 7,
	pixel_size = { h = 95 / 1.2 },
	config = { extra = { xmult = 8 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult } }
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play and context.other_card:is_face() then
			local is_first_face = false
			for i = 1, #context.scoring_hand do
				if context.scoring_hand[i]:is_face() then
					is_first_face = context.scoring_hand[i] == context.other_card
					break
				end
			end
			if is_first_face then
				card:remove_from_deck()
				card:start_dissolve({ G.C.RED }, nil, 1.6)
				return {
					xmult = card.ability.extra.xmult,
				}
			end
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
