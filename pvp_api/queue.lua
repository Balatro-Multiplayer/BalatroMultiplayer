-- Matchmaking queue (ranked + casual), mirroring the Speedrun mod's _join_queue.
-- Ranked prepends the "ranked:" prefix so the server rates the match; casual uses the
-- bare gamemode key. On match_found the API auto-joins and fires lobby_ready; the
-- host stamps metadata and, after a short settle delay, starts the match.

-- Searching-state flag drives the Find Game button label (see the menu).
MP._searching = false

function MP._show_searching(on)
	MP._searching = on and true or false
	if MP._show_searching_state then
		MP._show_searching_state(on)
	end
end

function MP._is_searching()
	return MP._searching
end

function MP._join_queue(kind, gamemode_key)
	gamemode_key = gamemode_key or "pvp_standard"
	MP._pvp_kind = kind

	local gm = MPAPI.GameModes[gamemode_key]
	local mm_max = (gm and gm.max_players and gm.max_players.ranked) or 2
	local game_mode = (kind == MP.LobbyKind.RANKED) and (MP.LobbyKind.RANKED_PREFIX .. gamemode_key) or gamemode_key

	local handle = MPAPI.matchmaking.queue({
		mod_id = MP.id,
		game_mode = game_mode,
		min_players = 2,
		max_players = mm_max,
	})
	if not handle then
		sendWarnMessage("[pvp] failed to create matchmaking handle", "MULTIPLAYER")
		MP._pvp_kind = nil
		return
	end
	MP._match_handle = handle
	MP._show_searching(true)

	handle:on("error", function(err)
		sendWarnMessage("[pvp] matchmaking error: " .. tostring(err), "MULTIPLAYER")
		MP._match_handle = nil
		MP._show_searching(false)
	end)

	handle:on("queued", function(pos)
		sendDebugMessage("[pvp] queued at " .. tostring(pos), "MULTIPLAYER")
		MP._show_searching(true)
	end)

	handle:on("match_found", function(data)
		sendDebugMessage("[pvp] match_found " .. tostring(data and data.lobbyCode), "MULTIPLAYER")
	end)

	handle:on("lobby_ready", function(lobby)
		MP._pvp_kind = kind
		MP.setup_lobby_mirror(lobby)
		if lobby.is_host then
			lobby:set_metadata(MP.pvp_lobby_metadata(gamemode_key, kind))
		end
		-- lobby_ready fires from inside the lobby's own 'connected' handler, so signal
		-- ready now; the host auto-starts once every client has reported in (see
		-- MP.maybe_autostart). Re-announce a few times to cover the subscribe race.
		MP.signal_ready(true)
		MP.start_ready_resync()
		MP._show_searching(false)
	end)

	handle:on("match_resolved", function(_ratings)
		MP._match_handle = nil
	end)

	handle:on("left", function()
		MP._match_handle = nil
		MP._pvp_kind = nil
		MP._show_searching(false)
	end)
end

-- Host-only: report the finished match's placements to the server (ELO for ranked,
-- plain resolve for casual). One-shot per match. metric = each player's best PvP
-- score (the leaderboard's season-best column).
function MP.report_match_result(winner_id)
	local handle = MP._match_handle
	if not handle or not handle.report_result or winner_id == "*draw*" then
		return
	end
	if MP._result_reported then
		return
	end
	MP._result_reported = true
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
			metric = (MP.pvp_score_metric and MP.pvp_score_metric(p.id)) or 0,
		}
	end
	handle:report_result(placements, function()
		MP._match_handle = nil
	end)
end

function MP._cancel_queue()
	if MP._match_handle then
		MP._match_handle:leave()
		MP._match_handle = nil
	end
	MP._pvp_kind = nil
	MP._show_searching(false)
end

-- ── Find Game overlay + click handlers ───────────────────────────────────────
local function queue_button(label, fn_name, colour)
	return UIBox_button({ button = fn_name, label = label, colour = colour, minw = 3, minh = 0.9, scale = 0.42, col = true })
end

G.FUNCS.mp_pvp_find_game = function()
	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
					{ n = G.UIT.T, config = { text = "Find Game", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.15 },
					nodes = {
						{ n = G.UIT.C, config = { align = "cm", padding = 0.1, r = 0.2, colour = G.C.BLACK }, nodes = {
							{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = { queue_button({ "Standard" }, "mp_pvp_queue_ranked", G.C.RED) } },
							{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
								{ n = G.UIT.T, config = { text = localize("k_ranked_cap"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
							} },
						} },
						{ n = G.UIT.C, config = { align = "cm", padding = 0.1, r = 0.2, colour = G.C.BLACK }, nodes = {
							{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = { queue_button({ "Standard" }, "mp_pvp_queue_casual", G.C.BLUE) } },
							{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
								{ n = G.UIT.T, config = { text = localize("k_casual_cap"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
							} },
						} },
					},
				},
			},
		}),
	})
end

G.FUNCS.mp_pvp_queue_ranked = function()
	G.FUNCS.exit_overlay_menu()
	MP._join_queue(MP.LobbyKind.RANKED, "pvp_standard")
end

G.FUNCS.mp_pvp_queue_casual = function()
	G.FUNCS.exit_overlay_menu()
	MP._join_queue(MP.LobbyKind.CASUAL, "pvp_standard")
end

G.FUNCS.mp_pvp_cancel_queue = function()
	MP._cancel_queue()
end
