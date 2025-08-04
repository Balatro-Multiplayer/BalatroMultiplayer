local Disableable_Toggle = MP.UI.Disableable_Toggle
local Disableable_Button = MP.UI.Disableable_Button

-- TODO repetition but w/e...
local function send_lobby_options(value)
	MP.ACTIONS.lobby_options()
end

function G.FUNCS.custom_seed_overlay(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_custom_seed_overlay(),
	})
end

function G.FUNCS.custom_seed_reset(e)
	MP.LOBBY.config.custom_seed = "random"
	send_lobby_options()
end

function G.UIDEF.create_UIBox_custom_seed_overlay()
	return create_UIBox_generic_options({
		back_func = "lobby_options",
		contents = {
			{
				n = G.UIT.R,
				config = { align = "cm", colour = G.C.CLEAR },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", minw = 0.1 },
						nodes = {
							create_text_input({
								max_length = 8,
								all_caps = true,
								ref_table = MP.LOBBY,
								ref_value = "temp_seed",
								prompt_text = localize("k_enter_seed"),
								keyboard_offset = 4,
								callback = function(val)
									MP.LOBBY.config.custom_seed = MP.LOBBY.temp_seed
									send_lobby_options()
								end,
							}),
							{
								n = G.UIT.B,
								config = { w = 0.1, h = 0.1 },
							},
							{
								n = G.UIT.T,
								config = {
									scale = 0.3,
									text = localize("k_enter_to_save"),
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					},
				},
			},
		},
	})
end

function toggle_different_seeds()
	G.FUNCS.lobby_options()
	send_lobby_options()
end

G.FUNCS.change_starting_lives = function(args)
	MP.LOBBY.config.starting_lives = args.to_val
	send_lobby_options()
end

G.FUNCS.change_starting_pvp_round = function(args)
	MP.LOBBY.config.pvp_start_round = args.to_val
	send_lobby_options()
end

G.FUNCS.change_timer_base_seconds = function(args)
	MP.LOBBY.config.timer_base_seconds = tonumber(args.to_val:sub(1, -2))
	send_lobby_options()
end

G.FUNCS.change_timer_increment_seconds = function(args)
	MP.LOBBY.config.timer_increment_seconds = tonumber(args.to_val:sub(1, -2))
	send_lobby_options()
end

G.FUNCS.change_showdown_starting_antes = function(args)
	MP.LOBBY.config.showdown_starting_antes = args.to_val
	send_lobby_options()
end

G.FUNCS.change_pvp_countdown_seconds = function(args)
	MP.LOBBY.config.pvp_countdown_seconds = args.to_val
	send_lobby_options()
end

-- This needs to have a parameter because its a callback for inputs
local function send_lobby_options(value)
	MP.ACTIONS.lobby_options()
end

function G.FUNCS.display_custom_seed(e)
	local display = MP.LOBBY.config.custom_seed == "random" and localize("k_random") or MP.LOBBY.config.custom_seed
	if display ~= e.children[1].config.text then
		e.children[2].config.text = display
		e.UIBox:recalculate(true)
	end
end

-- Component for lobby options tab containing toggles and custom seed section
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
