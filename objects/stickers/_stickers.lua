SMODS.Atlas({
	key = "alt_stickers",
	path = "alt_stickers.png",
	px = 71,
	py = 95,
})

local set_ability_ref = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
	set_ability_ref(self, center, initial, delay_sprites)
	for _, v in ipairs({ "persistent", "unreliable", "draining" }) do
		if G.GAME.modifiers and G.GAME.modifiers["mp_enable_" .. v .. "_jokers"] then
			SMODS.Stickers["mp_sticker_" .. v]:apply(self, center["mp_forced_" .. v])
		end
	end
end

-- big table for the alt stickers as they need specifications
local sticker_tables = {
	j_joker = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_greedy_joker = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_lusty_joker = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_wrathful_joker = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_gluttenous_joker = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_jolly = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_zany = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_mad = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_crazy = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_droll = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_sly = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_wily = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_clever = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_devious = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_crafty = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_half = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_stencil = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_four_fingers = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_mime = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_credit_card = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_ceremonial = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_banner = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_mystic_summit = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_marble = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_loyalty_card = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_8_ball = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_misprint = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_dusk = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_raised_fist = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_chaos = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_fibonacci = {
		persistent = true,
		unreliable = true,
		draining = false,
	},
	j_steel_joker = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_scary_face = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_abstract = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_delayed_grat = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_hack = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_pareidolia = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_gros_michel = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_even_steven = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_odd_todd = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_scholar = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_business = {
		persistent = false,
		unreliable = true,
		draining = true,
	},
	j_supernova = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_ride_the_bus = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_space = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_egg = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_burglar = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_blackboard = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_runner = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_ice_cream = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_dna = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_splash = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_blue_joker = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_sixth_sense = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_constellation = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_hiker = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_faceless = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_green_joker = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_superposition = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_todo_list = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_cavendish = {
		persistent = true,
		unreliable = true,
		draining = false,
	},
	j_card_sharp = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_red_card = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_madness = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_square = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_seance = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_riff_raff = {
		persistent = true,
		unreliable = false,
		draining = true,
	},
	j_vampire = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_shortcut = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_hologram = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_vagabond = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_baron = {
		persistent = true,
		unreliable = true,
		draining = false,
	},
	j_cloud_9 = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_rocket = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_obelisk = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_midas_mask = {
		persistent = true,
		unreliable = true,
		draining = true,
	},
	j_luchador = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_photograph = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_gift = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_turtle_bean = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_erosion = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_reserved_parking = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_mail = {
		persistent = true,
		unreliable = false,
		draining = true,
	},
	j_to_the_moon = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_hallucination = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_fortune_teller = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_juggler = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_drunkard = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_stone = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_golden = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_lucky_cat = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_baseball = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_bull = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_diet_cola = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_trading = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_flash = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_popcorn = {
		persistent = false,
		unreliable = true,
		draining = true,
	},
	j_trousers = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_ancient = {
		persistent = true,
		unreliable = false,
		draining = true,
	},
	j_ramen = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_walkie_talkie = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_selzer = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_castle = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_smiley = {
		persistent = true,
		unreliable = true,
		draining = false,
	},
	j_campfire = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_ticket = {
		persistent = true,
		unreliable = false,
		draining = true,
	},
	j_mr_bones = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_acrobat = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_sock_and_buskin = {
		persistent = false,
		unreliable = true,
		draining = true,
	},
	j_swashbuckler = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_troubadour = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_certificate = {
		persistent = true,
		unreliable = false,
		draining = true,
	},
	j_smeared = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_throwback = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_hanging_chad = {
		persistent = true,
		unreliable = true,
		draining = true,
	},
	j_rough_gem = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_bloodstone = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_arrowhead = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_onyx_agate = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_glass = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_ring_master = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_flower_pot = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_blueprint = {
		persistent = true,
		unreliable = true,
		draining = false,
	},
	j_wee = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_merry_andy = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_oops = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_idol = {
		persistent = false,
		unreliable = true,
		draining = true,
	},
	j_seeing_double = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_matador = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_hit_the_road = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_duo = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_trio = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_family = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_order = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_tribe = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_stuntman = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_invisible = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_brainstorm = {
		persistent = true,
		unreliable = false,
		draining = true,
	},
	j_satellite = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_shoot_the_moon = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_drivers_license = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_cartomancer = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_astronomer = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_burnt = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_bootstraps = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_caino = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_triboulet = {
		persistent = false,
		unreliable = true,
		draining = true,
	},
	j_yorick = {
		persistent = true,
		unreliable = false,
		draining = false,
	},
	j_chicot = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_perkeo = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_mp_conjoined_joker = {
		persistent = false,
		unreliable = true,
		draining = false,
	},
	j_mp_defensive_joker = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_mp_lets_go_gambling = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_mp_pacifist = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_mp_penny_pincher = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_mp_pizza = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_mp_skip_off = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
	j_mp_speedrun = {
		persistent = false,
		unreliable = false,
		draining = true,
	},
	j_mp_taxes = {
		persistent = false,
		unreliable = false,
		draining = false,
	},
}
-- told you it was big

G.E_MANAGER:add_event(Event({
	trigger = "immediate",
	func = function()
		for center, table in pairs(sticker_tables) do
			for k, v in pairs(table) do
				G.P_CENTERS[center]["mp_forced_" .. k] = v
			end
		end
		return true
	end,
}))
