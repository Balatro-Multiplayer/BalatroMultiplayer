--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD LOBBY-------------------------

local Disableable_Button = require("Disableable_Button")

Lobby = {
	connected = false,
	temp_code = "",
	code = nil,
	type = "",
	config = {},
	username = "Guest",
	host = {},
	guest = nil,
	is_host = false,
}

Connection_Status_UI = nil

local function get_connection_status_ui()
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
						text = (Lobby.code and "In Lobby")
							or (Lobby.connected and "Connected to Service")
							or "WARN: Cannot Find Multiplayer Service",
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

function Lobby.update_connection_status()
	if Connection_Status_UI then
		Connection_Status_UI:remove()
	end
	Connection_Status_UI = get_connection_status_ui()
end

local gameMainMenuRef = Game.main_menu
function Game.main_menu(arg_280_0, arg_280_1)
	Connection_Status_UI = get_connection_status_ui()
	gameMainMenuRef(arg_280_0, arg_280_1)
end

function G.FUNCS.copy_to_clipboard(arg_736_0)
	Utils.copy_to_clipboard(Lobby.code)
end

function G.FUNCS.reconnect(arg_736_0)
	ActionHandlers.connect()
	G.FUNCS:exit_overlay_menu()
end

function create_UIBox_view_code()
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
										text = Lobby.code,
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
									label = { "Copy to Clipboard" },
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

function G.FUNCS.lobby_setup_run(arg_736_0)
	G.FUNCS.start_run(arg_736_0, {
		stake = 1,
		challenge = {
			name = "Multiplayer Deck",
			id = "c_multiplayer_1",
			rules = {
				custom = {},
				modifiers = {},
			},
			jokers = {},
			consumeables = {},
			vouchers = {},
			deck = {
				type = "Challenge Deck",
			},
			restrictions = {
				banned_cards = {
					{ id = "j_diet_cola" }, -- Intention to disable skipping
					{ id = "j_mr_bones" },
					{ id = "v_hieroglyph" },
					{ id = "v_petroglyph" },
				},
				banned_tags = {},
				banned_other = {},
			},
		},
	})
end

function G.FUNCS.lobby_options(arg_736_0)
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
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
										text = "Not Implemented Yet",
										shadow = true,
										scale = 0.6,
										colour = G.C.UI.TEXT_LIGHT,
									},
								},
							},
						},
					},
				},
			},
		}),
	})
end

function G.FUNCS.view_code(arg_736_0)
	G.FUNCS.overlay_menu({
		definition = create_UIBox_view_code(),
	})
end

function G.FUNCS.lobby_leave(arg_736_0)
	Lobby.code = nil
	ActionHandlers.leave_lobby()
	Lobby.update_connection_status()
end

local function create_UIBox_lobby_menu()
	local text_scale = 0.45

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
							align = "cm",
							padding = 0.2,
							r = 0.1,
							emboss = 0.1,
							colour = G.C.L_BLACK,
							mid = true,
						},
						nodes = {
							Disableable_Button({
								id = "lobby_menu_start",
								button = "lobby_setup_run",
								colour = G.C.BLUE,
								minw = 3.65,
								minh = 1.55,
								label = { "START" },
								disabled_text = { "WAITING FOR", "HOST TO START" },
								scale = text_scale * 2,
								col = true,
								disable_ref_table = Lobby,
								disable_ref_value = "is_host",
							}),
							{
								n = G.UIT.C,
								config = {
									align = "cm",
								},
								nodes = {
									Disableable_Button({
										button = "lobby_options",
										colour = G.C.ORANGE,
										minw = 3.15,
										minh = 1.35,
										label = { "LOBBY OPTIONS" },
										scale = text_scale * 1.2,
										col = true,
										disable_ref_table = Lobby,
										disable_ref_value = "is_host",
									}),
									{
										n = G.UIT.C,
										config = {
											align = "cm",
											minw = 0.2,
										},
										nodes = {},
									},
									{
										n = G.UIT.C,
										config = {
											align = "tm",
											minw = 2.65,
										},
										nodes = {
											{
												n = G.UIT.R,
												config = {
													padding = 0.2,
													align = "cm",
												},
												nodes = {
													{
														n = G.UIT.T,
														config = {
															text = "Connected Players:",
															shadow = true,
															scale = text_scale * 0.8,
															colour = G.C.UI.TEXT_LIGHT,
														},
													},
												},
											},
											Lobby.host and Lobby.host.username and {
												n = G.UIT.R,
												config = {
													padding = 0,
													align = "cm",
												},
												nodes = {
													{
														n = G.UIT.T,
														config = {
															ref_table = Lobby.host,
															ref_value = "username",
															shadow = true,
															scale = text_scale * 0.8,
															colour = G.C.UI.TEXT_LIGHT,
														},
													},
												},
											} or nil,
											Lobby.guest and Lobby.guest.username and {
												n = G.UIT.R,
												config = {
													padding = 0,
													align = "cm",
												},
												nodes = {
													{
														n = G.UIT.T,
														config = {
															ref_table = Lobby.guest,
															ref_value = "username",
															shadow = true,
															scale = text_scale * 0.8,
															colour = G.C.UI.TEXT_LIGHT,
														},
													},
												},
											} or nil,
										},
									},
									{
										n = G.UIT.C,
										config = {
											align = "cm",
											minw = 0.2,
										},
										nodes = {},
									},
									UIBox_button({
										button = "view_code",
										colour = G.C.PALE_GREEN,
										minw = 3.15,
										minh = 1.35,
										label = { "VIEW CODE" },
										scale = text_scale * 1.2,
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
								label = { "LEAVE" },
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

local function get_lobby_main_menu_UI()
	return UIBox({
		definition = create_UIBox_lobby_menu(),
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

function display_lobby_main_menu_UI()
	G.MAIN_MENU_UI = get_lobby_main_menu_UI()
	G.MAIN_MENU_UI.alignment.offset.y = 0
	G.MAIN_MENU_UI:align_to_major()

	G.CONTROLLER:snap_to({ node = G.MAIN_MENU_UI:get_UIE_by_ID("lobby_menu_start") })
end

function Lobby.update_player_usernames()
	if Lobby.code then
		G.MAIN_MENU_UI:remove()
		display_lobby_main_menu_UI()
	end
end

local setMainMenuUIRef = set_main_menu_UI
function set_main_menu_UI()
	if Lobby.code then
		display_lobby_main_menu_UI()
	else
		setMainMenuUIRef()
	end
end

local in_lobby = false
local gameUpdateRef = Game.update
function Game:update(arg_298_1)
	if (Lobby.code and not in_lobby) or (not Lobby.code and in_lobby) then
		in_lobby = not in_lobby
		G.F_NO_SAVING = in_lobby
		self.FUNCS.go_to_menu()
	end
	gameUpdateRef(self, arg_298_1)
end

return Lobby

----------------------------------------------
------------MOD LOBBY END---------------------
