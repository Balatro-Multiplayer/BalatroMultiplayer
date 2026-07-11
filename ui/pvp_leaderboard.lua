-- PvP leaderboard overlay, built on the generic MPAPI.ui_leaderboard. Tabs are the
-- four server/web PvP gamemode keys; the metric is season-best single-blind score
-- (kind='score', higher is better). Pagination / own-rank footer / tabs live in MPAPI.

local DEFAULT_TAB = "pvp_standard"

-- Built lazily on first open (G.C colours + localization must be ready; this file
-- loads during the mod's main_file pass, before the game is fully up).
local _leaderboard
local function get_leaderboard()
	if _leaderboard then
		return _leaderboard
	end
	_leaderboard = MPAPI.ui_leaderboard({
		tabs = {
			{ key = "pvp_standard", label = "Standard", colour = G.C.RED },
			{ key = "pvp_expanded", label = "Expanded", colour = G.C.ORANGE },
			{ key = "pvp_vanilla", label = "Vanilla", colour = G.C.BLUE },
			{ key = "pvp_smallworld", label = "Small World", colour = G.C.GREEN },
		},
		columns = {
			{ header = function() return localize("k_rating_cap") end, colour = G.C.BLUE, width = 0.95, value = function(e) return tostring(e.rating or "?") end },
			{ header = function() return localize("k_best_score_cap") end, colour = G.C.PURPLE, width = 1.25, value = function(e) return tostring(e.seasonBest or "-") end },
			{ header = "W", header_colour = G.C.GREEN, colour = G.C.GREEN, width = 0.5, value = function(e) return tostring(e.wins or 0) end },
			{ header = "L", header_colour = G.C.RED, colour = G.C.RED, width = 0.5, value = function(e) return tostring(e.losses or 0) end },
		},
		empty_text = "No ranked players yet.",
		web_url = "https://new.balatromp.com/leaderboards",
		-- Leaderboards are the rated queue, so they carry the server's ranked prefix.
		fetch = function(tab_key, cb)
			MPAPI.matchmaking.get_leaderboard(MP.id, MP.LobbyKind.RANKED_PREFIX .. tab_key, nil, {}, cb)
		end,
	})
	return _leaderboard
end

MP.open_leaderboard = function(gamemode_key, page)
	get_leaderboard():open(gamemode_key or DEFAULT_TAB, page)
end

G.FUNCS.mp_pvp_open_leaderboard = function()
	get_leaderboard():open()
end
