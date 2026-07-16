-- Pause-menu run actions: Forfeit + Seed-change vote (mirrors Speed's
-- objects/actions/forfeit.lua + objects/actions/seed_vote.lua + ui/lobby/seed_vote.lua).
-- Loaded inside MPAPI.on_loaded (pvp_api dir) so the ActionTypes are tagged to this mod.
-- prefix_config.key = false keeps the literal pvp_* keys (see actions.lua for why).

-- Random 8-char run seed (uppercase alphanumeric), matching the game's seed alphabet.
function MP.generate_seed()
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	local s = ""
	for _ = 1, 8 do
		local n = math.random(#chars)
		s = s .. chars:sub(n, n)
	end
	return s
end

-- ── Forfeit ──────────────────────────────────────────────────────────────────
-- Broadcast reaches every client. Only the host does anything: it runs the gamemode's
-- forfeit hook (check_single_survivor -> pvp_player_won), the exact path a mid-match
-- leave takes (pvp_api/lobby_bridge.lua). pvp_player_won then gives the forfeiter the
-- lose screen and the opponent the win -- so there is no separate/duplicate lose here.
MPAPI.ActionType({
	key = "pvp_forfeit",
	prefix_config = { key = false },
	on_receive = function(_at, from_player_id, _params)
		if G.STAGE ~= G.STAGES.RUN then
			return
		end
		local lobby = MPAPI.get_current_lobby()
		if not lobby then
			return
		end
		local instance = lobby.get_gamemode_instance and lobby:get_gamemode_instance()
		if instance and instance.on_player_forfeit then
			MPAPI._handle_gamemode_result(instance, instance:on_player_forfeit(from_player_id))
		end
	end,
})

function MP.pvp_forfeit()
	local lobby = MPAPI.get_current_lobby()
	if not lobby or not MPAPI.ActionTypes["pvp_forfeit"] then
		return
	end
	lobby:action(MPAPI.ActionTypes["pvp_forfeit"]):broadcast({})
end

-- ── Seed-change vote ─────────────────────────────────────────────────────────
-- A unanimous vote restarts the match on a fresh seed. Each client tallies the vote
-- independently (broadcast reaches all); the host restarts on unanimity.
MPAPI.ActionType({
	key = "pvp_seed_vote",
	prefix_config = { key = false },
	on_receive = function(_at, from_player_id, _params)
		MP.register_seed_vote(from_player_id)
	end,
})

-- Restart the run on the new seed WITHOUT re-running the deck+stake draft: reuse the
-- local start path (action_start_game) with the already-pinned deck. Broadcast by the
-- host on a unanimous vote; every client (host included via loopback) applies it.
MPAPI.ActionType({
	key = "pvp_reseed",
	prefix_config = { key = false },
	on_receive = function(_at, _from, params)
		local lobby = MPAPI.get_current_lobby()
		if lobby and lobby.is_host then
			MP.referee_reset(MP.LOBBY.config.starting_lives)
		end
		MP.dispatch_action("startGame", { seed = params.seed, stake = MP.LOBBY.deck.stake })
	end,
})

function MP.cast_seed_vote()
	local lobby = MPAPI.get_current_lobby()
	if not lobby or not MPAPI.ActionTypes["pvp_seed_vote"] then
		return
	end
	lobby:action(MPAPI.ActionTypes["pvp_seed_vote"]):broadcast({})
end

-- Runs on every client when any vote arrives. Tallies via the lobby VoteTracker, shows
-- progress in chat, and (host only) restarts on a fresh seed once the vote is unanimous.
function MP.register_seed_vote(voter_id)
	local lobby = MPAPI.get_current_lobby()
	if not lobby or not MP.lobby or not MP.lobby.seed_votes then
		return
	end
	local count, total, unanimous = MP.lobby.seed_votes:record(voter_id)

	if MPAPI.chat and MPAPI.chat.addMessage then
		MPAPI.chat.addMessage(
			(localize("k_seed_vote") or "Vote to change seed") .. ": " .. count .. "/" .. total,
			G.C.BLUE
		)
	end

	if lobby.is_host and unanimous and MPAPI.ActionTypes["pvp_reseed"] then
		MP.lobby.seed_votes:reset()
		lobby:action(MPAPI.ActionTypes["pvp_reseed"]):broadcast({ seed = MP.generate_seed() })
	end
end
