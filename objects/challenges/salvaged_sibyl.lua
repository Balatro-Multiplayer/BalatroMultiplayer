SMODS.Challenge({
	key = "salvaged_sibyl",
	rules = {
		custom = {
			{ id = "mp_no_shop_planets" },
			{ id = "mp_only_medium" },
			{ id = "mp_only_purple_seals" },
			{ id = "mp_sibyl_CREDITS" },
		},
	},
	consumeables = {
		{ id = "c_medium" },
	},
	restrictions = {
		banned_cards = {
			{ id = "j_constellation" },
			{ id = "j_satellite" },
			{ id = "j_astronomer" },
			{ id = "c_high_priestess" },
			{ id = "v_planet_merchant", ids = { "v_planet_tycoon" } },
			{ id = "v_telescope", ids = { "v_observatory" } },
			{ id = "v_magic_trick", ids = { "v_illusion" } },
			{
				id = "p_celestial_normal_1",
				ids = {
					"p_celestial_normal_2",
					"p_celestial_normal_3",
					"p_celestial_normal_4",
					"p_celestial_jumbo_1",
					"p_celestial_jumbo_2",
					"p_celestial_mega_1",
					"p_celestial_mega_2",
				},
			},
			{
				id = "p_spectral_normal_1",
				ids = {
					"p_spectral_normal_2",
					"p_spectral_jumbo_1",
					"p_spectral_mega_1",
				},
			},
			{
				id = "p_standard_normal_1",
				ids = {
					"p_standard_normal_2",
					"p_standard_normal_3",
					"p_standard_normal_4",
					"p_standard_jumbo_1",
					"p_standard_jumbo_2",
					"p_standard_mega_1",
					"p_standard_mega_2",
				},
			},
		},
	},
	apply = function(self)
		G.GAME.selected_back.atlas = "mp_decks"
		G.GAME.selected_back.pos = { x = 3, y = 0 }
		G.GAME.planet_rate = 0
	end,
	unlocked = function(self)
		return true
	end,
})

-- billionth create card hook ever
local create_card_ref = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
	if G.GAME.modifiers.mp_only_medium and _type == "Spectral" then
		G.GAME.banned_keys["c_medium"] = nil
		forced_key = "c_medium"
	end
	return create_card_ref(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
end

local set_seal_ref = Card.set_seal
function Card:set_seal(_seal, silent, immediate)
	if G.GAME.modifiers.mp_only_purple_seals and _seal then _seal = "Purple" end
	return set_seal_ref(self, _seal, silent, immediate)
end
