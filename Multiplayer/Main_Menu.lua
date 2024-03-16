--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD MAIN MENU---------------------

local Utils = require("Utils")
local Lobby = require("Lobby")
local ActionHandlers = require("Action_Handlers")

MULTIPLAYER_VERSION = "0.1.0-MULTIPLAYER"

local gameMainMenuRef = Game.main_menu
function Game.main_menu(arg_280_0, arg_280_1)
	gameMainMenuRef(arg_280_0, arg_280_1)
	UIBox({
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
						text = MULTIPLAYER_VERSION,
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
				y = 0.6,
			},
			major = G.ROOM_ATTACH,
		},
	})
end

function create_UIBox_create_lobby_button()
	local var_495_0 = 0.75

	return (
		create_UIBox_generic_options({
			back_func = "play_options",
			contents = {
				{
					n = G.UIT.R,
					config = {
						padding = 0,
						align = "cm",
					},
					nodes = {
						create_tabs({
							snap_to_nav = true,
							colour = G.C.BOOSTER,
							tabs = {
								{
									label = "Attrition (1v1)",
									chosen = true,
									tab_definition_function = function()
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
													config = {
														align = "tm",
														padding = 0.05,
														minw = 4,
														minh = 1.5,
													},
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = Utils.wrapText(
																	"Both players start with 4 lives, every boss round is a competition between players where the player with the lower score loses a life.",
																	50
																),
																shadow = true,
																scale = var_495_0 * 0.6,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
												create_toggle({
													label = "Lose lives on round loss",
													ref_table = Lobby.config,
													ref_value = "death_on_round_loss",
												}),
												create_toggle({
													label = "Different seeds",
													ref_table = Lobby.config,
													ref_value = "different_seeds",
												}),
												UIBox_button({
													label = { "Start Lobby" },
													colour = G.C.RED,
													button = "start_lobby",
													minw = 5,
												}),
											},
										}
									end,
								},
								{
									label = "Draft (1v1)",
									tab_definition_function = function()
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
													config = {
														align = "tm",
														padding = 0.05,
														minw = 4,
														minh = 2.5,
													},
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = Utils.wrapText(
																	"Both players play a set amount of antes simultaneously, then they play an ante where every round the player with the higher scorer wins, player with the most round wins in the final ante is the victor.",
																	50
																),
																shadow = true,
																scale = var_495_0 * 0.6,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
												UIBox_button({
													label = { "Coming Soon!" },
													colour = G.C.RED,
													minw = 5,
												}),
											},
										}
									end,
								},
								{
									label = "Heads Up (1v1)",
									tab_definition_function = function()
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
													config = {
														align = "tm",
														padding = 0.05,
														minw = 4,
														minh = 1,
													},
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = Utils.wrapText(
																	"Both players play the first ante, then must keep beating the opponents previous score or lose.",
																	50
																),
																shadow = true,
																scale = var_495_0 * 0.6,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
												UIBox_button({
													label = { "Coming Soon!" },
													colour = G.C.RED,
													minw = 5,
												}),
											},
										}
									end,
								},
								{
									label = "Battle Royale (8p)",
									tab_definition_function = function()
										return {
											n = G.UIT.ROOT,
											config = {
												emboss = 0.05,
												minh = 6,
												r = 0.1,
												minw = 10,
												align = "Tm",
												padding = 0.2,
												colour = G.C.BLACK,
											},
											nodes = {
												{
													n = G.UIT.R,
													config = {
														align = "tm",
														padding = 0.05,
														minw = 4,
														minh = 1,
													},
													nodes = {
														{
															n = G.UIT.T,
															config = {
																text = Utils.wrapText(
																	"Draft, except there are up to 8 players and every player only has 1 life.",
																	50
																),
																shadow = true,
																scale = var_495_0 * 0.6,
																colour = G.C.UI.TEXT_LIGHT,
															},
														},
													},
												},
												UIBox_button({
													label = { "Coming Soon!" },
													colour = G.C.RED,
													minw = 5,
												}),
											},
										}
									end,
								},
							},
						}),
					},
				},
			},
		})
	)
end

function create_UIBox_join_lobby_button()
	return (
		create_UIBox_generic_options({
			back_func = "play_options",
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
										scale = 0.6,
										shadow = true,
										text = "Lobby Code:",
										colour = G.C.UI.TEXT_LIGHT,
									},
								},
							},
						},
						{
							n = G.UIT.R,
							config = {
								padding = 0.5,
								align = "cm",
							},
							nodes = {
								create_text_input({
									w = 4,
									h = 1,
									max_length = 5,
									prompt_text = "Enter Lobby Code",
									ref_table = Lobby,
									ref_value = "temp_code",
									extended_corpus = false,
									keyboard_offset = 1,
									minw = 5,
									callback = function(val)
										ActionHandlers.join_lobby(Lobby.temp_code)
									end,
								}),
							},
						},
						UIBox_button({
							label = { "Paste From Clipboard" },
							colour = G.C.RED,
							button = "join_from_clipboard",
							minw = 5,
						}),
					},
				},
			},
		})
	)
end

function override_main_menu_play_button()
	return (
		create_UIBox_generic_options({
			contents = {
				UIBox_button({
					label = { "Singleplayer" },
					colour = G.C.BLUE,
					button = "setup_run",
					minw = 5,
				}),
				Lobby.connected and UIBox_button({
					label = { "Create Lobby" },
					colour = G.C.GREEN,
					button = "create_lobby",
					minw = 5,
				}) or nil,
				Lobby.connected and UIBox_button({
					label = { "Join Lobby" },
					colour = G.C.RED,
					button = "join_lobby",
					minw = 5,
				}) or nil,
				not Lobby.connected and UIBox_button({
					label = { "Reconnect" },
					colour = G.C.RED,
					button = "reconnect",
					minw = 5,
				}) or nil,
			},
		})
	)
end

function G.FUNCS.play_options(arg_736_0)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = override_main_menu_play_button(),
	})
end

function G.FUNCS.create_lobby(arg_736_0)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = create_UIBox_create_lobby_button(),
	})
end

function G.FUNCS.join_lobby(arg_736_0)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = create_UIBox_join_lobby_button(),
	})
end

function G.FUNCS.join_from_clipboard(arg_736_0)
	Lobby.temp_code = Utils.get_from_clipboard()
	ActionHandlers.join_lobby(Lobby.temp_code)
end

function G.FUNCS.start_lobby(arg_736_0)
	G.SETTINGS.paused = false

	ActionHandlers.create_lobby()
end

-- Modify play button to take you to mode select first
local create_UIBox_main_menu_buttonsRef = create_UIBox_main_menu_buttons
function create_UIBox_main_menu_buttons()
	local menu = create_UIBox_main_menu_buttonsRef()
	menu.nodes[1].nodes[1].nodes[1].nodes[1].config.button = "play_options"
	return menu
end

----------------------------------------------
------------MOD MAIN MENU END-----------------
