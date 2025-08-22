SMODS.Back({
	key = "sibyl",
	config = { consumables = { "c_medium" } },
	atlas = "mp_decks",
	pos = { x = 3, y = 0 },
	apply = function(self)
		local spec_bans = {
			j_constellation = true,
			c_high_priestess = true,
			v_planet_merchant = true,
			v_planet_tycoon = true,
			v_telescope = true,
			v_observatory = true,
			v_magic_trick = true,
			v_illusion = true,
			tag_meteor = true,
			tag_standard = true,
			tag_ethereal = true,
		}
		for k, v in pairs(G.P_CENTERS) do
			local ban = false
			if spec_bans[k] then
				ban = true
			elseif v.set == "Booster" then
				if v.kind == "Celestial" or v.kind == "Standard" or v.kind == "Spectral" then ban = true end
			end
			if ban then G.GAME.banned_keys[k] = true end
		end
		for k, v in pairs(G.P_TAGS) do
			if spec_bans[k] then G.GAME.banned_keys[k] = true end
		end
		G.GAME.planet_rate = 0
		G.GAME.modifiers.mp_sibyl = true
	end,
})

-- billionth create card hook ever
local create_card_ref = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
	if G.GAME.modifiers.mp_sibyl and _type == "Spectral" then forced_key = "c_medium" end
	return create_card_ref(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
end
