-- Main menu, copied from the Speedrunning mod's ui/main_menu (buttons.lua + view.lua)
-- and rewired to PvP. Same layout: a big Find Game, a Leaderboard/Practice stack, a
-- Join Lobby column (by-code / from-clipboard), and a big Create Lobby.

PVP.main_menu = PVP.main_menu or { buttons = {}, initialized = false }

-- Distinct teal for the Leaderboard button (matches Speed).
local _leaderboard_colour = { 0.20, 0.74, 0.72, 1 }

function PVP.main_menu.create_buttons()
	local M = PVP.main_menu
	if M.initialized then
		return
	end
	local b = M.buttons

	M.find_game_args = {
		id = "mp_pvp_find_game",
		button = "mp_pvp_find_game",
		colour = G.C.BLUE,
		minw = 3.65,
		minh = 1.55,
		label = { localize("b_find_game_cap") },
		scale = 0.7,
		col = true,
		enabled = function()
			return MPAPI.is_connected()
		end,
	}
	b.find_game = MPAPI.disableable_button(M.find_game_args)
	b.create_lobby = MPAPI.disableable_button({
		id = "mp_pvp_create_lobby",
		button = "mp_pvp_create_lobby",
		colour = G.C.GREEN,
		minw = 3.65,
		minh = 1.55,
		label = localize("b_create_lobby_cap"),
		scale = 0.7,
		col = true,
		enabled = function()
			return MPAPI.is_connected()
		end,
	})
	b.join_by_code = MPAPI.disableable_button({
		id = "mp_pvp_join_lobby_by_code",
		button = "mp_pvp_join_lobby_by_code",
		colour = G.C.RED,
		minw = 3.65,
		minh = 0.6,
		label = { localize("b_by_code_cap") },
		scale = 0.45,
		enabled = function()
			return MPAPI.is_connected()
		end,
	})
	b.join_from_clipboard = MPAPI.disableable_button({
		id = "mp_pvp_join_lobby_from_clipboard",
		button = "mp_pvp_join_lobby_from_clipboard",
		colour = G.C.PURPLE,
		minw = 3.65,
		minh = 0.6,
		label = { localize("b_from_clipboard_cap") },
		scale = 0.45,
		enabled = function()
			return MPAPI.is_connected()
		end,
	})
	b.practice = MPAPI.disableable_button({
		id = "mp_pvp_practice",
		button = "mp_pvp_practice",
		colour = G.C.ORANGE,
		minw = 2.65,
		minh = 1.35,
		label = { localize("b_practice_cap") },
		scale = 0.54,
		col = true,
		-- Practice is fully local (MPAPI.create_local_lobby) -- no server needed.
		enabled = true,
	})
	b.leaderboard = MPAPI.disableable_button({
		id = "mp_pvp_leaderboard",
		button = "mp_pvp_open_leaderboard",
		colour = _leaderboard_colour,
		minw = 2.65,
		minh = 1.35,
		label = { localize("b_leaderboard_cap") },
		scale = 0.54,
		col = true,
		enabled = function()
			return MPAPI.is_connected()
		end,
	})
	-- §22.2/§22.3: replay is fully local playback once the run/lobby list is
	-- fetched, but the list fetch itself needs a real connection, same as
	-- Leaderboard.
	b.replay = MPAPI.disableable_button({
		id = "mp_pvp_replay",
		button = "mp_pvp_open_replay_menu",
		colour = { 0.55, 0.35, 0.75, 1 },
		minw = 2.65,
		minh = 1.35,
		label = { "Replay" },
		scale = 0.54,
		col = true,
		enabled = function()
			return MPAPI.is_connected()
		end,
	})
	M.initialized = true
end

PVP.update_main_menu_buttons = function()
	local M = PVP.main_menu
	if not M.initialized then
		return
	end
	M.buttons.find_game:update()
	M.buttons.create_lobby:update()
	M.buttons.join_by_code:update()
	M.buttons.join_from_clipboard:update()
	M.buttons.leaderboard:update()
	M.buttons.replay:update()
end

-- Swap the Find Game button between search / cancel (called by queue.lua).
PVP._show_searching_state = function(searching)
	local M = PVP.main_menu
	if not M.initialized or not M.find_game_args then
		return
	end
	if searching then
		M.find_game_args.label = { localize("b_cancel_search_cap") }
		M.find_game_args.button = "mp_pvp_cancel_queue"
		M.find_game_args.colour = G.C.RED
	else
		M.find_game_args.label = { localize("b_find_game_cap") }
		M.find_game_args.button = "mp_pvp_find_game"
		M.find_game_args.colour = G.C.BLUE
	end
	M.buttons.find_game:update()
end

PVP.build_pre_lobby_ui = function()
	PVP.main_menu.create_buttons()
	MPAPI.set_logo_offset(0, true)
	local b = PVP.main_menu.buttons
	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "bm" },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.1, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK, mid = true },
						nodes = {
							b.find_game.node,
							{
								n = G.UIT.C,
								config = { align = "cm" },
								nodes = {
									{ n = G.UIT.R, config = { align = "cm" }, nodes = {
										{ n = G.UIT.C, config = { align = "cm", padding = 0.05 }, nodes = { b.leaderboard.node } },
										{ n = G.UIT.C, config = { align = "cm", padding = 0.05 }, nodes = { b.practice.node } },
										{ n = G.UIT.C, config = { align = "cm", padding = 0.05 }, nodes = { b.replay.node } },
									} },
								},
							},
							{
								n = G.UIT.C,
								config = { align = "cm", padding = 0.1, r = 0.2, colour = G.C.BLACK },
								nodes = {
									{
										n = G.UIT.C,
										config = { align = "cm", maxh = 1.4 },
										nodes = {
											{ n = G.UIT.T, config = { text = localize("k_join_lobby_cap"), scale = 0.45, colour = G.C.UI.TEXT_LIGHT, vert = true, maxh = 1.4 } },
										},
									},
									{
										n = G.UIT.C,
										config = { align = "cm", padding = 0.1 },
										nodes = {
											{ n = G.UIT.R, config = { align = "cm" }, nodes = { b.join_by_code.node } },
											{ n = G.UIT.R, config = { align = "cm" }, nodes = { b.join_from_clipboard.node } },
										},
									},
								},
							},
							b.create_lobby.node,
						},
					},
				},
			},
		},
	}
end

-- ── Create Lobby overlay ─────────────────────────────────────────────────────
-- Gamemode (shape) picker, same grid-of-buttons style as the Practice overlay
-- below. Nemesis IS the 1v1 shape (its rotating pairing degenerates identically
-- to plain pairwise at exactly 2 players, see referee.lua) so there's no separate
-- "1v1" option. Ruleset (default Chocolate) is picked afterward, once inside the
-- lobby, via Lobby Options (ui/lobby/lobby_options.lua) -- not here.
G.FUNCS.mp_pvp_create_lobby = function()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
					{ n = G.UIT.T, config = { text = "Create Lobby", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_create_lobby_nemesis", label = { "Nemesis" }, colour = G.C.BLUE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_create_lobby_royale", label = { "Royale" }, colour = G.C.PURPLE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_create_lobby_manhunt", label = { "Manhunt" }, colour = G.C.RED, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_create_lobby_teams", label = { "Teams" }, colour = G.C.GREEN, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
			},
		}),
	})
end

G.FUNCS.mp_pvp_create_lobby_nemesis = function()
	G.FUNCS.exit_overlay_menu()
	PVP.pvp_create_private_lobby("pvp_chocolate")
end

G.FUNCS.mp_pvp_create_lobby_royale = function()
	G.FUNCS.exit_overlay_menu()
	PVP.pvp_create_private_lobby("pvp_royale")
end

G.FUNCS.mp_pvp_create_lobby_manhunt = function()
	G.FUNCS.exit_overlay_menu()
	PVP.pvp_create_private_lobby("pvp_manhunt")
end

G.FUNCS.mp_pvp_create_lobby_teams = function()
	G.FUNCS.exit_overlay_menu()
	PVP.pvp_create_private_lobby("pvp_teams")
end

-- ── Join overlays (copied from Speed's join.lua) ─────────────────────────────
G.FUNCS.mp_pvp_join_lobby_by_code = function()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			snap_back = true,
			contents = {
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.2, r = 0.1 },
					nodes = {
						{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
							{ n = G.UIT.T, config = { text = localize("k_lobby_code_cap"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
						} },
						{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
							create_text_input({ id = "mp_pvp_lobby_code_input", ref_table = { text = "" }, ref_value = "text", prompt_text = localize("k_lobby_code_cap"), max_length = 6, all_caps = true, w = 4, h = 0.6 }),
						} },
						{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
							UIBox_button({ id = "mp_pvp_join_lobby_confirm", button = "mp_pvp_join_lobby_confirm", colour = G.C.GREEN, minw = 2, minh = 0.6, label = { localize("k_join_lobby_cap") }, scale = 0.45 }),
						} },
					},
				},
			},
		}),
	})
end

G.FUNCS.mp_pvp_join_lobby_confirm = function()
	local code = G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("mp_pvp_lobby_code_input")
	if code and code.config and code.config.ref_table then
		local text = code.config.ref_table.text or ""
		text = text:match("^%s*(.-)%s*$") or ""
		if #text > 0 then
			G.FUNCS.exit_overlay_menu()
			PVP.pvp_join_lobby(text)
		end
	end
end

G.FUNCS.mp_pvp_join_lobby_from_clipboard = function()
	local code = (love.system.getClipboardText and love.system.getClipboardText()) or ""
	code = code:match("^%s*(.-)%s*$") or ""
	if #code > 0 then
		PVP.pvp_join_lobby(code)
	end
end

-- ── Practice overlay ─────────────────────────────────────────────────────────
-- Ruleset picker, not a gamemode picker: Royale/Nemesis both resolve to the same
-- ruleset_mp_vanilla + gamemode_mp_attrition as plain Vanilla and have no distinguishing
-- mechanic with a single practice player (see PVP._start_practice's header comment), so
-- they're intentionally not offered here.
G.FUNCS.mp_pvp_practice = function()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
					{ n = G.UIT.T, config = { text = "Practice", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_practice_chocolate", label = { "Chocolate" }, colour = G.C.BLUE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_practice_strawberry", label = { "Strawberry" }, colour = G.C.PURPLE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_practice_vanilla", label = { "Vanilla" }, colour = G.C.GREEN, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_practice_smallworld", label = { "Small", "World" }, colour = G.C.RED, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
				-- §17.6/§17.3: the 5th real ruleset -- was never wired into any
				-- player-facing picker at all (not practice-specific, project-wide).
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_practice_experimental", label = { "Experimental" }, colour = G.C.ORANGE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
			},
		}),
	})
end

G.FUNCS.mp_pvp_practice_chocolate = function()
	G.FUNCS.exit_overlay_menu()
	PVP._start_practice("pvp_chocolate")
end

G.FUNCS.mp_pvp_practice_strawberry = function()
	G.FUNCS.exit_overlay_menu()
	PVP._start_practice("pvp_strawberry")
end

G.FUNCS.mp_pvp_practice_vanilla = function()
	G.FUNCS.exit_overlay_menu()
	PVP._start_practice("pvp_vanilla")
end

G.FUNCS.mp_pvp_practice_smallworld = function()
	G.FUNCS.exit_overlay_menu()
	PVP._start_practice("pvp_smallworld")
end

G.FUNCS.mp_pvp_practice_experimental = function()
	G.FUNCS.exit_overlay_menu()
	PVP._start_practice("pvp_experimental")
end

-- ── Replay/Spectate overlay ───────────────────────────────────────────────
-- §22.2/§22.3: a small picker routing to the two list screens
-- (ui/replay/replay_browser.lua, ui/replay/spectate_browser.lua), same
-- overlay style as the Practice/Create Lobby pickers above.
G.FUNCS.mp_pvp_open_replay_menu = function()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
					{ n = G.UIT.T, config = { text = "Replay / Spectate", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_open_replay_browser_from_menu", label = { "My", "Replays" }, colour = G.C.BLUE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_open_spectate_browser_from_menu", label = { "Spectate" }, colour = G.C.PURPLE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
			},
		}),
	})
end

G.FUNCS.mp_pvp_open_replay_browser_from_menu = function()
	G.FUNCS.exit_overlay_menu()
	G.FUNCS.mp_pvp_open_replay_browser()
end

G.FUNCS.mp_pvp_open_spectate_browser_from_menu = function()
	G.FUNCS.exit_overlay_menu()
	G.FUNCS.mp_pvp_open_spectate_browser()
end
