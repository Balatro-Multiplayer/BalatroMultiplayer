SMODS.Challenge({
	key = "planet_tycoon",
	rules = {
		custom = {
			{ id = "mp_shop_planets" },
			{ id = "mp_shop_planets_EXTENDED" },
			{ id = "mp_planet_tycoon_CREDITS" },
		},
	},
	restrictions = {
		banned_cards = {
			{ id = "v_planet_merchant", ids = { "v_planet_tycoon" } },
		}
	},
	apply = function(self)
		G.GAME.planet_rate = 360
	end,
	unlocked = function(self)
		return true
	end,
})
