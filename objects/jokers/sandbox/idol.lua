SMODS.Atlas({
	key = "idol_sandbox",
	path = "j_idol_sandbox_color.png",
	px = 71,
	py = 95,
})
SMODS.Joker({
	key = "idol_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	rarity = 2,
	cost = 6,
	atlas = "idol_sandbox",
	config = { extra = { xmult = 1.5 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		local idol_card = G.GAME.current_round.idol_card or { rank = "Ace" }
		return {
			vars = {
				localize(idol_card.rank, "ranks"),
				card.ability.extra.xmult,
			},
		}
	end,
	calculate = function(self, card, context)
		if
			context.individual
			and context.cardarea == G.play
			and context.other_card:get_id() == G.GAME.current_round.idol_card.id
		then
			return {
				xmult = card.ability.extra.xmult,
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
