-- Matchmaking queue (ranked + casual), mirroring the Speedrun mod's _join_queue.
-- Ranked prepends the "ranked:" prefix so the server rates the match; casual uses the
-- bare gamemode key. On match_found the API auto-joins and fires lobby_ready; the
-- host stamps metadata and, after a short settle delay, starts the match.

-- Searching-state flag drives the Find Game button label (see the menu).
PVP._searching = false

function PVP._show_searching(on)
	PVP._searching = on and true or false
	if PVP._show_searching_state then
		PVP._show_searching_state(on)
	end
end

function PVP._is_searching()
	return PVP._searching
end

function PVP._join_queue(kind, gamemode_key)
	gamemode_key = gamemode_key or PVP.GamemodeKey.PVP_CHOCOLATE
	PVP._pvp_kind = kind
	PVP.reset_ruleset_to_gamemode_default(gamemode_key)

	local gm = MPAPI.GameModes[gamemode_key]
	local mm_max_key = (kind == PVP.LobbyAccess.RANKED) and "ranked" or "public"
	local mm_max = (gm and gm.max_players and gm.max_players[mm_max_key]) or 2
	local game_mode = (kind == PVP.LobbyAccess.RANKED) and (PVP.LobbyAccess.RANKED_PREFIX .. gamemode_key) or gamemode_key

	local handle = MPAPI.matchmaking.queue({
		mod_id = PVP.id,
		game_mode = game_mode,
		min_players = 2,
		max_players = mm_max,
	})
	if not handle then
		sendWarnMessage("[pvp] failed to create matchmaking handle", "MULTIPLAYER")
		PVP._pvp_kind = nil
		return
	end
	PVP._match_handle = handle
	PVP._show_searching(true)

	handle:on("error", function(err)
		sendWarnMessage("[pvp] matchmaking error: " .. tostring(err), "MULTIPLAYER")
		PVP._match_handle = nil
		PVP._show_searching(false)
	end)

	handle:on("queued", function(pos)
		sendDebugMessage("[pvp] queued at " .. tostring(pos), "MULTIPLAYER")
		PVP._show_searching(true)
	end)

	handle:on("match_found", function(data)
		sendDebugMessage("[pvp] match_found " .. tostring(data and data.lobbyCode), "MULTIPLAYER")
	end)

	handle:on("lobby_ready", function(lobby)
		PVP._pvp_kind = kind
		PVP.setup_lobby_mirror(lobby)
		if lobby.is_host then
			lobby:set_metadata(PVP.pvp_lobby_metadata(gamemode_key, kind))
		end
		-- lobby_ready fires from inside the lobby's own 'connected' handler, so signal
		-- ready now; the host auto-starts once every client has reported in (see
		-- PVP.maybe_autostart). Re-announce a few times to cover the subscribe race.
		PVP.signal_ready(true)
		PVP.start_ready_resync()
		PVP._show_searching(false)
	end)

	handle:on("match_resolved", function(_ratings)
		PVP._match_handle = nil
	end)

	handle:on("left", function()
		PVP._match_handle = nil
		PVP._pvp_kind = nil
		PVP._show_searching(false)
	end)
end

-- Host-only: report the finished match's placements to the server (ELO for ranked,
-- plain resolve for casual). One-shot per match. metric = each player's best PvP
-- score (the leaderboard's season-best column).
function PVP.report_match_result(winner_id)
	local handle = PVP._match_handle
	if not handle or not handle.report_result or winner_id == "*draw*" then
		return
	end
	if PVP._result_reported then
		return
	end
	PVP._result_reported = true
	local lobby = MPAPI.get_current_lobby()
	if not lobby then
		return
	end
	local placements = {}
	for _, p in ipairs(lobby:get_players()) do
		placements[#placements + 1] = {
			playerId = p.id,
			place = (p.id == winner_id) and 1 or 2,
			performance = (p.id == winner_id) and 1 or 0,
			metric = (PVP.pvp_score_metric and PVP.pvp_score_metric(p.id)) or 0,
		}
	end
	handle:report_result(placements, function()
		PVP._match_handle = nil
	end)
end

function PVP._cancel_queue()
	if PVP._match_handle then
		PVP._match_handle:leave()
		PVP._match_handle = nil
	end
	PVP._pvp_kind = nil
	PVP._show_searching(false)
end

-- ── Find Game overlays + click handlers ──────────────────────────────────────
-- Ranked/Casual (top level), then a per-kind picker (grid-of-buttons style
-- matching the Practice/Create Lobby overlays). Ranked is always exactly 2
-- players -- matchmaking.service.ts's forfeit/ELO resolution is hardcoded for a
-- 2-player result -- so ranked only offers the four ruleset-only (Nemesis-shaped)
-- entries; casual additionally offers Royale/Manhunt/Teams (all on Chocolate,
-- the shared default ruleset) at up to 8 players.
G.FUNCS.mp_pvp_find_game = function()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
					{ n = G.UIT.T, config = { text = "Find Game", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_find_game_ranked", label = { "Ranked" }, colour = G.C.RED, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_find_game_casual", label = { "Casual" }, colour = G.C.BLUE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
			},
		}),
	})
end

G.FUNCS.mp_pvp_find_game_ranked = function()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
					{ n = G.UIT.T, config = { text = "Ranked", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_ranked_chocolate", label = { "Chocolate" }, colour = G.C.BLUE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_ranked_strawberry", label = { "Strawberry" }, colour = G.C.PURPLE, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_ranked_vanilla", label = { "Vanilla" }, colour = G.C.GREEN, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_ranked_smallworld", label = { "Small", "World" }, colour = G.C.RED, minw = 2.5, minh = 2.0, scale = 0.5, col = true }),
						} },
					},
				},
			},
		}),
	})
end

-- §17.4: previously only 2 of the 4 Nemesis-shaped rulesets (Chocolate,
-- Small World) had a casual queue button at all -- Vanilla and Strawberry
-- were ranked-only, with no casual path to them whatsoever. Now every
-- Nemesis ruleset gets its own explicit casual button, mirroring the ranked
-- grid above one-for-one -- "Casual Nemesis" was never really one option,
-- it was silently just Chocolate.
G.FUNCS.mp_pvp_find_game_casual = function()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
					{ n = G.UIT.T, config = { text = "Casual", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
				{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
					{ n = G.UIT.T, config = { text = "Nemesis", scale = 0.4, colour = G.C.UI.TEXT_LIGHT } },
				} },
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_casual_chocolate", label = { "Chocolate" }, colour = G.C.BLUE, minw = 2.5, minh = 1.4, scale = 0.4, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_casual_strawberry", label = { "Strawberry" }, colour = G.C.PURPLE, minw = 2.5, minh = 1.4, scale = 0.4, col = true }),
						} },
					},
				},
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_casual_vanilla", label = { "Vanilla" }, colour = G.C.GREEN, minw = 2.5, minh = 1.4, scale = 0.4, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_casual_smallworld", label = { "Small", "World" }, colour = G.C.ORANGE, minw = 2.5, minh = 1.4, scale = 0.4, col = true }),
						} },
					},
				},
				{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
					{ n = G.UIT.T, config = { text = "Other Modes", scale = 0.4, colour = G.C.UI.TEXT_LIGHT } },
				} },
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_casual_royale", label = { "Royale" }, colour = G.C.PURPLE, minw = 2.5, minh = 1.4, scale = 0.4, col = true }),
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_casual_manhunt", label = { "Manhunt" }, colour = G.C.RED, minw = 2.5, minh = 1.4, scale = 0.4, col = true }),
						} },
					},
				},
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
							UIBox_button({ button = "mp_pvp_queue_casual_teams", label = { "Teams" }, colour = G.C.GREEN, minw = 2.5, minh = 1.4, scale = 0.4, col = true }),
						} },
					},
				},
			},
		}),
	})
end

G.FUNCS.mp_pvp_queue_ranked_chocolate = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.RANKED, "pvp_chocolate")
end
G.FUNCS.mp_pvp_queue_ranked_strawberry = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.RANKED, "pvp_strawberry")
end
G.FUNCS.mp_pvp_queue_ranked_vanilla = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.RANKED, "pvp_vanilla")
end
G.FUNCS.mp_pvp_queue_ranked_smallworld = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.RANKED, "pvp_smallworld")
end

G.FUNCS.mp_pvp_queue_casual_chocolate = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.CASUAL, "pvp_chocolate")
end
G.FUNCS.mp_pvp_queue_casual_strawberry = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.CASUAL, "pvp_strawberry")
end
G.FUNCS.mp_pvp_queue_casual_vanilla = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.CASUAL, "pvp_vanilla")
end
G.FUNCS.mp_pvp_queue_casual_royale = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.CASUAL, "pvp_royale")
end
G.FUNCS.mp_pvp_queue_casual_manhunt = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.CASUAL, "pvp_manhunt")
end
G.FUNCS.mp_pvp_queue_casual_teams = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.CASUAL, "pvp_teams")
end
G.FUNCS.mp_pvp_queue_casual_smallworld = function()
	G.FUNCS.exit_overlay_menu()
	PVP._join_queue(PVP.LobbyAccess.CASUAL, "pvp_smallworld")
end

G.FUNCS.mp_pvp_cancel_queue = function()
	PVP._cancel_queue()
end
