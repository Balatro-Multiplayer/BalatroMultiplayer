-- Component for lobby options tab containing toggles and custom seed section

local Disableable_Toggle = MP.UI.Disableable_Toggle
local Disableable_Button = MP.UI.Disableable_Button

-- This needs to have a parameter because its a callback for inputs
local function send_lobby_options(value)
	MP.ACTIONS.lobby_options()
end

local function create_lobby_option_toggle(id, label_key, ref_value, callback)
	return {
		n = G.UIT.R,
		config = {
			padding = 0,
			align = "cr",
		},
		nodes = {
			Disableable_Toggle({
				id = id,
				enabled_ref_table = MP.LOBBY,
				enabled_ref_value = "is_host",
				label = localize(label_key),
				ref_table = MP.LOBBY.config,
				ref_value = ref_value,
				callback = callback or send_lobby_options,
			}),
		},
	}
end

local function create_custom_seed_section()
	if MP.LOBBY.config.different_seeds then
		return { n = G.UIT.B, config = { w = 0.1, h = 0.1 } }
	end

	return {
		n = G.UIT.R,
		config = { padding = 0, align = "cr" },
		nodes = {
			{
				-- TODO: Extract this into a component so we can pretend it's clean code
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
				},
				nodes = {
					{
						n = G.UIT.C,
						config = {
							padding = 0,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.R,
								config = {
									padding = 0.2,
									align = "cr",
									func = "display_custom_seed",
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											scale = 0.45,
											text = localize("k_current_seed"),
											colour = G.C.UI.TEXT_LIGHT,
										},
									},
									{
										n = G.UIT.T,
										config = {
											scale = 0.45,
											text = MP.LOBBY.config.custom_seed,
											colour = G.C.UI.TEXT_LIGHT,
										},
									},
								},
							},
							{
								n = G.UIT.R,
								config = {
									padding = 0.2,
									align = "cr",
								},
								nodes = {
									Disableable_Button({
										id = "custom_seed_overlay",
										button = "custom_seed_overlay",
										colour = G.C.BLUE,
										minw = 3.65,
										minh = 0.6,
										label = {
											localize("b_set_custom_seed"),
										},
										disabled_text = {
											localize("b_set_custom_seed"),
										},
										scale = 0.45,
										col = true,
										enabled_ref_table = MP.LOBBY,
										enabled_ref_value = "is_host",
									}),
									{
										n = G.UIT.B,
										config = {
											w = 0.1,
											h = 0.1,
										},
									},
									Disableable_Button({
										id = "custom_seed_reset",
										button = "custom_seed_reset",
										colour = G.C.RED,
										minw = 1.65,
										minh = 0.6,
										label = {
											localize("b_reset"),
										},
										disabled_text = {
											localize("b_reset"),
										},
										scale = 0.45,
										col = true,
										enabled_ref_table = MP.LOBBY,
										enabled_ref_value = "is_host",
									}),
								},
							},
						},
					},
				},
			},
		},
	}
end

-- Creates the lobby options tab UI containing toggles for various multiplayer settings
-- Returns a UI table with lobby configuration options like gold on life loss, different seeds, etc.
function MP.UI.create_lobby_options_tab()
	return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 6,
			r = 0.1,
			minw = 10,
			align = "tm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			create_lobby_option_toggle("gold_on_life_loss_toggle", "b_opts_cb_money", "gold_on_life_loss"),
			create_lobby_option_toggle(
				"no_gold_on_round_loss_toggle",
				"b_opts_no_gold_on_loss",
				"no_gold_on_round_loss"
			),
			create_lobby_option_toggle("death_on_round_loss_toggle", "b_opts_death_on_loss", "death_on_round_loss"),
			create_lobby_option_toggle(
				"different_seeds_toggle",
				"b_opts_diff_seeds",
				"different_seeds",
				toggle_different_seeds
			),
			create_lobby_option_toggle("different_decks_toggle", "b_opts_player_diff_deck", "different_decks"),
			create_lobby_option_toggle("multiplayer_jokers_toggle", "b_opts_multiplayer_jokers", "multiplayer_jokers"),
			create_lobby_option_toggle("timer_toggle", "b_opts_timer", "timer"),
			create_lobby_option_toggle("normal_bosses_toggle", "b_opts_normal_bosses", "normal_bosses"),
			create_custom_seed_section(),
		},
	}
end