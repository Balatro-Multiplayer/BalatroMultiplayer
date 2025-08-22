SMODS.Back({
	key = "cocktail",
	config = {},
	atlas = "mp_decks",
	pos = { x = 4, y = 0 },
	mod_whitelist = {
		Multiplayer = true,
	},
	apply = function(self)
		-- we need to fucking generate the seed early this is infuriating
		local seed = G._MP_SET_SEED
		local seeded = false
		if seed then seeded = true end
		G.GAME.pseudorandom.seed = seed or generate_starting_seed()
		G.GAME.modifiers.mp_cocktail = {}
		local decks = {}
		for k, v in pairs(G.P_CENTERS) do
			if v.set == "Back" and k ~= "b_challenge" and k ~= "b_mp_cocktail" then
				if not (v.mod and not self.mod_whitelist[v.mod.id]) then decks[#decks + 1] = k end
			end
		end
		pseudoshuffle(decks, pseudoseed("mp_cocktail"))
		local back = G.GAME.selected_back
		for i = 1, 3 do
			G.GAME.modifiers.mp_cocktail[i] = decks[i]
			if decks[i] == "b_checkered" then -- hardcoded because cringe
				G.E_MANAGER:add_event(Event({
					func = function()
						for k, v in pairs(G.playing_cards) do
							if v.base.suit == "Clubs" then v:change_suit("Spades") end
							if v.base.suit == "Diamonds" then v:change_suit("Hearts") end
						end
						return true
					end,
				}))
			end
		end
		local function merge(t1, t2, safe)
			local t3 = {}
			for k, v in pairs(t1) do
				if type(v) == "table" then
					t3[k] = merge(v, {})
				else
					t3[k] = v
				end
			end
			for k, v in pairs(t2) do
				local existing = t3[k]

				if type(existing) == "number" and type(v) == "number" then
					t3[k] = existing + v
				elseif type(existing) == "table" and type(v) == "table" then
					t3[k] = merge(existing, v, true) -- risky but it works...
				else
					if type(v) == "table" then
						t3[k] = merge(v, {})
					else
						local index = safe and #t3 + 1 or k
						t3[index] = v
					end
				end
			end
			return t3
		end
		for i = 1, 3 do
			back.effect.config = merge(back.effect.config, G.P_CENTERS[G.GAME.modifiers.mp_cocktail[i]].config)
			if back.effect.config.voucher then
				back.effect.config.vouchers = back.effect.config.vouchers or {}
				back.effect.config.vouchers[#back.effect.config.vouchers + 1] = back.effect.config.voucher
				back.effect.config.voucher = nil
			end
			local obj = G.P_CENTERS[G.GAME.modifiers.mp_cocktail[i]]
			if obj.apply and type(obj.apply) == "function" then obj:apply(back) end
		end
		if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" then
			MP.apply_fake_back_vouchers(back)
		end
		back.effect.mp_cocktailed = true
		if not seeded then
			G.E_MANAGER:add_event(Event({
				func = function()
					G.GAME.seeded = nil
					return true
				end,
			}))
		end
	end,
	calculate = function(self, back, context)
		for i = 1, 3 do
			back:change_to(G.P_CENTERS[G.GAME.modifiers.mp_cocktail[i]])
			local ret1, ret2 = back:trigger_effect(context)
			back:change_to(G.P_CENTERS["b_mp_cocktail"])
			if ret1 or ret2 then return ret1, ret2 end
		end
	end,
})

local change_to_ref = Back.change_to
function Back:change_to(new_back)
	if self.effect.mp_cocktailed then
		local t = copy_table(self.effect.config)
		local ret = change_to_ref(self, new_back)
		self.effect.config = copy_table(t)
		self.effect.mp_cocktailed = true
		return ret
	end
	return change_to_ref(self, new_back)
end
