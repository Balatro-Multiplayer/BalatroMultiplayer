MP.SANDBOX = {}

MP.Ruleset({
	key = "sandbox",
	multiplayer_content = true,
	banned_jokers = {},
	banned_silent = {
		"j_hanging_chad",
		"j_ride_the_bus",
		"j_baseball",
		"j_bloodstone",
		"j_castle",
		"j_cloud_9",
		"j_constellation",
		"j_faceless",
		"j_hit_the_road",
		"j_juggler",
		"j_loyalty_card",
		"j_lucky_cat",
		"j_mail",
		"j_misprint",
		"j_order",
		"j_photograph",
		"j_runner",
		"j_satellite",
		"j_square",
		"j_steel_joker",
		"j_throwback",
		"j_vampire",
	},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = { "tag_rare" },
	banned_blinds = {},

	reworked_jokers = (function()
		local jokers = {
			"j_mp_hanging_chad",
			"j_mp_magnet_sandbox",
		}
		for i = 1, 21 do
			table.insert(jokers, "j_mp_preview_disabled_sandbox_" .. i)
		end
		return jokers
	end)(),
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {},
	reworked_blinds = {},
	reworked_tags = { "tag_mp_sandbox_rare" },

	create_info_menu = function()
		return {
			{
				n = G.UIT.R,
				config = {
					align = "tm",
				},
				nodes = {
					MP.UI.BackgroundGrouping(localize("k_has_multiplayer_content"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_yes"),
								scale = 0.8,
								colour = G.C.GREEN,
							},
						},
					}, { col = true, text_scale = 0.6 }),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1,
						},
					},
					MP.UI.BackgroundGrouping(localize("k_forces_lobby_options"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_yes"),
								scale = 0.8,
								colour = G.C.GREEN,
							},
						},
					}, { col = true, text_scale = 0.6 }),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1,
						},
					},
					MP.UI.BackgroundGrouping(localize("k_forces_gamemode"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							},
						},
					}, { col = true, text_scale = 0.6 }),
				},
			},
			{
				n = G.UIT.R,
				config = {
					minw = 0.05,
					minh = 0.05,
				},
			},
			{
				n = G.UIT.R,
				config = {
					align = "cl",
					padding = 0.1,
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_sandbox_description"),
							scale = 0.6,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
		}
	end,

	forced_lobby_options = true,

	force_lobby_options = function(self)
		MP.LOBBY.config.preview_disabled = true
		MP.LOBBY.config.the_order = false
		return true
	end,
}):inject()

-- debugging hotswitch
MP.sandbox_no_collection = true
