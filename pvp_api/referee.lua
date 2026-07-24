-- Host-authoritative PvP referee.
--
-- In the old TCP model the server was the referee: it tracked both players' state,
-- decided who reached the blind first, compared scores, decremented lives, and
-- declared win/loss. In the peer MQTT model there is no server adjudicator, so the
-- HOST client runs that logic. This file is a faithful Lua port of the legacy
-- server's src/actionHandlers.ts + Client.ts resolution rules, operating on a
-- per-player-id table (PVP.REF). Every function is a no-op on non-host clients.
--
-- Authoritative outcomes are broadcast as pvp_* ActionTypes (see actions.lua); all
-- clients (including the host, via broadcast loopback) then apply them through the
-- existing client handlers, so the host and guest stay in lockstep.

PVP.REF = PVP.REF
	or {
		players = {},
		first_ready_at = nil,
		-- Nemesis-pairing (rotating no-repeat 1v1 duels, N>2): nemesis_of[id]=partner
		-- id for the current ante (absent = bye this ante); used_pairs is the
		-- no-repeat memory; last_bye_id lets bye assignment prefer rotating away
		-- from whoever byed last time.
		nemesis_of = {},
		used_pairs = {},
		nemesis_ante_computed_for = 0,
		last_bye_id = nil,
		-- Teams: shared per-team life pools ({A=n, B=n}). Unused by Manhunt, which
		-- keeps asymmetric per-player lives (Runner=1, Hunter=manhunt_hunter_lives)
		-- on the existing pl.lives field -- no pool needed there.
		team_lives = {},
		-- Teams: team_card_target[id] = one random opposing-team member id, re-picked
		-- once per ante (same cadence as nemesis_of), used for joker/consumable
		-- triggering (Asteroid/Taxes/Penny Pincher) -- separate from the team score
		-- SUM shown on the HUD (pvp_team_score_board), which isn't routed through a
		-- single target id at all.
		team_card_target = {},
		team_card_ante_computed_for = 0,
	}

local function is_host()
	local lobby = MPAPI.get_current_lobby()
	return lobby and lobby.is_host
end

-- Forward-declared: PVP.referee_on_ready_blind (below) needs to call
-- broadcast_live_targets before its definition further down this file, since a
-- fresh round's board should show reset (0) values immediately rather than
-- stale ones from the round that just ended.
local broadcast_royale_targets, broadcast_live_targets

local function broadcast(key, params)
	local lobby = MPAPI.get_current_lobby()
	if lobby and MPAPI.ActionTypes[key] then
		lobby:action(MPAPI.ActionTypes[key]):broadcast(params or {})
	end
end

local function ref_player(id)
	PVP.REF.players[id] = PVP.REF.players[id]
		or {
			id = id,
			score = PVP.INSANE_INT.empty(),
			highest_score = PVP.INSANE_INT.empty(),
			hands_left = 4,
			lives = PVP.LOBBY.config.starting_lives or 4,
			skips = 0,
			ante = 1,
			furthest_blind = 0,
			played_this_blind = false,
			is_ready = false,
			first_ready = false,
			lives_blocker = false,
			-- Manhunt ("HUNTER"/"RUNNER") or Teams ("A"/"B"); nil for every other mode.
			-- Stamped from PVP.LOBBY.roster in PVP.referee_reset.
			team_id = nil,
		}
	return PVP.REF.players[id]
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
-- of the 2-player "opponent hit 0 lives" check). Returns true if it fired.
local function check_alive_win()
	local alive = alive_ids()
	if #alive <= 1 then
		broadcast("pvp_win", { winner_id = alive[1] or "*draw*" })
		return true
	end
	return false
end

-- Manhunt/Teams analog of check_alive_win(): the generic "last player standing"
-- rule doesn't apply to either -- Manhunt's Runner has exactly 1 life and dying
-- ends the match for the WHOLE Hunter team regardless of remaining Hunter
-- headcount (not "last person standing"), and Teams' shared pool hitting 0 ends
-- the match regardless of individual teammates' states. Returns true if a win
-- fired. A no-op (and returns false) when neither mode is active.
local function check_team_win()
	if PVP.LOBBY.config.manhunt then
		local any_hunter_alive = false
		for _, id in ipairs(both_players()) do
			local pl = ref_player(id)
			if pl.team_id == "RUNNER" and pl.lives <= 0 then
				broadcast("pvp_win", { winner_id = "", winner_team_id = "HUNTER" })
				return true
			end
			if pl.team_id == "HUNTER" and pl.lives > 0 then
				any_hunter_alive = true
			end
		end
		if not any_hunter_alive then
			broadcast("pvp_win", { winner_id = "", winner_team_id = "RUNNER" })
			return true
		end
		return false
	end
	if PVP.LOBBY.config.team_based then
		if (PVP.REF.team_lives.A or 1) <= 0 then
			broadcast("pvp_win", { winner_id = "", winner_team_id = "B" })
			return true
		end
		if (PVP.REF.team_lives.B or 1) <= 0 then
			broadcast("pvp_win", { winner_id = "", winner_team_id = "A" })
			return true
		end
		return false
	end
	return false
end

-- Dispatches to whichever win-check applies to the active mode.
local function check_any_win()
	if PVP.LOBBY.config.manhunt or PVP.LOBBY.config.team_based then
		return check_team_win()
	end
	return check_alive_win()
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

-- Recomputes PVP.REF.nemesis_of for the current ante from the given alive roster:
-- a no-repeat (until every possible pair has been used, at which point the cycle
-- restarts) round-robin pairing, with a bye for odd counts that prefers not
-- repeating whoever byed last time.
local function compute_nemesis_pairing(alive)
	PVP.REF.nemesis_of = {}
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
			if id ~= PVP.REF.last_bye_id then
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
				if PVP.REF.used_pairs[pair_key(p[1], p[2])] then
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
			PVP.REF.used_pairs = {}
			chosen = circle_round(ids, 0)
		end
		for _, p in ipairs(chosen) do
			PVP.REF.nemesis_of[p[1]] = p[2]
			PVP.REF.nemesis_of[p[2]] = p[1]
			PVP.REF.used_pairs[pair_key(p[1], p[2])] = true
		end
	end
	PVP.REF.last_bye_id = bye_id
end

-- Broadcasts the current ante's pairing to everyone (flat id -> partner-id-or-"" map
-- for every currently-alive id) so each client can resolve PVP.current_target_id().
local function broadcast_nemesis_pairing()
	local payload = {}
	for _, id in ipairs(alive_ids()) do
		payload[id] = PVP.REF.nemesis_of[id] or ""
	end
	broadcast("pvp_nemesis_pairing", { pairing = payload })
end

-- Recomputes PVP.REF.team_card_target for the current ante: each alive player is
-- assigned one random currently-alive OPPOSING-team member, for joker/consumable
-- triggering (Asteroid/Taxes/Penny Pincher). Re-picked once per ante, same cadence
-- as compute_nemesis_pairing -- kept separate from the team score SUM shown on the
-- HUD (pvp_team_score_board), which isn't routed through a target id at all.
local function compute_team_card_targets(alive)
	PVP.REF.team_card_target = {}
	local by_team = { A = {}, B = {} }
	for _, id in ipairs(alive) do
		local team_id = ref_player(id).team_id
		if by_team[team_id] then
			table.insert(by_team[team_id], id)
		end
	end
	for _, id in ipairs(alive) do
		local my_team = ref_player(id).team_id
		local enemy_team = (my_team == "A") and "B" or "A"
		local candidates = by_team[enemy_team]
		if candidates and #candidates > 0 then
			PVP.REF.team_card_target[id] = candidates[math.random(#candidates)]
		end
	end
end

-- Broadcasts the current ante's team card-targeting assignments to everyone (flat
-- id -> target-id-or-"" map) so each client can resolve PVP.current_target_id().
local function broadcast_team_card_target()
	local payload = {}
	for _, id in ipairs(alive_ids()) do
		payload[id] = PVP.REF.team_card_target[id] or ""
	end
	broadcast("pvp_team_card_target", { pairing = payload })
end

-- Best PvP score for a player (host referee state), as a plausibility-bounded number
-- for the matchmaking `metric` (season-best score column). Host-only.
function PVP.pvp_score_metric(player_id)
	local pl = PVP.REF and PVP.REF.players and PVP.REF.players[player_id]
	if not pl or not pl.score then
		return 0
	end
	return tonumber(PVP.INSANE_INT.to_string(pl.highest_score or pl.score)) or 0
end

-- Reset all referee state at game start and stamp starting lives (option override
-- else the gamemode default). Mirrors Lobby.setPlayersLives + resetPlayers.
function PVP.referee_reset(starting_lives)
	if not is_host() then
		return
	end
	PVP.REF.players = {}
	PVP.REF.first_ready_at = nil
	if PVP.REF.ready_tracker then
		PVP.REF.ready_tracker:reset()
	end
	PVP.REF.nemesis_of = {}
	PVP.REF.used_pairs = {}
	PVP.REF.nemesis_ante_computed_for = 0
	PVP.REF.last_bye_id = nil
	PVP.REF.team_lives = {}
	PVP.REF.team_card_target = {}
	PVP.REF.team_card_ante_computed_for = 0
	PVP._result_reported = false
	local lives = starting_lives or PVP.LOBBY.config.starting_lives or 4
	local total = both_players()
	for _, id in ipairs(total) do
		local pl = ref_player(id)
		pl.lives = lives
		pl.score = PVP.INSANE_INT.empty()
		pl.hands_left = 4
		pl.played_this_blind = false
		pl.is_ready = false
		pl.first_ready = false
		pl.lives_blocker = false
		pl.team_id = PVP.LOBBY.roster and PVP.LOBBY.roster[id] or nil
	end

	if PVP.LOBBY.config.manhunt then
		-- Exactly one Runner: the first player who actually claimed the slot (roster
		-- order isn't meaningful, so pick deterministically off both_players()'s
		-- order), else the first player by default so the mode never ends up with
		-- zero Runners (e.g. a fabricated test roster, or nobody having opened the
		-- picker). Any extra Runner claims (a UI race) are demoted to Hunter.
		local runner_id = nil
		for _, id in ipairs(total) do
			if ref_player(id).team_id == "RUNNER" and not runner_id then
				runner_id = id
			end
		end
		runner_id = runner_id or total[1]
		for _, id in ipairs(total) do
			local pl = ref_player(id)
			pl.team_id = (id == runner_id) and "RUNNER" or "HUNTER"
			pl.lives = (pl.team_id == "RUNNER") and 1 or (PVP.LOBBY.config.manhunt_hunter_lives or 7)
			broadcast("pvp_player_lives", { player_id = id, lives = pl.lives })
		end
	elseif PVP.LOBBY.config.team_based then
		for _, id in ipairs(total) do
			local pl = ref_player(id)
			pl.team_id = pl.team_id or "A"
		end
		PVP.REF.team_lives = { A = lives, B = lives }
		broadcast("pvp_player_lives", { player_id = "*all*", lives = lives })
		broadcast("pvp_team_lives", { team_id = "A", lives = lives })
		broadcast("pvp_team_lives", { team_id = "B", lives = lives })
	else
		-- Authoritative starting lives to both clients.
		broadcast("pvp_player_lives", { player_id = "*all*", lives = lives })
	end

	if PVP.LOBBY.config.manhunt or PVP.LOBBY.config.team_based then
		-- Authoritative final roster snapshot: a player who never opened the picker
		-- (accepting the server-computed default above) never broadcast their own
		-- pvp_set_team, so PVP.LOBBY.roster/team_id on EVERY client (including
		-- their own) would otherwise never reflect it -- breaking blind reskin
		-- (get_nemesis_key), Teams' cross-team targeting latch, and the pvp_win
		-- winner_team_id resolution in outcomes.lua. Broadcasting the real
		-- assignments once here (not the best-effort pvp_set_team mirror) is what
		-- makes them authoritative.
		local final_roster = {}
		for _, id in ipairs(total) do
			final_roster[id] = ref_player(id).team_id
		end
		broadcast("pvp_team_roster", { roster = final_roster })
	end

	if PVP.LOBBY.config.nemesis_pairing then
		compute_nemesis_pairing(alive_ids())
		PVP.REF.nemesis_ante_computed_for = 1
		broadcast_nemesis_pairing()
	elseif PVP.LOBBY.config.team_based then
		compute_team_card_targets(alive_ids())
		PVP.REF.team_card_ante_computed_for = 1
		broadcast_team_card_target()
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

-- Teams-aware life loss for the fail_round/fail_timer/fail_pvp_timer paths below
-- (non-PvP-round failures: a vanilla boss blind loss, an ante timer expiry, a PvP
-- round timer expiry). Manhunt keeps ordinary per-player lives (lose_life
-- unchanged); Teams must decrement its SHARED pool once and mirror the new value
-- onto every teammate, or these paths would desync an individual's pl.lives from
-- their team's actual pool (the pool is the only thing check_team_win reads).
local function team_lose_life(pl)
	if not PVP.LOBBY.config.team_based then
		lose_life(pl)
		return
	end
	if pl.lives_blocker then
		return
	end
	pl.lives_blocker = true
	local team = pl.team_id
	PVP.REF.team_lives[team] = (PVP.REF.team_lives[team] or 1) - 1
	broadcast("pvp_team_lives", { team_id = team, lives = PVP.REF.team_lives[team] })
	for _, id in ipairs(both_players()) do
		local other = ref_player(id)
		if other.team_id == team then
			other.lives = PVP.REF.team_lives[team]
			broadcast("pvp_player_lives", { player_id = id, lives = other.lives })
		end
	end
end

-- readyBlind: both ready -> compute firstPlayer, reset per-blind state, start blind.
-- The 2-player path (below) is untouched. For N>2 (Royale) there's no meaningful
-- "first player" HUD ordering, so that concept is dropped and readiness is just
-- "every alive player has readied", via MPAPI.ReadyTracker()'s set/is_ready/reset
-- primitives (checked against alive_ids() ourselves rather than its own all_ready(),
-- which loops the full lobby roster and would stall on eliminated spectators).
function PVP.referee_on_ready_blind(from)
	if not is_host() then
		return
	end

	if #both_players() > 2 then
		PVP.REF.ready_tracker = PVP.REF.ready_tracker or MPAPI.ReadyTracker()
		PVP.REF.ready_tracker:set(from, true)
		local alive = alive_ids()
		local all_ready = true
		for _, id in ipairs(alive) do
			if not PVP.REF.ready_tracker:is_ready(id) then
				all_ready = false
				break
			end
		end
		if all_ready then
			PVP.REF.ready_tracker:reset()
			for _, id in ipairs(alive) do
				local pl = ref_player(id)
				pl.score = PVP.INSANE_INT.empty()
				pl.hands_left = 4
				pl.played_this_blind = false
			end
			broadcast("pvp_start_blind", { first_player = "" })
			-- Show fresh (0) values on the live target board immediately, not stale
			-- ones from the round that just ended.
			broadcast_live_targets()
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
		me.score = PVP.INSANE_INT.empty()
		enemy.score = PVP.INSANE_INT.empty()
		me.hands_left = 4
		enemy.hands_left = 4
		me.played_this_blind = false
		enemy.played_this_blind = false

		-- firstPlayer is the id of whichever player readied first.
		local first_id = me.first_ready and from or (enemy.first_ready and opp or nil)
		broadcast("pvp_start_blind", { first_player = first_id or "" })
	end
end

function PVP.referee_on_unready_blind(from)
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
function PVP.referee_resolve_2p_round(a, b)
	local a_lt_b = PVP.INSANE_INT.greater_than(b.score, a.score) -- a.score < b.score
	local b_lt_a = PVP.INSANE_INT.greater_than(a.score, b.score)
	local equal = PVP.INSANE_INT.equal(a.score, b.score)

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

-- Pure: given the Runner's ref_player table and an array of alive Hunters' ref_player
-- tables, decides which Hunters lose a life and whether the Runner is caught this
-- round. Ported from BalatroMultiplayerManhuntServer's BRModeManhunt.checkPVPDone --
-- NOT a rotating pairwise system like Nemesis: the Runner is compared once against
-- the single BEST Hunter score (they only have one life, so only the worst case
-- matters), while each Hunter is compared individually against the Runner (so
-- several Hunters can lose a life in the same round). A Hunter must STRICTLY beat
-- the Runner to survive; ties favor the Runner (they "evade" unless decisively
-- caught) UNLESS the Runner scored exactly 0, in which case a tied (0-0) Hunter is
-- not penalized.
function PVP.referee_resolve_manhunt_round(runner, hunters)
	local highest_hunter_score = PVP.INSANE_INT.empty()
	-- Defaults to the first hunter (not nil) so an all-0-0 tie still shows someone
	-- on the Runner's live target board rather than "no target yet".
	local highest_hunter_id = hunters[1] and hunters[1].id or nil
	for _, h in ipairs(hunters) do
		if PVP.INSANE_INT.greater_than(h.score, highest_hunter_score) then
			highest_hunter_score = h.score
			highest_hunter_id = h.id
		end
	end

	local hunter_losers = {}
	for _, h in ipairs(hunters) do
		local hunter_behind = PVP.INSANE_INT.greater_than(runner.score, h.score)
		local tied = PVP.INSANE_INT.equal(h.score, runner.score)
		local runner_scored = not PVP.INSANE_INT.equal(runner.score, PVP.INSANE_INT.empty())
		if hunter_behind or (tied and runner_scored) then
			hunter_losers[#hunter_losers + 1] = h
		end
	end

	return {
		hunter_losers = hunter_losers,
		runner_caught = PVP.INSANE_INT.greater_than(highest_hunter_score, runner.score),
		-- The Runner's live HUD target -- whichever Hunter currently holds the
		-- highest score (first-in-iteration-order tiebreak on exact ties). nil only
		-- if `hunters` is empty (shouldn't happen with a live match, but a fabricated
		-- test roster could hit it).
		highest_hunter_id = highest_hunter_id,
	}
end

-- Pure: sums a team's scores this round. Shared by the win/loss decision
-- (PVP.referee_resolve_teams_round below) and the live pvp_team_score_board
-- broadcast (broadcast_live_targets), so the summing rule can't drift between them.
local function sum_team_scores(team_players)
	local sum = PVP.INSANE_INT.empty()
	for _, pl in ipairs(team_players) do
		sum = PVP.INSANE_INT.add(sum, pl.score)
	end
	return sum
end

-- Pure: sums each team's scores this round and returns the losing team ("A"/"B"),
-- or equal=true on an exact tie (mirrors the 1v1/Royale "nobody loses on a tie" rule).
function PVP.referee_resolve_teams_round(team_a, team_b)
	local sum_a, sum_b = sum_team_scores(team_a), sum_team_scores(team_b)
	if PVP.INSANE_INT.equal(sum_a, sum_b) then
		return { equal = true }
	end
	return { equal = false, loser_team = PVP.INSANE_INT.greater_than(sum_b, sum_a) and "A" or "B" }
end

-- Pure: ranks alive players by score ascending and returns the same "bottom
-- floor(N/2) (min 1), ties folded down into the loser set" split
-- try_resolve_round's Royale branch has always used -- plus an is_loser lookup so
-- callers (round resolution AND the live pvp_royale_target broadcast) can
-- classify any alive id as currently safe/unsafe without duplicating the
-- cutoff/tie logic. Ties folding an EXTRA player past cutoff_idx into losers is
-- why callers must use is_loser, not just index vs. cutoff_idx, to know who's safe.
function PVP.referee_rank_royale(players)
	local ranked = {}
	for _, pl in ipairs(players) do
		ranked[#ranked + 1] = pl
	end
	table.sort(ranked, function(x, y)
		return PVP.INSANE_INT.greater_than(y.score, x.score)
	end)

	local cutoff_idx = math.max(1, math.floor(#ranked / 2))
	local cutoff_score = ranked[cutoff_idx].score
	local losers, is_loser = {}, {}
	for _, pl in ipairs(ranked) do
		if not PVP.INSANE_INT.greater_than(pl.score, cutoff_score) then
			losers[#losers + 1] = pl
			is_loser[pl.id] = true
		end
	end

	return { ranked = ranked, cutoff_idx = cutoff_idx, losers = losers, is_loser = is_loser }
end

-- Effects wrapper for the Manhunt branch of try_resolve_round: splits the alive
-- roster into the Runner + Hunters, applies PVP.referee_resolve_manhunt_round's
-- outcome, and declares the match over via check_team_win() once appropriate.
local function resolve_manhunt_round(alive)
	local runner, hunters = nil, {}
	for _, id in ipairs(alive) do
		local pl = ref_player(id)
		pl.first_ready = false
		if pl.team_id == "RUNNER" then
			runner = pl
		else
			hunters[#hunters + 1] = pl
		end
	end
	if not runner then
		-- Runner already eliminated/disconnected this round -- forfeit handling
		-- (PVP.referee_manhunt_on_forfeit) already resolved the match.
		return
	end

	local outcome = PVP.referee_resolve_manhunt_round(runner, hunters)
	for _, h in ipairs(outcome.hunter_losers) do
		lose_life(h)
	end
	if outcome.runner_caught then
		lose_life(runner)
	end

	if not check_team_win() then
		broadcast("pvp_end_pvp", { loser_id = "", pvp_timer_lost = false })
	end
end

-- Effects wrapper for the Teams branch of try_resolve_round: sums each team's
-- scores, decrements the losing team's SHARED pool once (not once per member), and
-- keeps every teammate's individual pl.lives mirrored to that pool so the existing
-- per-player lives-reading code (HUD, jokers) keeps working unmodified.
local function resolve_teams_round(alive)
	local by_team = { A = {}, B = {} }
	for _, id in ipairs(alive) do
		local pl = ref_player(id)
		pl.first_ready = false
		if by_team[pl.team_id] then
			table.insert(by_team[pl.team_id], pl)
		end
	end
	local outcome = PVP.referee_resolve_teams_round(by_team.A, by_team.B)
	if not outcome.equal then
		local loser = outcome.loser_team
		PVP.REF.team_lives[loser] = (PVP.REF.team_lives[loser] or 1) - 1
		broadcast("pvp_team_lives", { team_id = loser, lives = PVP.REF.team_lives[loser] })
		for _, id in ipairs(both_players()) do
			local pl = ref_player(id)
			if pl.team_id == loser then
				pl.lives = PVP.REF.team_lives[loser]
				broadcast("pvp_player_lives", { player_id = id, lives = pl.lives })
			end
		end
	end
	if not check_team_win() then
		broadcast("pvp_end_pvp", { loser_id = "", pvp_timer_lost = false })
	end
end

-- Broadcasts each alive Royale player's personalized live target: a SAFE player
-- (not currently losing a life) is shown the adjacent ranked player with the
-- next-LOWER score (their safety margin); an UNSAFE player is shown the adjacent
-- ranked player with the next-HIGHER score (what they need to beat). Carries ids
-- only -- once a client's PVP.current_target_id() resolves to the right id, the
-- existing raw per-sender score/hands/lives relay (objects/blinds/nemesis.lua)
-- displays the value, no separate score payload needed here.
function broadcast_royale_targets(rank)
	local payload = {}
	for i, pl in ipairs(rank.ranked) do
		local neighbor
		if rank.is_loser[pl.id] then
			neighbor = rank.ranked[i + 1] -- may be nil: the whole alive set tied (nobody loses)
		else
			neighbor = rank.ranked[i - 1] -- may be nil: i == 1, the lowest-ranked "safe" player (full-tie edge case)
		end
		payload[pl.id] = neighbor and neighbor.id or ""
	end
	broadcast("pvp_royale_target", { targets = payload })
end

-- Live (mid-round, not just round-end) target broadcast for N>2 modes, called on
-- every score update so the HUD tracks continuously. A no-op for 2-player lobbies
-- (mirrors try_resolve_round's own size-based branch), Nemesis-pairing (target is
-- the per-ante partner, unrelated to live score), and Manhunt Hunters (their
-- target -- the Runner -- never changes mid-match, resolved locally instead).
function broadcast_live_targets()
	if #both_players() <= 2 or PVP.LOBBY.config.nemesis_pairing then
		return
	end
	local alive = alive_ids()
	if #alive < 2 then
		return
	end

	if PVP.LOBBY.config.manhunt then
		local runner, hunters = nil, {}
		for _, id in ipairs(alive) do
			local pl = ref_player(id)
			if pl.team_id == "RUNNER" then
				runner = pl
			else
				hunters[#hunters + 1] = pl
			end
		end
		if runner and #hunters > 0 then
			local outcome = PVP.referee_resolve_manhunt_round(runner, hunters)
			broadcast("pvp_manhunt_target", { target_id = outcome.highest_hunter_id })
		end
	elseif PVP.LOBBY.config.team_based then
		local by_team = { A = {}, B = {} }
		for _, id in ipairs(alive) do
			local pl = ref_player(id)
			if by_team[pl.team_id] then
				table.insert(by_team[pl.team_id], pl)
			end
		end
		broadcast("pvp_team_score_board", {
			team_scores = {
				A = PVP.INSANE_INT.to_string(sum_team_scores(by_team.A)),
				B = PVP.INSANE_INT.to_string(sum_team_scores(by_team.B)),
			},
		})
	else
		local alive_players = {}
		for _, id in ipairs(alive) do
			alive_players[#alive_players + 1] = ref_player(id)
		end
		broadcast_royale_targets(PVP.referee_rank_royale(alive_players))
	end
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
	local total = both_players()
	if #total < 2 then
		return
	end

	-- Manhunt/Teams are gated BEFORE the #total==2 check below: both can have
	-- exactly 2 total players (1 Runner+1 Hunter, or a degenerate 1v1 Teams match)
	-- where the generic symmetric pairwise rule would otherwise wrongly apply.
	if PVP.LOBBY.config.manhunt or PVP.LOBBY.config.team_based then
		local alive = alive_ids()
		if #alive < 2 then
			return
		end
		for _, id in ipairs(alive) do
			if ref_player(id).hands_left >= 1 then
				return
			end
		end
		if PVP.LOBBY.config.manhunt then
			resolve_manhunt_round(alive)
		else
			resolve_teams_round(alive)
		end
		return
	end

	if #total == 2 then
		local a, b = ref_player(total[1]), ref_player(total[2])
		local outcome = PVP.referee_resolve_2p_round(a, b)
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
				broadcast("pvp_win", { winner_id = game_winner.id })
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

	if PVP.LOBBY.config.nemesis_pairing then
		-- Nemesis: resolve every still-live pair independently (a pair with one side
		-- now eliminated/disconnected is skipped -- the survivor is untouched this
		-- round, equivalent to a bye). Both sides are already guaranteed hands_left<1
		-- by the gate above, so no early-exit-while-trailing nuance is needed here
		-- (unlike the 2-player branch, where responsiveness matters more).
		local seen = {}
		for _, ida in ipairs(alive) do
			ref_player(ida).first_ready = false
			local idb = PVP.REF.nemesis_of[ida]
			if idb and not seen[ida] and not seen[idb] and ref_player(idb).lives > 0 then
				local a, b = ref_player(ida), ref_player(idb)
				if not PVP.INSANE_INT.equal(a.score, b.score) then
					local loser = PVP.INSANE_INT.greater_than(b.score, a.score) and a or b
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
		-- this round. See PVP.referee_rank_royale for the extracted, independently
		-- testable ranking/cutoff logic (also reused by the live target broadcast).
		local alive_players = {}
		for _, id in ipairs(alive) do
			alive_players[#alive_players + 1] = ref_player(id)
		end
		local rank = PVP.referee_rank_royale(alive_players)
		for _, pl in ipairs(rank.ranked) do
			pl.first_ready = false
		end

		if #rank.losers < #rank.ranked then
			for _, pl in ipairs(rank.losers) do
				lose_life(pl)
			end
		end
	end

	if not check_alive_win() then
		broadcast("pvp_end_pvp", { loser_id = "", pvp_timer_lost = false })
	end
end

-- playHand: store sender score/hands, then attempt resolution.
function PVP.referee_on_play_hand(from, params)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	pl.score = PVP.INSANE_INT.from_string(tostring(params.score or "0"))
	pl.hands_left = math.floor(tonumber(params.handsLeft) or pl.hands_left)
	if params.skips then
		pl.skips = tonumber(params.skips) or pl.skips
	end
	if params.lives then
		pl.lives = tonumber(params.lives) or pl.lives
	end
	if PVP.INSANE_INT.greater_than(pl.score, PVP.INSANE_INT.empty()) then
		pl.played_this_blind = true
	end
	if PVP.INSANE_INT.greater_than(pl.score, pl.highest_score) then
		pl.highest_score = pl.score
	end
	broadcast_live_targets()
	try_resolve_round()
end

function PVP.referee_on_skip(from, params)
	if not is_host() then
		return
	end
	ref_player(from).skips = tonumber(params.skips) or 0
end

function PVP.referee_on_set_ante(from, params)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	pl.ante = tonumber(params.ante) or pl.ante

	-- Manhunt: the Runner "escapes" by clearing ante 8 (reaching ante 9) without
	-- ever being caught -- an immediate win, mirroring the ante>8 natural-stop
	-- precedent already used by PvP practice mode.
	if PVP.LOBBY.config.manhunt and pl.team_id == "RUNNER" then
		local ante = tonumber(params.ante)
		if ante and ante > 8 then
			broadcast("pvp_win", { winner_id = "", winner_team_id = "RUNNER" })
			return
		end
	end

	-- Nemesis-pairing: recompute once per ante, triggered by whichever alive
	-- player's ease_ante() reports it first. Safe against overlapping with an
	-- in-flight resolution for the OLD ante, because a client can only call
	-- ease_ante() (and thus report a new ante at all) after receiving that ante's
	-- pvp_end_pvp/pvp_win -- which itself can't be sent until try_resolve_round's
	-- batch-resolve for the old ante has already completed.
	if PVP.LOBBY.config.nemesis_pairing then
		local ante = tonumber(params.ante)
		if ante and ante > PVP.REF.nemesis_ante_computed_for then
			PVP.REF.nemesis_ante_computed_for = ante
			compute_nemesis_pairing(alive_ids())
			broadcast_nemesis_pairing()
		end
	elseif PVP.LOBBY.config.team_based then
		-- Teams' card-targeting rotation: same once-per-ante cadence as Nemesis
		-- pairing above (see that branch's comment for why this is race-safe).
		local ante = tonumber(params.ante)
		if ante and ante > PVP.REF.team_card_ante_computed_for then
			PVP.REF.team_card_ante_computed_for = ante
			compute_team_card_targets(alive_ids())
			broadcast_team_card_target()
		end
	end
end

-- Manhunt: the Runner redeemed an ante-skip voucher (manhunt_vouchers.lua) --
-- every Hunter gains +1 life as compensation. A no-op if `from` isn't the Runner
-- (defensive; the vouchers themselves only ever call this for the Runner).
function PVP.referee_on_redeem_ante_voucher(from)
	if not is_host() then
		return
	end
	if ref_player(from).team_id ~= "RUNNER" then
		return
	end
	for _, id in ipairs(both_players()) do
		local pl = ref_player(id)
		if pl.team_id == "HUNTER" then
			pl.lives = pl.lives + 1
			broadcast("pvp_player_lives", { player_id = id, lives = pl.lives })
		end
	end
end

function PVP.referee_on_set_furthest_blind(from, params)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	pl.furthest_blind = tonumber(params.furthestBlind) or pl.furthest_blind
end

-- newRound: re-arm loseLife for the next round (resetBlocker).
function PVP.referee_on_new_round(from)
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
function PVP.referee_on_fail_round(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	if PVP.LOBBY.config.death_on_round_loss then
		team_lose_life(pl)
	end
	if pl.lives == 0 then
		if check_any_win() then
			return
		end
	end
	if PVP.LOBBY.config.manhunt or PVP.LOBBY.config.team_based or #both_players() > 2 then
		pl.hands_left = 0
		broadcast_live_targets()
		try_resolve_round()
	end
end

-- failTimer (non-PvP ante timer): sender loses a life; match ends only when exactly
-- one player remains alive. Same N>2 progress-nudge as referee_on_fail_round.
function PVP.referee_on_fail_timer(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	team_lose_life(pl)
	if pl.lives == 0 and check_any_win() then
		return
	end
	if PVP.LOBBY.config.manhunt or PVP.LOBBY.config.team_based or #both_players() > 2 then
		pl.hands_left = 0
		broadcast_live_targets()
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
-- §17.12: previously this ended the whole PvP round outright (life loss +
-- broadcast pvp_end_pvp / force hands_left=0) the instant the PvP timer
-- expired. Per the design doc, running out of time on a single hand should
-- cost exactly that -- one hand, credited with the same time bonus a normal
-- hand-play would have earned -- not the life and the round. hands_left is
-- decremented here directly (the host's own authoritative mirror, kept in
-- sync from the client's own pvp_play_hand reports the same way
-- referee_on_play_hand already updates it) rather than round-tripping
-- through a client acknowledgment; the targeted pvp_timer_hand_lost
-- broadcast below only carries the LOCAL consequence (crediting the timer
-- bonus) back to the specific player who timed out, since score itself is
-- untouched by a timeout and doesn't need re-reporting.
function PVP.referee_on_fail_pvp_timer(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	pl.hands_left = math.max(0, (pl.hands_left or 0) - 1)
	broadcast("pvp_timer_hand_lost", { player_id = from })
	broadcast_live_targets()
	try_resolve_round()
end

-- Manhunt's on_player_forfeit: the Runner leaving ends the match immediately in
-- the Hunters' favor (there is nothing left to "escape" against). A Hunter
-- leaving doesn't end the match by itself -- try_resolve_round's own
-- hunters-all-eliminated check (via check_team_win) handles "last Hunter left"
-- naturally once the remaining Hunters' next round resolves. Returns the winning
-- team_id if this call ended the match, else nil.
function PVP.referee_manhunt_on_forfeit(player_id)
	if not is_host() then
		return nil
	end
	local pl = ref_player(player_id)
	if pl.team_id == "RUNNER" then
		broadcast("pvp_win", { winner_id = "", winner_team_id = "HUNTER" })
		return "HUNTER"
	end
	return nil
end

-- Teams' on_player_forfeit: if the leaver's whole team roster is now gone, the
-- other team wins immediately. Returns the winning team_id if this call ended
-- the match, else nil.
function PVP.referee_teams_on_forfeit(player_id)
	if not is_host() then
		return nil
	end
	local pl = ref_player(player_id)
	local team = pl.team_id
	if not team then
		return nil
	end
	for _, id in ipairs(both_players()) do
		if id ~= player_id and ref_player(id).team_id == team then
			return nil -- a teammate remains
		end
	end
	local winner = (team == "A") and "B" or "A"
	broadcast("pvp_win", { winner_id = "", winner_team_id = winner })
	return winner
end
