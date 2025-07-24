local Disableable_Button = MP.UI.Disableable_Button
local Disableable_Toggle = MP.UI.Disableable_Toggle
local Disableable_Option_Cycle = MP.UI.Disableable_Option_Cycle

-- This needs to have a parameter because its a callback for inputs
local function send_lobby_options(value)
	MP.ACTIONS.lobby_options()
end

G.HUD_connection_status = nil

function G.UIDEF.get_connection_status_ui()
	return UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = {
				align = "cm",
				colour = G.C.UI.TRANSPARENT_DARK,
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						scale = 0.3,
						text = (MP.LOBBY.code and localize("k_in_lobby")) or (MP.LOBBY.connected and localize(
							"k_connected"
						)) or localize("k_warn_service"),
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		},
		config = {
			align = "tri",
			bond = "Weak",
			offset = {
				x = 0,
				y = 0.9,
			},
			major = G.ROOM_ATTACH,
		},
	})
end

function G.UIDEF.create_UIBox_view_code()
	local var_495_0 = 0.75

	return (
		create_UIBox_generic_options({
			contents = {
				{
					n = G.UIT.R,
					config = {
						padding = 0,
						align = "cm",
					},
					nodes = {
						{
							n = G.UIT.R,
							config = {
								padding = 0.5,
								align = "cm",
							},
							nodes = {
								{
									n = G.UIT.T,
									config = {
										text = MP.LOBBY.code,
										shadow = true,
										scale = var_495_0 * 0.6,
										colour = G.C.UI.TEXT_LIGHT,
									},
								},
							},
						},
						{
							n = G.UIT.R,
							config = {
								padding = 0,
								align = "cm",
							},
							nodes = {
								UIBox_button({
									label = { localize("b_copy_clipboard") },
									colour = G.C.BLUE,
									button = "copy_to_clipboard",
									minw = 5,
								}),
							},
						},
					},
				},
			},
		})
	)
end

-- TODO: This entire function seems to only return once
-- ie we only get EITHER the order warning message or cheating message or nemesis unlock message
local function get_lobby_text()
	-- Check the other player (guest if we're host, host if we're guest)
	local other_player = MP.LOBBY.is_host and MP.LOBBY.guest or MP.LOBBY.host

	if other_player and other_player.cached == false then
		return MP.UTILS.wrapText(string.format(localize("k_warning_cheating"), MP.UTILS.random_message()), 100),
			SMODS.Gradients.warning_text
	end

	if other_player and other_player.config and other_player.config.unlocked == false then
		return localize("k_warning_nemesis_unlock"), SMODS.Gradients.warning_text
	end

	local current_player = MP.LOBBY.is_host and MP.LOBBY.host or MP.LOBBY.guest
	local current_has_order = current_player and current_player.config and current_player.config.TheOrder
	local other_has_order = other_player and other_player.config and other_player.config.TheOrder

	if (MP.LOBBY.ready_to_start or not MP.LOBBY.is_host) and current_has_order ~= other_has_order then
		return localize("k_warning_no_order"), SMODS.Gradients.warning_text
	end

	if MP.LOBBY.ready_to_start or not MP.LOBBY.is_host then
		local hostSteamoddedVersion = MP.LOBBY.host and MP.LOBBY.host.config and MP.LOBBY.host.config.Mods["Steamodded"]
		local guestSteamoddedVersion = MP.LOBBY.guest
			and MP.LOBBY.guest.config
			and MP.LOBBY.guest.config.Mods["Steamodded"]

		if hostSteamoddedVersion ~= guestSteamoddedVersion then
			return localize("k_steamodded_warning"), SMODS.Gradients.warning_text
		end
	end

	SMODS.Mods["Multiplayer"].config.unlocked = MP.UTILS.unlock_check()
	if not SMODS.Mods["Multiplayer"].config.unlocked then
		return localize("k_warning_unlock_profile"), SMODS.Gradients.warning_text
	end

	-- Remove the mod hash warning from main warning display area since it's shown
	-- alongside critical warnings (cheating, compatibility issues). This makes users
	-- learn to ignore all warnings. Instead, we should indicate hash differences
	-- through other UI elements like colored usernames or separate indicators.
	-- The hash check itself remains useful for debugging but shouldn't be presented
	-- as a blocking warning alongside serious compatibility issues.
	-- steph
	if MP.LOBBY.host and MP.LOBBY.host.hash and MP.LOBBY.guest and MP.LOBBY.guest.hash then
		if MP.LOBBY.host.hash ~= MP.LOBBY.guest.hash then
			return localize("k_mod_hash_warning"), G.C.UI.TEXT_LIGHT
		end
	end

	-- ???: What is this supposed to accomplish?
	if MP.LOBBY.username == "Guest" then
		return localize("k_set_name"), G.C.UI.TEXT_LIGHT
	end

	return " ", G.C.UI.TEXT_LIGHT
end

local function create_player_info_row(player, player_type, text_scale)
	if not player or not player.username then
		return nil
	end

	return {
		n = G.UIT.R,
		config = {
			padding = 0.1,
			align = "cm",
		},
		nodes = {
			{
				n = G.UIT.T,
				config = {
					ref_table = player,
					ref_value = "username",
					shadow = true,
					scale = text_scale * 0.8,
					colour = G.C.UI.TEXT_LIGHT,
				},
			},
			{
				n = G.UIT.B,
				config = {
					w = 0.1,
					h = 0.1,
				},
			},
			player.hash and UIBox_button({
				id = player_type .. "_hash",
				button = "view_" .. player_type .. "_hash",
				label = { player.hash },
				minw = 0.75,
				minh = 0.3,
				scale = 0.25,
				shadow = false,
				colour = G.C.PURPLE,
				col = true,
			}) or nil,
		},
	}
end

local function create_players_section(text_scale)
	return {
		n = G.UIT.C,
		config = {
			align = "tm",
			minw = 2.65,
		},
		nodes = {
			{
				n = G.UIT.R,
				config = {
					padding = 0.15,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_connect_player"),
							shadow = true,
							scale = text_scale * 0.8,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
			create_player_info_row(MP.LOBBY.host, "host", text_scale),
			create_player_info_row(MP.LOBBY.guest, "guest", text_scale),
		},
	}
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
local function create_lobby_options_tab()
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
			-- Much cleaner
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

local function create_spacer(width)
	return {
		n = G.UIT.C,
		config = {
			align = "cm",
			minw = width or 0.2,
		},
		nodes = {},
	}
end

function G.UIDEF.create_UIBox_lobby_menu()
	local text_scale = 0.45
	local back = MP.LOBBY.config.different_decks and MP.LOBBY.deck.back or MP.LOBBY.config.back
	local stake = MP.LOBBY.config.different_decks and MP.LOBBY.deck.stake or MP.LOBBY.config.stake

	local text, colour = get_lobby_text()

	local t = {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			colour = G.C.CLEAR,
		},
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "bm",
				},
				nodes = {
					{
						n = G.UIT.R,
						config = {
							padding = 1.25,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									scale = 0.3,
									shadow = true,
									text = text,
									colour = colour,
								},
							},
						},
					} or nil,
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.2,
							r = 0.1,
							emboss = 0.1,
							colour = G.C.L_BLACK,
							mid = true,
						},
						nodes = {
							MP.LOBBY.is_host
								and Disableable_Button({
									id = "lobby_menu_start",
									button = "lobby_start_game",
									colour = G.C.BLUE,
									minw = 3.65,
									minh = 1.55,
									label = { localize("b_start") },
									disabled_text = MP.LOBBY.guest.username and localize("b_wait_for_guest_ready") or localize("b_wait_for_players"),
									scale = text_scale * 2,
									col = true,
									enabled_ref_table = MP.LOBBY,
									enabled_ref_value = "ready_to_start",
								})
								or UIBox_button({
									id = "lobby_menu_start",
									button = "lobby_ready_up",
									colour = MP.LOBBY.ready_to_start and G.C.GREEN or G.C.RED,
									minw = 3.65,
									minh = 1.55,
									label = { MP.LOBBY.ready_to_start and localize("b_unready") or localize("b_ready") },
									scale = text_scale * 2,
									col = true,
								}),
							{
								n = G.UIT.C,
								config = {
									align = "cm",
								},
								nodes = {
									UIBox_button({
										button = "lobby_options",
										colour = G.C.ORANGE,
										minw = 3.15,
										minh = 1.35,
										label = {
											localize("b_lobby_options"),
										},
										scale = text_scale * 1.2,
										col = true,
									}),
									create_spacer(),
									MP.LOBBY.is_host and Disableable_Button({
										id = "lobby_choose_deck",
										button = "lobby_choose_deck",
										colour = G.C.PURPLE,
										minw = 2.15,
										minh = 1.35,
										label = {
											localize({
												type = "name_text",
												key = MP.UTILS.get_deck_key_from_name(back),
												set = "Back",
											}),
											localize({
												type = "name_text",
												key = SMODS.stake_from_index(
													type(stake) == "string" and tonumber(stake) or stake
												),
												set = "Stake",
											}),
										},
										scale = text_scale * 1.2,
										col = true,
										enabled_ref_table = MP.LOBBY,
										enabled_ref_value = "is_host",
									}) or Disableable_Button({
										id = "lobby_choose_deck",
										button = "lobby_choose_deck",
										colour = G.C.PURPLE,
										minw = 2.15,
										minh = 1.35,
										label = {
											localize({
												type = "name_text",
												key = MP.UTILS.get_deck_key_from_name(back),
												set = "Back",
											}),
											localize({
												type = "name_text",
												key = SMODS.stake_from_index(
													type(stake) == "string" and tonumber(stake) or stake
												),
												set = "Stake",
											}),
										},
										scale = text_scale * 1.2,
										col = true,
										enabled_ref_table = MP.LOBBY.config,
										enabled_ref_value = "different_decks",
									}),
									create_spacer(),
									create_players_section(text_scale),
									create_spacer(),
									UIBox_button({
										button = "view_code",
										colour = G.C.PALE_GREEN,
										minw = 2.15,
										minh = 1.35,
										label = { localize("b_view_code") },
										scale = text_scale * 1.2,
										col = true,
									}),
									create_spacer(),
									UIBox_button({
										button = "copy_to_clipboard",
										colour = G.C.PALE_GREEN,
										minw = 1.35,
										minh = 1.35,
										label = {"COPY CODE", "TO CLIPBOARD"},
										scale = text_scale,
										col = true,
									}),
								},
							},
							UIBox_button({
								id = "lobby_menu_leave",
								button = "lobby_leave",
								colour = G.C.RED,
								minw = 3.65,
								minh = 1.55,
								label = { localize("b_leave") },
								scale = text_scale * 1.5,
								col = true,
							}),
						},
					},
				},
			},
		},
	}
	return t
end

local function create_lobby_option_cycle(id, label_key, options, current_option, callback)
	return Disableable_Option_Cycle({
		id = id,
		enabled_ref_table = MP.LOBBY,
		enabled_ref_value = "is_host",
		label = localize(label_key),
		options = options,
		current_option = current_option,
		opt_callback = callback,
	})
end

local function create_gamemode_modifiers_tab()
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
			{
				n = G.UIT.R,
				config = { padding = 0, align = "cm" },
				nodes = {
					create_lobby_option_cycle(
						"starting_lives_option",
						"b_opts_lives",
						{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 },
						MP.LOBBY.config.starting_lives,
						"change_starting_lives"
					),
					create_lobby_option_cycle("pvp_round_start_option", "k_opts_pvp_start_round", {
						1,
						2,
						3,
						4,
						5,
						6,
						7,
						8,
						9,
						10,
						11,
						12,
						13,
						14,
						15,
						16,
						17,
						18,
						19,
						20,
					}, MP.LOBBY.config.pvp_start_round, "change_starting_pvp_round"),
					create_lobby_option_cycle(
						"pvp_timer_seconds_option",
						"k_opts_pvp_timer",
						{ "30s", "60s", "90s", "120s", "150s", "180s" },
						MP.LOBBY.config.timer_base_seconds / 30,
						"change_timer_base_seconds"
					),
					create_lobby_option_cycle("showdown_starting_antes_option", "k_opts_showdown_starting_antes", {
						1,
						2,
						3,
						4,
						5,
						6,
						7,
						8,
						9,
						10,
						11,
						12,
						13,
						14,
						15,
						16,
						17,
						18,
						19,
						20,
					}, MP.LOBBY.config.showdown_starting_antes, "change_showdown_starting_antes"),

					create_lobby_option_cycle("pvp_timer_increment_seconds_option", "k_opts_pvp_timer_increment", {
						"0s",
						"30s",
						"60s",
						"90s",
						"120s",
						"150s",
						"180s",
					}, MP.LOBBY.config.timer_increment_seconds / 30, "change_timer_increment_seconds"),
				},
			},
		},
	}
end

function G.UIDEF.create_UIBox_lobby_options()
	return create_UIBox_generic_options({
		contents = {
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
				},
				nodes = {
					not MP.LOBBY.is_host and {
						n = G.UIT.R,
						config = {
							padding = 0.3,
							align = "cm",
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									scale = 0.6,
									shadow = true,
									text = localize("k_opts_only_host"),
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					} or nil,
					create_tabs({
						snap_to_nav = true,
						colour = G.C.BOOSTER,
						tabs = {
							{
								label = localize("k_lobby_options"),
								chosen = true,
								tab_definition_function = function()
									return create_lobby_options_tab()
								end,
							},
							{
								label = localize("k_opts_gm"),
								tab_definition_function = function()
									return create_gamemode_modifiers_tab()
								end,
							},
						},
					}),
				},
			},
		},
	})
end

function G.FUNCS.display_custom_seed(e)
	local display = MP.LOBBY.config.custom_seed == "random" and localize("k_random") or MP.LOBBY.config.custom_seed
	if display ~= e.children[1].config.text then
		e.children[2].config.text = display
		e.UIBox:recalculate(true)
	end
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

function G.UIDEF.create_UIBox_view_hash(type)
	return (
		create_UIBox_generic_options({
			contents = {
				{
					n = G.UIT.C,
					config = {
						padding = 0.2,
						align = "cm",
					},
					nodes = MP.UI.hash_str_to_view(
						type == "host" and MP.LOBBY.host.hash_str or MP.LOBBY.guest.hash_str,
						G.C.UI.TEXT_LIGHT
					),
				},
			},
		})
	)
end

function MP.UI.hash_str_to_view(str, text_colour)
	local t = {}

	if not str then
		return t
	end

	for s in str:gmatch("[^;]+") do
		table.insert(t, {
			n = G.UIT.R,
			config = {
				padding = 0.05,
				align = "cm",
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = s,
						shadow = true,
						scale = 0.45,
						colour = text_colour,
					},
				},
			},
		})
	end
	return t
end

G.FUNCS.view_host_hash = function(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_view_hash("host"),
	})
end

G.FUNCS.view_guest_hash = function(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_view_hash("guest"),
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

function G.FUNCS.get_lobby_main_menu_UI(e)
	return UIBox({
		definition = G.UIDEF.create_UIBox_lobby_menu(),
		config = {
			align = "bmi",
			offset = {
				x = 0,
				y = 10,
			},
			major = G.ROOM_ATTACH,
			bond = "Weak",
		},
	})
end

---@type fun(e: table | nil, args: { deck: string, stake: number | nil, seed: string | nil })
function G.FUNCS.lobby_start_run(e, args)
	if MP.LOBBY.config.different_decks == false then
		G.FUNCS.copy_host_deck()
	end

	local challenge = nil
	if MP.LOBBY.deck.back == "Challenge Deck" then
		challenge = G.CHALLENGES[get_challenge_int_from_id(MP.LOBBY.deck.challenge)]
	else
		G.GAME.viewed_back = G.P_CENTERS[MP.UTILS.get_deck_key_from_name(MP.LOBBY.deck.back)]
	end

	G.FUNCS.start_run(e, {
		mp_start = true,
		challenge = challenge,
		stake = tonumber(MP.LOBBY.deck.stake),
		seed = args.seed,
	})
end

function G.FUNCS.copy_host_deck()
	MP.LOBBY.deck.back = MP.LOBBY.config.back
	MP.LOBBY.deck.sleeve = MP.LOBBY.config.sleeve
	MP.LOBBY.deck.stake = MP.LOBBY.config.stake
	MP.LOBBY.deck.challenge = MP.LOBBY.config.challenge
end

function G.FUNCS.lobby_start_game(e)
	MP.ACTIONS.start_game()
end

function G.FUNCS.lobby_ready_up(e)
	MP.LOBBY.ready_to_start = not MP.LOBBY.ready_to_start

	e.config.colour = MP.LOBBY.ready_to_start and G.C.GREEN or G.C.RED
	e.children[1].children[1].config.text = MP.LOBBY.ready_to_start and localize("b_unready") or localize("b_ready")
	e.UIBox:recalculate()

	if MP.LOBBY.ready_to_start then
		MP.ACTIONS.ready_lobby()
	else
		MP.ACTIONS.unready_lobby()
	end
end

function G.FUNCS.lobby_options(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_lobby_options(),
	})
end

function G.FUNCS.view_code(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_view_code(),
	})
end

function G.FUNCS.lobby_leave(e)
	MP.LOBBY.code = nil
	MP.ACTIONS.leave_lobby()
	MP.UI.update_connection_status()
	G.STATE = G.STATES.MENU
end

function G.FUNCS.lobby_choose_deck(e)
	G.FUNCS.setup_run(e)
	if G.OVERLAY_MENU then
		G.OVERLAY_MENU:get_UIE_by_ID("run_setup_seed"):remove()
	end
end

local start_run_ref = G.FUNCS.start_run
G.FUNCS.start_run = function(e, args)
	if MP.LOBBY.code then
		if not args.mp_start then
			G.FUNCS.exit_overlay_menu()
			local chosen_stake = args.stake
			if MP.DECK.MAX_STAKE > 0 and chosen_stake > MP.DECK.MAX_STAKE then
				MP.UTILS.overlay_message(
					"Selected stake is incompatible with Multiplayer, stake set to "
						.. SMODS.stake_from_index(MP.DECK.MAX_STAKE)
				)
				chosen_stake = MP.DECK.MAX_STAKE
			end
			if MP.LOBBY.is_host then
				MP.LOBBY.config.back = args.challenge and "Challenge Deck"
					or (args.deck and args.deck.name)
					or G.GAME.viewed_back.name
				MP.LOBBY.config.stake = chosen_stake
				MP.LOBBY.config.sleeve = G.viewed_sleeve
				MP.LOBBY.config.challenge = args.challenge and args.challenge.id or ""
				send_lobby_options()
			end
			MP.LOBBY.deck.back = args.challenge and "Challenge Deck"
				or (args.deck and args.deck.name)
				or G.GAME.viewed_back.name
			MP.LOBBY.deck.stake = chosen_stake
			MP.LOBBY.deck.sleeve = G.viewed_sleeve
			MP.LOBBY.deck.challenge = args.challenge and args.challenge.id or ""
			MP.ACTIONS.update_player_usernames()
		else
			start_run_ref(e, {
				challenge = args.challenge,
				stake = tonumber(MP.LOBBY.deck.stake),
				seed = args.seed,
			})
		end
	else
		start_run_ref(e, args)
	end
end

function G.FUNCS.display_lobby_main_menu_UI(e)
	G.MAIN_MENU_UI = G.FUNCS.get_lobby_main_menu_UI(e)
	G.MAIN_MENU_UI.alignment.offset.y = 0
	G.MAIN_MENU_UI:align_to_major()

	G.CONTROLLER:snap_to({ node = G.MAIN_MENU_UI:get_UIE_by_ID("lobby_menu_start") })
end

function G.FUNCS.mp_return_to_lobby()
	MP.ACTIONS.stop_game()
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

local set_main_menu_UI_ref = set_main_menu_UI
---@diagnostic disable-next-line: lowercase-global
function set_main_menu_UI()
	if MP.LOBBY.code then
		if G.MAIN_MENU_UI then
			G.MAIN_MENU_UI:remove()
		end
		if G.STAGE == G.STAGES.MAIN_MENU then
			G.FUNCS.display_lobby_main_menu_UI()
		end
	else
		set_main_menu_UI_ref()
	end
end

local in_lobby = false
local gameUpdateRef = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	-- Track lobby state transitions
	if (MP.LOBBY.code and not in_lobby) or (not MP.LOBBY.code and in_lobby) then
		in_lobby = not in_lobby
		G.F_NO_SAVING = in_lobby
		if true then -- G.STATE == G.STATES.MENU, revert if something breaks, but this causes disconnects to not exit the game
			self.FUNCS.go_to_menu()
			MP.reset_game_states()
		end
	end
	gameUpdateRef(self, dt)
end

function G.UIDEF.create_UIBox_unstuck()
	return (
		create_UIBox_generic_options({
			contents = {
				{
					n = G.UIT.C,
					config = {
						padding = 0.2,
						align = "cm",
					},
					nodes = {
						UIBox_button({ label = { localize("b_unstuck_blind") }, button = "mp_unstuck_blind", minw = 5 }),
					},
				},
			},
		})
	)
end

function G.FUNCS.mp_unstuck()
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_unstuck(),
	})
end

function G.FUNCS.mp_unstuck_arcana()
	G.FUNCS.skip_booster()
end

function G.FUNCS.mp_unstuck_blind()
	MP.GAME.ready_blind = false
	if MP.GAME.next_blind_context then
		G.FUNCS.select_blind(MP.GAME.next_blind_context)
	else
		sendErrorMessage("No next blind context", "MULTIPLAYER")
	end
end

function MP.UI.update_connection_status()
	if G.HUD_connection_status then
		G.HUD_connection_status:remove()
	end
	if G.STAGE == G.STAGES.MAIN_MENU then
		G.HUD_connection_status = G.UIDEF.get_connection_status_ui()
	end
end

local gameMainMenuRef = Game.main_menu
---@diagnostic disable-next-line: duplicate-set-field
function Game:main_menu(change_context)
	MP.UI.update_connection_status()
	gameMainMenuRef(self, change_context)
end

function G.FUNCS.copy_to_clipboard(e)
	MP.UTILS.copy_to_clipboard(MP.LOBBY.code)
end

function G.FUNCS.reconnect(e)
	MP.ACTIONS.connect()
	G.FUNCS:exit_overlay_menu()
end

function MP.update_player_usernames()
	if MP.LOBBY.code then
		if G.MAIN_MENU_UI then
			G.MAIN_MENU_UI:remove()
		end
		if G.STAGE == G.STAGES.MAIN_MENU then
			G.FUNCS.display_lobby_main_menu_UI()
		end
	end
end
