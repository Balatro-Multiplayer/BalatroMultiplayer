-- Bridge GameModes: thin MPAPI.GameMode entry points that delegate into MP's own
-- ruleset/gamemode/pool-gating machinery (the BRIDGE approach — MP's composition
-- system stays authoritative; see the plan). Each maps a server/website game-mode
-- key (pvp_standard/pvp_vanilla/pvp_expanded/pvp_smallworld — the exact keys the
-- matchmaking server + web leaderboard expect, queried as `ranked:<key>`) onto an
-- MP ruleset + MP gamemode.
--
-- These MUST be loaded inside MPAPI.on_loaded so their GameObjects are tagged to
-- this mod (per-lobby action/gamemode routing depends on the owning mod id).
--
-- Blind selection and ante progression are intentionally NO-OPS here: MP's own
-- ui/game/round.lua + lovely wiring drive the nemesis/showdown blinds off
-- MP.LOBBY.config, so the API's reset_blinds/ease_ante overlay (api/gamemode/hooks.lua)
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
-- constant here, next to its definition in MP.PVP_GAMEMODES below, so those call
-- sites can't drift from this table's actual key.
MP.GamemodeKey = { PVP_STANDARD = "pvp_standard" }

MP.PVP_GAMEMODES = {
	pvp_standard = { ruleset = "ruleset_mp_standard_ranked", gamemode = "gamemode_mp_attrition", display = "Standard", has_ranked = true },
	pvp_expanded = { ruleset = "ruleset_mp_blitz", gamemode = "gamemode_mp_attrition", display = "Expanded", has_ranked = false },
	pvp_vanilla = { ruleset = "ruleset_mp_vanilla", gamemode = "gamemode_mp_attrition", display = "Vanilla", has_ranked = false },
	pvp_smallworld = { ruleset = "ruleset_mp_smallworld", gamemode = "gamemode_mp_attrition", display = "Small World", has_ranked = false },
	-- Royale (2-16 players): reuses attrition's blind-selection and a plain ruleset.
	-- Kept out of the uniform 1v1 loop below (own min/max_players, no ban_pick draft --
	-- that schedule hardcodes exactly 2 alternating actors) but still present in this
	-- table so lobby_bridge.lua's mirror_metadata / flow.lua's key lookup resolve
	-- "pvp_royale" to the correct internal ruleset/gamemode. `custom_bridge` marks
	-- entries (Royale, Nemesis) registered via their own MPAPI.GameMode call below
	-- instead of the uniform 1v1 loop -- not "is Royale specifically".
	pvp_royale = { ruleset = "ruleset_mp_vanilla", gamemode = "gamemode_mp_attrition", display = "Royale", has_ranked = false, custom_bridge = true },
	-- Nemesis (2-16 players): rotating no-repeat 1v1 pairing, re-paired each ante --
	-- same reasons as Royale for being out of the uniform loop (no ban_pick, own
	-- max_players). The `nemesis_pairing` flag (not `gamemode`/`ruleset`, which are
	-- shared with Royale) is what every pairing-aware piece of code branches on.
	pvp_nemesis = {
		ruleset = "ruleset_mp_vanilla",
		gamemode = "gamemode_mp_attrition",
		display = "Nemesis",
		has_ranked = false,
		custom_bridge = true,
		-- Read by lobby_bridge.lua's mirror_metadata to set MP.LOBBY.config.nemesis_pairing
		-- on EVERY client (not just the host, who's the only one that runs start_run below).
		nemesis_pairing = true,
	},
}

for key, def in pairs(MP.PVP_GAMEMODES) do
	if not def.custom_bridge then
	MPAPI.GameMode({
		key = key,
		-- Keep the literal `pvp_*` key (the server/web matchmaking taxonomy expects it);
		-- otherwise SMODS prefixes it to "mp_pvp_*" and MPAPI.GameModes[key] lookups miss.
		prefix_config = { key = false },
		display_name = def.display,
		has_ranked_mode = def.has_ranked,
		-- Pre-run deck+stake draft (matchmaking only): 9 random deck+stake pairs. A random
		-- player bans 1, the other bans 3, the first bans 3, then the other PICKS one of
		-- the final 2 to play on. Rendered in the matchmaking lobby status panel.
		ban_pick = {
			pool_size = 9,
			schedule = {
				{ actor = 1, action = "ban", count = 1 },
				{ actor = 2, action = "ban", count = 3 },
				{ actor = 1, action = "ban", count = 3 },
				{ actor = 2, action = "pick", count = 1 },
			},
		},
		-- PvP is 1v1 (attrition's single "enemy"): two players in every lobby type.
		min_players = 2,
		max_players = def.has_ranked and { public = 2, private = 2, ranked = 2 } or { public = 2, private = 2 },
		-- Best-effort start: point MP's lobby config at this mode's ruleset/gamemode,
		-- then hand off to MP's existing run-start flow. The MP.LOBBY <- API-lobby
		-- mirror (Phase 4/5) fills in deck/seed/host state; until then this is the
		-- entry point matchmaking/private-lobby start will call.
		start_run = function(self, deck_name, seed)
			MP.LOBBY.config.ruleset = def.ruleset
			MP.LOBBY.config.gamemode = def.gamemode
			if deck_name then
				MP.LOBBY.deck.back = deck_name
			end
			G.FUNCS.lobby_start_run(nil, { seed = seed })
		end,
		-- MP drives blinds itself; keep the API overlay inert (see header note).
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
end

-- Royale: same bridge shape as the loop above, but 2-16 players and no ban/pick
-- draft (the 2-actor ban_pick schedule above doesn't generalize to N players).
-- Elimination math (rank-and-cut bottom half) lives in pvp_api/referee.lua.
do
	local def = MP.PVP_GAMEMODES.pvp_royale
	MPAPI.GameMode({
		key = "pvp_royale",
		prefix_config = { key = false },
		display_name = def.display,
		has_ranked_mode = def.has_ranked,
		min_players = 2,
		max_players = { public = 16, private = 16 },
		start_run = function(self, deck_name, seed)
			MP.LOBBY.config.ruleset = def.ruleset
			MP.LOBBY.config.gamemode = def.gamemode
			if deck_name then
				MP.LOBBY.deck.back = deck_name
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

-- Nemesis: same bridge shape as Royale (2-16 players, no ban/pick draft). The
-- distinguishing MP.LOBBY.config.nemesis_pairing flag (every pairing-aware piece
-- of code -- referee.lua, MP.current_target_id, attrition.lua's bye check --
-- branches on it, since Royale and Nemesis otherwise share the identical
-- gamemode/ruleset pair) is set for EVERY client, host and guests alike, by
-- lobby_bridge.lua's mirror_metadata (keyed off this mode's `nemesis_pairing =
-- true` marker in MP.PVP_GAMEMODES.pvp_nemesis above) -- not here, since start_run
-- only ever runs on the host. Round-robin pairing itself lives in referee.lua.
do
	local def = MP.PVP_GAMEMODES.pvp_nemesis
	MPAPI.GameMode({
		key = "pvp_nemesis",
		prefix_config = { key = false },
		display_name = def.display,
		has_ranked_mode = def.has_ranked,
		min_players = 2,
		max_players = { public = 16, private = 16 },
		start_run = function(self, deck_name, seed)
			MP.LOBBY.config.ruleset = def.ruleset
			MP.LOBBY.config.gamemode = def.gamemode
			if deck_name then
				MP.LOBBY.deck.back = deck_name
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
