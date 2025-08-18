--[[ doesn't work yet

SMODS.Back({
	key = "cocktail",
	config = {},
	atlas = "mp_decks",
	pos = {x = 4, y = 0},
	apply = function(self)
		-- we need to fucking generate the seed early this is infuriating
		local seed = G._MP_SET_SEED
		local seeded = false
		if seed then seeded = true end
		G.GAME.pseudorandom.seed = seed or generate_starting_seed()
		G.GAME.modifiers.mp_cocktail = {}
		local decks = {}
		for k, v in pairs(G.P_CENTERS) do
			if v.set == 'Back'
			and k ~= "b_challenge"
			and k ~= "b_mp_cocktail" then
				decks[#decks+1] = k
			end
		end
		pseudoshuffle(decks, pseudoseed('mp_cocktail'))
		for i = 1, 3 do
			G.GAME.modifiers.mp_cocktail[i] = decks[i]
			print(decks[i])
		end
		if not seeded then
			G.E_MANAGER:add_event(Event({
				func = (function()
					G.GAME.seeded = nil
					return true
				end)
			}))
		end
	end,
	calculate = function(self, back, context)
		for i = 1, 3 do
			G.GAME.selected_back:change_to(G.P_CENTERS[G.GAME.modifiers.mp_cocktail[i]])
			local ret1, ret2 = G.GAME.selected_back:trigger_effect(context)
			G.GAME.selected_back:change_to(G.P_CENTERS["b_mp_cocktail"])
			return ret1, ret2
		end
	end,
})

]]