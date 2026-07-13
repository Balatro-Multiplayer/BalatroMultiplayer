-- Host-authoritative PvP referee.
--
-- In the old TCP model the server was the referee: it tracked both players' state,
-- decided who reached the blind first, compared scores, decremented lives, and
-- declared win/loss. In the peer MQTT model there is no server adjudicator, so the
-- HOST client runs that logic. This file is a faithful Lua port of the legacy
-- server's src/actionHandlers.ts + Client.ts resolution rules, operating on a
-- per-player-id table (MP.REF). Every function is a no-op on non-host clients.
--
-- Authoritative outcomes are broadcast as pvp_* ActionTypes (see actions.lua); all
-- clients (including the host, via broadcast loopback) then apply them through the
-- existing client handlers, so the host and guest stay in lockstep.

MP.REF = MP.REF
	or {
		players = {},
		first_ready_at = nil,
		match_over = false,
		-- Nemesis-pairing (rotating no-repeat 1v1 duels, N>2): nemesis_of[id]=partner
		-- id for the current ante (absent = bye this ante); used_pairs is the
		-- no-repeat memory; last_bye_id lets bye assignment prefer rotating away
		-- from whoever byed last time.
		nemesis_of = {},
		used_pairs = {},
		nemesis_ante_computed_for = 0,
		last_bye_id = nil,
	}

local function is_host()
	local lobby = MPAPI.get_current_lobby()
	return lobby and lobby.is_host
end

local function broadcast(key, params)
	local lobby = MPAPI.get_current_lobby()
	if lobby and MPAPI.ActionTypes[key] then
		lobby:action(MPAPI.ActionTypes[key]):broadcast(params or {})
	end
end

-- The match ends the first time a game winner is declared. Every subsequent
-- resolution attempt (extra play_hand loopbacks, timer fails, N>2 progress-nudge
-- re-checks, etc. that still observe <=1 alive) must NOT re-broadcast pvp_win, or
-- clients replay the win/lose jingle and screen once per stray event instead of
-- once per match.
local function declare_win(winner_id)
	if MP.REF.match_over then
		return
	end
	MP.REF.match_over = true
	broadcast("pvp_win", { winner_id = winner_id })
end

local function ref_player(id)
	MP.REF.players[id] = MP.REF.players[id]
		or {
			id = id,
			score = MP.INSANE_INT.empty(),
			highest_score = MP.INSANE_INT.empty(),
			hands_left = 4,
			lives = MP.LOBBY.config.starting_lives or 4,
			skips = 0,
			ante = 1,
			furthest_blind = 0,
			played_this_blind = false,
			is_ready = false,
			first_ready = false,
			lives_blocker = false,
		}
	return MP.REF.players[id]
end

-- The two participant ids (host is the local player when we are host).
local function both_players()
	local lobby = MPAPI.get_current_lobby()
	if not lobby then
		return {}
	end
	local ids = {}
	for _, p in ipairs(lobby:get_players()) do
		ids[#ids + 1] = p.id
	end
	return ids
end

local function opponent_of(id)
	for _, oid in ipairs(both_players()) do
		if oid ~= id then
			return oid
		end
	end
	return nil
end

-- Recomputed fresh every call (never cached): self-heals on disconnect via the
-- existing PLAYER_LEFT-pruned both_players() roster, no separate table to maintain.
local function alive_ids()
	local ids = {}
	for _, id in ipairs(both_players()) do
		if ref_player(id).lives > 0 then
			ids[#ids + 1] = id
		end
	end
	return ids
end

-- Declares pvp_win once exactly one player remains alive (Royale's N-player analog
-- of the 2-player "opponent hit 0 lives" check). Returns true if it fired (or had
-- already fired -- see declare_win's match_over guard).
local function check_alive_win()
	local alive = alive_ids()
	if #alive <= 1 then
		declare_win(alive[1] or "*draw*")
		return true
	end
	return false
end

local function pair_key(a, b)
	if a > b then
		a, b = b, a
	end
	return a .. ":" .. b
end

-- Standard round-robin circle method: fix ids[1], rotate the remaining ids by
-- `offset` positions, then pair (1,2),(3,4),... Deterministic (unlike shuffle-and-
-- retry, which degenerates badly at small N) -- every rotation 0..#ids-2 yields a
-- distinct perfect matching, together covering every possible pair exactly once.
local function circle_round(ids, offset)
	local n = #ids
	local rotated = { ids[1] }
	for i = 1, n - 1 do
		local src = ((i - 1 + offset) % (n - 1)) + 2
		rotated[#rotated + 1] = ids[src]
	end
	local out = {}
	for i = 1, n, 2 do
		out[#out + 1] = { rotated[i], rotated[i + 1] }
	end
	return out
end

-- Recomputes MP.REF.nemesis_of for the current ante from the given alive roster:
-- a no-repeat (until every possible pair has been used, at which point the cycle
-- restarts) round-robin pairing, with a bye for odd counts that prefers not
-- repeating whoever byed last time.
local function compute_nemesis_pairing(alive)
	MP.REF.nemesis_of = {}
	if #alive < 2 then
		return
	end

	local ids = {}
	for _, id in ipairs(alive) do
		ids[#ids + 1] = id
	end
	for i = #ids, 2, -1 do
		local j = math.random(i)
		ids[i], ids[j] = ids[j], ids[i]
	end

	local bye_id = nil
	if #ids % 2 == 1 then
		local idx = 1
		for i, id in ipairs(ids) do
			if id ~= MP.REF.last_bye_id then
				idx = i
				break
			end
		end
		bye_id = table.remove(ids, idx)
	end

	local n = #ids
	local chosen = nil
	if n >= 2 then
		for offset = 0, n - 2 do
			local candidate = circle_round(ids, offset)
			local ok = true
			for _, p in ipairs(candidate) do
				if MP.REF.used_pairs[pair_key(p[1], p[2])] then
					ok = false
					break
				end
			end
			if ok then
				chosen = candidate
				break
			end
		end
		if not chosen then
			-- Every possible pair among the current alive set has already been used --
			-- the no-repeat cycle restarts.
			MP.REF.used_pairs = {}
			chosen = circle_round(ids, 0)
		end
		for _, p in ipairs(chosen) do
			MP.REF.nemesis_of[p[1]] = p[2]
			MP.REF.nemesis_of[p[2]] = p[1]
			MP.REF.used_pairs[pair_key(p[1], p[2])] = true
		end
	end
	MP.REF.last_bye_id = bye_id
end

-- Broadcasts the current ante's pairing to everyone (flat id -> partner-id-or-"" map
-- for every currently-alive id) so each client can resolve MP.current_target_id().
local function broadcast_nemesis_pairing()
	local payload = {}
	for _, id in ipairs(alive_ids()) do
		payload[id] = MP.REF.nemesis_of[id] or ""
	end
	broadcast("pvp_nemesis_pairing", { pairing = payload })
end

-- Best PvP score for a player (host referee state), as a plausibility-bounded number
-- for the matchmaking `metric` (season-best score column). Host-only.
function MP.pvp_score_metric(player_id)
	local pl = MP.REF and MP.REF.players and MP.REF.players[player_id]
	if not pl or not pl.score then
		return 0
	end
	return tonumber(MP.INSANE_INT.to_string(pl.highest_score or pl.score)) or 0
end

-- Reset all referee state at game start and stamp starting lives (option override
-- else the gamemode default). Mirrors Lobby.setPlayersLives + resetPlayers.
function MP.referee_reset(starting_lives)
	if not is_host() then
		return
	end
	MP.REF.players = {}
	MP.REF.first_ready_at = nil
	if MP.REF.ready_tracker then
		MP.REF.ready_tracker:reset()
	end
	MP.REF.nemesis_of = {}
	MP.REF.used_pairs = {}
	MP.REF.nemesis_ante_computed_for = 0
	MP.REF.last_bye_id = nil
	MP.REF.match_over = false
	MP._result_reported = false
	local lives = starting_lives or MP.LOBBY.config.starting_lives or 4
	for _, id in ipairs(both_players()) do
		local pl = ref_player(id)
		pl.lives = lives
		pl.score = MP.INSANE_INT.empty()
		pl.hands_left = 4
		pl.played_this_blind = false
		pl.is_ready = false
		pl.first_ready = false
		pl.lives_blocker = false
	end
	-- Authoritative starting lives to both clients.
	broadcast("pvp_player_lives", { player_id = "*all*", lives = lives })

	if MP.LOBBY.config.nemesis_pairing then
		compute_nemesis_pairing(alive_ids())
		MP.REF.nemesis_ante_computed_for = 1
		broadcast_nemesis_pairing()
	end
end

-- loseLife(): decrement once per round (guarded by lives_blocker, re-armed by
-- newRound). Broadcasts the loser's new life count to everyone.
local function lose_life(pl)
	if pl.lives_blocker then
		return
	end
	pl.lives = pl.lives - 1
	pl.lives_blocker = true
	broadcast("pvp_player_lives", { player_id = pl.id, lives = pl.lives })
end

-- readyBlind: both ready -> compute firstPlayer, reset per-blind state, start blind.
-- The 2-player path (below) is untouched. For N>2 (Royale) there's no meaningful
-- "first player" HUD ordering, so that concept is dropped and readiness is just
-- "every alive player has readied", via MPAPI.ReadyTracker()'s set/is_ready/reset
-- primitives (checked against alive_ids() ourselves rather than its own all_ready(),
-- which loops the full lobby roster and would stall on eliminated spectators).
function MP.referee_on_ready_blind(from)
	if not is_host() then
		return
	end

	if #both_players() > 2 then
		MP.REF.ready_tracker = MP.REF.ready_tracker or MPAPI.ReadyTracker()
		MP.REF.ready_tracker:set(from, true)
		local alive = alive_ids()
		local all_ready = true
		for _, id in ipairs(alive) do
			if not MP.REF.ready_tracker:is_ready(id) then
				all_ready = false
				break
			end
		end
		if all_ready then
			MP.REF.ready_tracker:reset()
			for _, id in ipairs(alive) do
				local pl = ref_player(id)
				pl.score = MP.INSANE_INT.empty()
				pl.hands_left = 4
				pl.played_this_blind = false
			end
			broadcast("pvp_start_blind", { first_player = "" })
		end
		return
	end

	local me = ref_player(from)
	me.is_ready = true
	local opp = opponent_of(from)
	local enemy = opp and ref_player(opp)

	if not me.first_ready and not (enemy and enemy.is_ready) and not (enemy and enemy.first_ready) then
		me.first_ready = true
	end

	if enemy and me.is_ready and enemy.is_ready then
		me.is_ready = false
		enemy.is_ready = false
		me.score = MP.INSANE_INT.empty()
		enemy.score = MP.INSANE_INT.empty()
		me.hands_left = 4
		enemy.hands_left = 4
		me.played_this_blind = false
		enemy.played_this_blind = false

		-- firstPlayer is the id of whichever player readied first.
		local first_id = me.first_ready and from or (enemy.first_ready and opp or nil)
		broadcast("pvp_start_blind", { first_player = first_id or "" })
	end
end

function MP.referee_on_unready_blind(from)
	if not is_host() then
		return
	end
	ref_player(from).is_ready = false
end

-- Pure: given the 2-player round-end state, decides whether the round is over
-- yet and, if so, who's ahead. Returns nil if the trailing player still has
-- hands left (round not over). roundWinner = the higher score; on an exact tie
-- the FIRST player (a) is the nominal winner (a_lt_b is false when scores are
-- equal) but no life is lost either way (see the equal-handling in
-- try_resolve_round below) -- extracted from try_resolve_round so this
-- decision is independently testable without a live lobby (see
-- ClaudeControl/suites/pvp/referee.lua, which verified this tie-break
-- direction live against the actual expression below).
function MP.referee_resolve_2p_round(a, b)
	local a_lt_b = MP.INSANE_INT.greater_than(b.score, a.score) -- a.score < b.score
	local b_lt_a = MP.INSANE_INT.greater_than(a.score, b.score)
	local equal = MP.INSANE_INT.equal(a.score, b.score)

	local trigger = (a.hands_left < 1 and a_lt_b)
		or (b.hands_left < 1 and b_lt_a)
		or (a.hands_left < 1 and b.hands_left < 1)
	if not trigger then
		return nil
	end

	local winner = a_lt_b and b or a
	local loser = (winner.id == a.id) and b or a
	return { winner = winner, loser = loser, equal = equal }
end

-- The score-comparison round resolution (playHand path). Called after a player's
-- score/hands are updated. Ends the round when the trailing player is out of hands
-- or both are, decided by InsaneInt score with exact-equality = draw.
--
-- Branches on total lobby size (both_players()), not alive count: a lobby that
-- started at 2 always uses the pairwise rule below, untouched. A lobby that
-- started at N>2 always uses the rank-and-cut rule, even after it narrows down to
-- 2 alive -- at exactly 2 alive, floor(2/2)=1 degenerates to "the lower scorer of
-- the pair loses a life", so the ending plays out identically to a 1v1 anyway.
local function try_resolve_round()
	if MP.REF.match_over then
		return
	end
	local total = both_players()
	if #total < 2 then
		return
	end

	if #total == 2 then
		local a, b = ref_player(total[1]), ref_player(total[2])
		local outcome = MP.referee_resolve_2p_round(a, b)
		if not outcome then
			return
		end
		local winner, loser, equal = outcome.winner, outcome.loser, outcome.equal

		if not equal then
			lose_life(loser)
			if a.lives <= 0 or b.lives <= 0 then
				local game_winner = (a.lives > b.lives) and a or b
				winner.first_ready = false
				loser.first_ready = false
				declare_win(game_winner.id)
				return
			end
		end

		winner.first_ready = false
		loser.first_ready = false
		broadcast("pvp_end_pvp", { loser_id = (not equal) and loser.id or "", pvp_timer_lost = false })
		return
	end

	-- N>2: wait until every alive player is out of hands, then resolve once for the
	-- whole lobby -- either Royale's rank-and-cut, or Nemesis's per-pair scoring.
	-- Sharing this gate means there is always exactly one pvp_end_pvp/pvp_win
	-- broadcast per round, never one per pair: pvp_end_pvp forces every client into
	-- NEW_ROUND, so a per-pair broadcast would corrupt other pairs' still-open rounds.
	local alive = alive_ids()
	if #alive < 2 then
		return
	end
	for _, id in ipairs(alive) do
		if ref_player(id).hands_left >= 1 then
			return
		end
	end

	if MP.LOBBY.config.nemesis_pairing then
		-- Nemesis: resolve every still-live pair independently (a pair with one side
		-- now eliminated/disconnected is skipped -- the survivor is untouched this
		-- round, equivalent to a bye). Both sides are already guaranteed hands_left<1
		-- by the gate above, so no early-exit-while-trailing nuance is needed here
		-- (unlike the 2-player branch, where responsiveness matters more).
		local seen = {}
		for _, ida in ipairs(alive) do
			ref_player(ida).first_ready = false
			local idb = MP.REF.nemesis_of[ida]
			if idb and not seen[ida] and not seen[idb] and ref_player(idb).lives > 0 then
				local a, b = ref_player(ida), ref_player(idb)
				if not MP.INSANE_INT.equal(a.score, b.score) then
					local loser = MP.INSANE_INT.greater_than(b.score, a.score) and a or b
					lose_life(loser)
				end
				seen[ida] = true
				seen[idb] = true
			end
		end
	else
		-- Royale: rank by score and the bottom floor(N/2) (min 1) lose a life. Ties at
		-- the cutoff are folded into the loser set (not a strict headcount) so a tied
		-- cluster isn't split arbitrarily -- unless the tie reaches every alive player,
		-- in which case (mirroring the 1v1 exact-tie "nobody loses" rule) nobody loses
		-- this round.
		local ranked = {}
		for _, id in ipairs(alive) do
			ranked[#ranked + 1] = ref_player(id)
		end
		table.sort(ranked, function(x, y)
			return MP.INSANE_INT.greater_than(y.score, x.score)
		end)

		local cutoff_idx = math.max(1, math.floor(#ranked / 2))
		local cutoff_score = ranked[cutoff_idx].score
		local losers = {}
		for _, pl in ipairs(ranked) do
			pl.first_ready = false
			if not MP.INSANE_INT.greater_than(pl.score, cutoff_score) then
				losers[#losers + 1] = pl
			end
		end

		if #losers < #ranked then
			for _, pl in ipairs(losers) do
				lose_life(pl)
			end
		end
	end

	if not check_alive_win() then
		broadcast("pvp_end_pvp", { loser_id = "", pvp_timer_lost = false })
	end
end

-- playHand: store sender score/hands, then attempt resolution.
function MP.referee_on_play_hand(from, params)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	pl.score = MP.INSANE_INT.from_string(tostring(params.score or "0"))
	pl.hands_left = math.floor(tonumber(params.handsLeft) or pl.hands_left)
	if params.skips then
		pl.skips = tonumber(params.skips) or pl.skips
	end
	if params.lives then
		pl.lives = tonumber(params.lives) or pl.lives
	end
	if MP.INSANE_INT.greater_than(pl.score, MP.INSANE_INT.empty()) then
		pl.played_this_blind = true
	end
	if MP.INSANE_INT.greater_than(pl.score, pl.highest_score) then
		pl.highest_score = pl.score
	end
	try_resolve_round()
end

function MP.referee_on_skip(from, params)
	if not is_host() then
		return
	end
	ref_player(from).skips = tonumber(params.skips) or 0
end

function MP.referee_on_set_ante(from, params)
	if not is_host() then
		return
	end
	ref_player(from).ante = tonumber(params.ante) or ref_player(from).ante

	-- Nemesis-pairing: recompute once per ante, triggered by whichever alive
	-- player's ease_ante() reports it first. Safe against overlapping with an
	-- in-flight resolution for the OLD ante, because a client can only call
	-- ease_ante() (and thus report a new ante at all) after receiving that ante's
	-- pvp_end_pvp/pvp_win -- which itself can't be sent until try_resolve_round's
	-- batch-resolve for the old ante has already completed.
	if MP.LOBBY.config.nemesis_pairing then
		local ante = tonumber(params.ante)
		if ante and ante > MP.REF.nemesis_ante_computed_for then
			MP.REF.nemesis_ante_computed_for = ante
			compute_nemesis_pairing(alive_ids())
			broadcast_nemesis_pairing()
		end
	end
end

function MP.referee_on_set_furthest_blind(from, params)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	pl.furthest_blind = tonumber(params.furthestBlind) or pl.furthest_blind
end

-- newRound: re-arm loseLife for the next round (resetBlocker).
function MP.referee_on_new_round(from)
	if not is_host() then
		return
	end
	ref_player(from).lives_blocker = false
end

-- failRound: mode-dependent life loss (death_on_round_loss) and match end.
--
-- The general (attrition/Royale/Nemesis) path used to declare pvp_win against
-- opponent_of(from) unconditionally -- at N>2 that's an arbitrary bystander, not
-- necessarily the actual sole survivor, since death_on_round_loss fires on any
-- failed blind, not just nemesis-boss rounds. Fixed to the same "exactly 1 alive"
-- check try_resolve_round uses. For N>2, whether or not this failure eliminated
-- them, force their hands_left to 0 and re-run try_resolve_round(): the batch-wait
-- gate there only progresses once every CURRENTLY alive player is done, and without
-- this nudge a failed-but-not-eliminated player's frozen hands_left (or a now-
-- excluded eliminated one, whose elimination might be exactly what the gate was
-- waiting on) would leave the rest of the lobby stuck.
function MP.referee_on_fail_round(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	if MP.LOBBY.config.death_on_round_loss then
		lose_life(pl)
	end
	if pl.lives == 0 then
		if check_alive_win() then
			return
		end
	end
	if #both_players() > 2 then
		pl.hands_left = 0
		try_resolve_round()
	end
end

-- failTimer (non-PvP ante timer): sender loses a life; match ends only when exactly
-- one player remains alive. Same N>2 progress-nudge as referee_on_fail_round.
function MP.referee_on_fail_timer(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	lose_life(pl)
	if pl.lives == 0 and check_alive_win() then
		return
	end
	if #both_players() > 2 then
		pl.hands_left = 0
		try_resolve_round()
	end
end

-- failPvPTimer: sender loses the PvP round on the timer (always a life; round or
-- match). The 2-player path ends the round directly (there's only one round in
-- flight, so it's safe). For N>2, a single player's timeout must NOT broadcast
-- pvp_end_pvp directly -- that forces every client into NEW_ROUND, corrupting any
-- other pair/comparison still in progress -- so it defers to the same batch-wait
-- gate as everything else via try_resolve_round(). This also fixes a pre-existing
-- bug: this function used to broadcast pvp_end_pvp unconditionally even at N>2.
function MP.referee_on_fail_pvp_timer(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	lose_life(pl)
	if pl.lives == 0 and check_alive_win() then
		return
	end
	if #both_players() == 2 then
		pl.first_ready = false
		local opp = opponent_of(from)
		if opp then
			ref_player(opp).first_ready = false
		end
		broadcast("pvp_end_pvp", { loser_id = from, pvp_timer_lost = true })
		return
	end
	pl.hands_left = 0
	try_resolve_round()
end
