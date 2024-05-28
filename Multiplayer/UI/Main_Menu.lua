----------------------------------------------
------------MOD MAIN MENU---------------------

local Utils = require("Utils")
local success, version = pcall(require, "Version")
if not success then
	version = "DEV"
end

MULTIPLAYER_VERSION = version .. "-MULTIPLAYER"

local game_main_menu_ref = Game.main_menu
---@diagnostic disable-next-line: duplicate-set-field
function Game:main_menu(change_context)
	game_main_menu_ref(self, change_context)
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

function G.UIDEF.create_UIBox_create_lobby_button()
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
									label = mp_localize("attrition_name", "Attrition"),
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
																	mp_localize(
																		"attrition_desc",
																		"Every boss round is a competition between players where the player with the lower score loses a life."
																	),
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
													id = "start_attrition",
													label = { mp_localize("start_lobby", "Start Lobby") },
													colour = G.C.RED,
													button = "start_lobby",
													minw = 5,
												}),
											},
										}
									end,
								},
								{
									label = mp_localize("draft_name", "Draft"),
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
																	mp_localize(
																		"draft_desc",
																		"Both players play 3 normal antes, then they play an ante where every round the player with the higher scorer wins."
																	),
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
													id = "start_draft",
													label = { mp_localize("start_lobby", "Start Lobby") },
													colour = G.C.RED,
													button = "start_lobby",
													minw = 5,
												}),
											},
										}
									end,
								},
								{
									label = mp_localize("vanilla_plus_name", "Vanilla+"),
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
																	mp_localize(
																		"vp_desc",
																		"The first person to fail a round loses, no PvP blinds."
																	),
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
													label = { mp_localize("coming_soon", "Coming Soon!") },
													colour = G.C.RED,
													minw = 5,
												}),
											},
										}
									end,
								},
								{
									label = mp_localize("headup_name", "Heads Up"),
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
																	mp_localize(
																		"hu_desc",
																		"Both players play the first ante, then must keep beating the opponents previous score or lose."
																	),
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
													label = { mp_localize("coming_soon", "Coming Soon!") },
													colour = G.C.RED,
													minw = 5,
												}),
											},
										}
									end,
								},
								{
									label = mp_localize("royale_name", "Battle Royale"),
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
																	mp_localize(
																		"royale_desc",
																		"Attrition, except there are up to 8 players and every player only has 1 life."
																	),
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
													label = { mp_localize("coming_soon", "Coming Soon!") },
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

function G.UIDEF.create_UIBox_join_lobby_button()
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
								create_text_input({
									w = 4,
									h = 1,
									max_length = 5,
									prompt_text = mp_localize("enter_lobby_code", "Enter Lobby Code"),
									ref_table = G.LOBBY,
									ref_value = "temp_code",
									extended_corpus = false,
									keyboard_offset = 1,
									minw = 5,
									callback = function(val)
										G.MULTIPLAYER.join_lobby(G.LOBBY.temp_code)
									end,
								}),
							},
						},
						UIBox_button({
							label = { mp_localize("join_clip", "Paste From Clipboard") },
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

function G.UIDEF.override_main_menu_play_button()
	return (
		create_UIBox_generic_options({
			contents = {
				UIBox_button({
					label = { mp_localize("singleplayer", "Singleplayer") },
					colour = G.C.BLUE,
					button = "setup_run",
					minw = 5,
				}),
				G.LOBBY.connected and UIBox_button({
					label = { mp_localize("create_lobby", "Create Lobby") },
					colour = G.C.GREEN,
					button = "create_lobby",
					minw = 5,
				}) or nil,
				G.LOBBY.connected and UIBox_button({
					label = { mp_localize("join_lobby", "Join Lobby") },
					colour = G.C.RED,
					button = "join_lobby",
					minw = 5,
				}) or nil,
				not G.LOBBY.connected and UIBox_button({
					label = { mp_localize("reconnect", "Reconnect") },
					colour = G.C.RED,
					button = "reconnect",
					minw = 5,
				}) or nil,
			},
		})
	)
end

function G.FUNCS.play_options(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.override_main_menu_play_button(),
	})
end

function G.FUNCS.create_lobby(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_create_lobby_button(),
	})
end

function G.FUNCS.join_lobby(e)
	G.SETTINGS.paused = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_join_lobby_button(),
	})
end

function G.FUNCS.join_from_clipboard(e)
	G.LOBBY.temp_code = Utils.get_from_clipboard()
	G.MULTIPLAYER.join_lobby(G.LOBBY.temp_code)
end

function G.FUNCS.start_lobby(e)
	G.SETTINGS.paused = false
	G.MULTIPLAYER.create_lobby(e.config.id == "start_attrition" and "attrition" or "draft")
end

-- Modify play button to take you to mode select first
local create_UIBox_main_menu_buttonsRef = create_UIBox_main_menu_buttons
---@diagnostic disable-next-line: lowercase-global
function create_UIBox_main_menu_buttons()
	local menu = create_UIBox_main_menu_buttonsRef()
	menu.nodes[1].nodes[1].nodes[1].nodes[1].config.button = "play_options"
	return menu
end

----------------------------------------------
------------MOD MAIN MENU END-----------------
