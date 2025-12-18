SMODS.Atlas({
	key = "ec_other_sandbox",
	path = "ec_other_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Back({ --Echo Deck
	name = "Echo Deck",
	key = "echodeck",
	loc_txt = {
		name = "Echo Deck",
		text = {
			"{C:attention}Retrigger{} all playing cards",
			"{C:red}X1.2{} base Blind size",
			"Increases by {C:red}X0.2{} each Ante",
		},
	},
	order = 18,
	unlocked = true,
	discovered = true,
	config = {},
	loc_vars = function(self, info_queue, center)
		return { vars = {} }
	end,
	pos = { x = 2, y = 0 },
	atlas = "ec_other_sandbox",
	apply = function(self, back)
		G.GAME.starting_params.ante_scaling = 1.2
	end,

	calculate = function(self, back, context)
		if context.cardarea == G.play and context.repetition then
			return {
				message = localize("k_again_ex"),
				repetitions = 1,
				card = card,
			}
		elseif context.repetition and context.cardarea == G.hand then
			if next(context.card_effects[1]) or #context.card_effects > 1 then
				return {
					message = localize("k_again_ex"),
					repetitions = 1,
					card = card,
				}
			end
		end

		if context.end_of_round and not context.repetition and not context.individual and G.GAME.blind.boss then
			G.GAME.starting_params.ante_scaling = G.GAME.starting_params.ante_scaling + 0.2
		end
	end,
})
