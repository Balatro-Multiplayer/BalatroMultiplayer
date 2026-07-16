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

MP.PVP_GAMEMODES = {
	pvp_standard = { ruleset = "ruleset_mp_standard_ranked", gamemode = "gamemode_mp_attrition", display = "Standard", has_ranked = true },
	pvp_expanded = { ruleset = "ruleset_mp_blitz", gamemode = "gamemode_mp_attrition", display = "Expanded", has_ranked = false },
	pvp_vanilla = { ruleset = "ruleset_mp_vanilla", gamemode = "gamemode_mp_attrition", display = "Vanilla", has_ranked = false },
	pvp_smallworld = { ruleset = "ruleset_mp_smallworld", gamemode = "gamemode_mp_attrition", display = "Small World", has_ranked = false },
}

for key, def in pairs(MP.PVP_GAMEMODES) do
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
