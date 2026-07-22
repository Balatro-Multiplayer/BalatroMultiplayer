-- Bridge GameModes: thin MPAPI.GameMode entry points that delegate into PVP's own
-- ruleset/gamemode/pool-gating machinery (the BRIDGE approach — PVP's composition
-- system stays authoritative; see the plan). Each maps a server/website game-mode
-- key (pvp_chocolate/pvp_vanilla/pvp_strawberry/pvp_smallworld/pvp_royale/
-- pvp_manhunt/pvp_teams — the exact keys the matchmaking server + web leaderboard
-- expect, queried as `ranked:<key>`) onto a PVP ruleset + shape.
--
-- These MUST be loaded inside MPAPI.on_loaded so their GameObjects are tagged to
-- this mod (per-lobby action/gamemode routing depends on the owning mod id).
--
-- Blind selection and ante progression are intentionally NO-OPS here: PVP's own
-- ui/game/round.lua + lovely wiring drive the nemesis/showdown blinds off
-- PVP.LOBBY.config, so the API's reset_blinds/ease_ante overlay (api/gamemode/hooks.lua)
-- must not also mutate the blinds. get_blinds_by_ante returns nothing so the API
-- overlay is a harmless no-op; on_ante_change does nothing. The one API-side hook we
-- do use is on_player_forfeit -> check_single_survivor (win when the opponent quits).

-- The defined winning code path: a gamemode's on_player_forfeit just returns
-- { winner = player_id } and never touches an ActionType or a lobby object.
MPAPI.on_winner_declared(function(winner_id)
	local lobby = MPAPI.get_current_lobby()
	if lobby and MPAPI.ActionTypes["pvp_player_won"] then
		lobby:action(MPAPI.ActionTypes["pvp_player_won"]):broadcast({ player_id = winner_id })
	end
end)

-- The default/fallback queue mode key, referenced as a raw string across several
-- consumer files (flow.lua, queue.lua, pvp_leaderboard.lua) -- kept as one named
-- constant here, next to its definition in PVP.PVP_GAMEMODES below, so those call
-- sites can't drift from this table's actual key. Also the default ruleset every
-- shape (Nemesis/Royale/Manhunt/Teams) creates a private lobby on, overridable
-- afterward via the in-lobby ruleset picker (ui/lobby/lobby_options.lua).
PVP.GamemodeKey = { PVP_CHOCOLATE = "pvp_chocolate" }

-- There is no separate "plain 1v1" shape: Nemesis's rotating pairing degenerates
-- identically to a plain pairwise 1v1 at exactly 2 players (see referee.lua's
-- try_resolve_round comments), so every ruleset-only entry below IS Nemesis --
-- one shape covers both. Ranked play is always exactly 2 players (matchmaking's
-- ELO/forfeit resolution -- BalatroMultiplayerServer's autoForfeitMatch -- is
-- hardcoded for a 2-player result and would tie multiple players for 1st with
-- more); casual/private go up to 8/16.
PVP.PVP_GAMEMODES = {
	pvp_chocolate = { ruleset = "ruleset_mp_chocolate_ranked", gamemode = "gamemode_mp_attrition", display = "Chocolate", has_ranked = true, custom_bridge = true, nemesis_pairing = true },
	pvp_strawberry = { ruleset = "ruleset_mp_strawberry", gamemode = "gamemode_mp_attrition", display = "Strawberry", has_ranked = true, custom_bridge = true, nemesis_pairing = true },
	pvp_vanilla = { ruleset = "ruleset_mp_vanilla", gamemode = "gamemode_mp_attrition", display = "Vanilla", has_ranked = true, custom_bridge = true, nemesis_pairing = true },
	pvp_smallworld = { ruleset = "ruleset_mp_smallworld", gamemode = "gamemode_mp_attrition", display = "Small World", has_ranked = true, custom_bridge = true, nemesis_pairing = true },
	-- Royale/Manhunt/Teams (2-16 players): never ranked (no per-ruleset ELO ladder
	-- for these), default to the Chocolate ruleset like everything else (swappable
	-- in Lobby Options for private lobbies), casual-queueable at up to 8 players.
	pvp_royale = { ruleset = "ruleset_mp_chocolate_ranked", gamemode = "gamemode_mp_attrition", display = "Royale", has_ranked = false, custom_bridge = true },
	pvp_manhunt = { ruleset = "ruleset_mp_chocolate_ranked", gamemode = "gamemode_mp_attrition", display = "Manhunt", has_ranked = false, custom_bridge = true, manhunt = true },
	pvp_teams = { ruleset = "ruleset_mp_chocolate_ranked", gamemode = "gamemode_mp_attrition", display = "Teams", has_ranked = false, custom_bridge = true, team_based = true },
}

-- Pre-run deck+stake draft (matchmaking only, exactly 2 players -- see
-- run_lifecycle.lua's ban_pick gate): 9 random deck+stake pairs. A random player
-- bans 1, the other bans 3, the first bans 3, then the other PICKS one of the
-- final 2 to play on. Rendered in the matchmaking lobby status panel. Shared by
-- all four ranked-eligible (Nemesis-shaped) entries below.
local BAN_PICK = {
	pool_size = 9,
	schedule = {
		{ actor = 1, action = "ban", count = 1 },
		{ actor = 2, action = "ban", count = 3 },
		{ actor = 1, action = "ban", count = 3 },
		{ actor = 2, action = "pick", count = 1 },
	},
}

-- The four ruleset-only (Nemesis-shaped) entries: identical registration shape,
-- parameterized per ruleset. Round-robin pairing degenerates to plain pairwise at
-- 2 players (ranked) and behaves as real rotating Nemesis at N>2 (casual/private).
for _, key in ipairs({ "pvp_chocolate", "pvp_strawberry", "pvp_vanilla", "pvp_smallworld" }) do
	local def = PVP.PVP_GAMEMODES[key]
	MPAPI.GameMode({
		key = key,
		-- Keep the literal `pvp_*` key (the server/web matchmaking taxonomy expects it);
		-- otherwise SMODS prefixes it to "mp_pvp_*" and MPAPI.GameModes[key] lookups miss.
		prefix_config = { key = false },
		display_name = def.display,
		has_ranked_mode = def.has_ranked,
		ban_pick = BAN_PICK,
		min_players = 2,
		max_players = { public = 8, private = 16, ranked = 2 },
		-- PVP.LOBBY.config.ruleset/gamemode are already correctly populated by the
		-- metadata mirror (lobby_bridge.lua's mirror_metadata) by the time start_run
		-- runs -- setting them here from `def` would stomp a ruleset the host chose
		-- via the in-lobby picker (Lobby Options), reverting it back to this
		-- gamemode key's default every time the match actually starts.
		start_run = function(self, deck_name, seed)
			if deck_name then
				PVP.LOBBY.deck.back = deck_name
			end
			G.FUNCS.lobby_start_run(nil, { seed = seed })
		end,
		-- PVP drives blinds itself; keep the API overlay inert (see header note).
		get_blinds_by_ante = function(self, ante)
			return nil, nil, nil
		end,
		on_ante_change = function(self, ante) end,
		-- Host-authoritative: when the opponent forfeits/leaves, the last player
		-- standing wins. The registered winner handler above performs the broadcast.
		on_player_forfeit = function(self, player_id)
			local winner_id = self:check_single_survivor(player_id)
			if not winner_id then
				return
			end
			return { winner = winner_id }
		end,
	})
end

-- Royale: no ban/pick draft (the 2-actor ban_pick schedule above doesn't
-- generalize to N players). Elimination math (rank-and-cut bottom half) lives in
-- pvp_api/referee.lua.
do
	local def = PVP.PVP_GAMEMODES.pvp_royale
	MPAPI.GameMode({
		key = "pvp_royale",
		prefix_config = { key = false },
		display_name = def.display,
		has_ranked_mode = def.has_ranked,
		min_players = 2,
		max_players = { public = 8, private = 16 },
		start_run = function(self, deck_name, seed)
			if deck_name then
				PVP.LOBBY.deck.back = deck_name
			end
			G.FUNCS.lobby_start_run(nil, { seed = seed })
		end,
		get_blinds_by_ante = function(self, ante)
			return nil, nil, nil
		end,
		on_ante_change = function(self, ante) end,
		on_player_forfeit = function(self, player_id)
			local winner_id = self:check_single_survivor(player_id)
			if not winner_id then
				return
			end
			return { winner = winner_id }
		end,
	})
end

-- Manhunt: same bridge shape as Royale (no ban/pick draft). Win/loss is
-- asymmetric (Runner vs best-Hunter, not "last one standing"), so forfeit
-- handling calls the dedicated referee helper instead of the generic
-- check_single_survivor -- a Hunter leaving doesn't end the match by itself.
do
	local def = PVP.PVP_GAMEMODES.pvp_manhunt
	MPAPI.GameMode({
		key = "pvp_manhunt",
		prefix_config = { key = false },
		display_name = def.display,
		has_ranked_mode = def.has_ranked,
		min_players = 2,
		max_players = { public = 8, private = 16 },
		start_run = function(self, deck_name, seed)
			if deck_name then
				PVP.LOBBY.deck.back = deck_name
			end
			G.FUNCS.lobby_start_run(nil, { seed = seed })
		end,
		get_blinds_by_ante = function(self, ante)
			return nil, nil, nil
		end,
		on_ante_change = function(self, ante) end,
		-- Broadcasts pvp_win (winner_team_id) itself -- unlike check_single_survivor's
		-- callers above, NOT returned as { winner = ... }: MPAPI._handle_gamemode_result
		-- would hand a team_id string ("HUNTER") to the generic on_winner_declared
		-- handler above, which broadcasts pvp_player_won with THAT as player_id -- a
		-- string no real client id ever matches, so every client would wrongly resolve
		-- to "I lost".
		on_player_forfeit = function(self, player_id)
			PVP.referee_manhunt_on_forfeit(player_id)
		end,
	})
end

-- Teams: same bridge shape. A whole team's roster leaving ends the match for the
-- other team; a single member leaving does not (see PVP.referee_teams_on_forfeit).
do
	local def = PVP.PVP_GAMEMODES.pvp_teams
	MPAPI.GameMode({
		key = "pvp_teams",
		prefix_config = { key = false },
		display_name = def.display,
		has_ranked_mode = def.has_ranked,
		min_players = 2,
		max_players = { public = 8, private = 16 },
		start_run = function(self, deck_name, seed)
			if deck_name then
				PVP.LOBBY.deck.back = deck_name
			end
			G.FUNCS.lobby_start_run(nil, { seed = seed })
		end,
		get_blinds_by_ante = function(self, ante)
			return nil, nil, nil
		end,
		on_ante_change = function(self, ante) end,
		-- Same reason as Manhunt's forfeit hook above: broadcasts pvp_win itself,
		-- not returned as { winner = ... }.
		on_player_forfeit = function(self, player_id)
			PVP.referee_teams_on_forfeit(player_id)
		end,
	})
end
