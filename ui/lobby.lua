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

function G.UIDEF.create_UIBox_lobby_menu()
	local text_scale = 0.45
	local back = MP.LOBBY.config.different_decks and MP.LOBBY.deck.back or MP.LOBBY.config.back
	local stake = MP.LOBBY.config.different_decks and MP.LOBBY.deck.stake or MP.LOBBY.config.stake

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
					MP.UI.lobby_status_display(),
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
							MP.UI.create_lobby_main_button(text_scale),
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
									MP.UI.create_spacer(),
									MP.UI.create_lobby_deck_button(text_scale, back, stake),
									MP.UI.create_spacer(),
									MP.UI.create_players_section(text_scale),
									MP.UI.create_spacer(),
									MP.UI.create_lobby_code_buttons(text_scale),
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
									return MP.UI.create_lobby_options_tab()
								end,
							},
							{
								label = localize("k_opts_gm"),
								tab_definition_function = function()
									return MP.UI.create_gamemode_modifiers_tab()
								end,
							},
						},
					}),
				},
			},
		},
	})
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

function G.UIDEF.create_UIBox_view_hash(type)
	return (
		create_UIBox_generic_options({
			contents = {
				{
					n = G.UIT.C,
					config = {
						padding = 0.07,
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
				padding = 0.02,
				align = "cm",
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = s,
						shadow = true,
						scale = 0.4,
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
