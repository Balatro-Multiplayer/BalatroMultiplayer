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

MP.REF = MP.REF or { players = {}, first_ready_at = nil }

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
function MP.referee_on_ready_blind(from)
	if not is_host() then
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

-- The score-comparison round resolution (playHand path). Called after a player's
-- score/hands are updated. Ends the round when the trailing player is out of hands
-- or both are, decided by InsaneInt score with exact-equality = draw.
local function try_resolve_round()
	local ids = both_players()
	if #ids < 2 then
		return
	end
	local a, b = ref_player(ids[1]), ref_player(ids[2])
	local a_lt_b = MP.INSANE_INT.greater_than(b.score, a.score) -- a.score < b.score
	local b_lt_a = MP.INSANE_INT.greater_than(a.score, b.score)
	local equal = MP.INSANE_INT.equal(a.score, b.score)

	local trigger = (a.hands_left < 1 and a_lt_b)
		or (b.hands_left < 1 and b_lt_a)
		or (a.hands_left < 1 and b.hands_left < 1)
	if not trigger then
		return
	end

	-- roundWinner = the higher score; on a tie the second player is nominal winner
	-- but no life is lost and both get lost=false.
	local winner = a_lt_b and b or a
	local loser = (winner.id == a.id) and b or a

	if not equal then
		lose_life(loser)
		if a.lives <= 0 or b.lives <= 0 then
			local game_winner = (a.lives > b.lives) and a or b
			local game_loser = (game_winner.id == a.id) and b or a
			winner.first_ready = false
			loser.first_ready = false
			broadcast("pvp_win", { winner_id = game_winner.id })
			return
		end
	end

	winner.first_ready = false
	loser.first_ready = false
	broadcast("pvp_end_pvp", { loser_id = (not equal) and loser.id or "", pvp_timer_lost = false })
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
end

-- setFurthestBlind: survival-mode win check (opponent already at 0 lives and behind).
function MP.referee_on_set_furthest_blind(from, params)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	pl.furthest_blind = tonumber(params.furthestBlind) or pl.furthest_blind
	if MP.LOBBY.config.gamemode == "gamemode_mp_survival" then
		local opp = opponent_of(from)
		local enemy = opp and ref_player(opp)
		if enemy and enemy.lives == 0 and pl.furthest_blind > enemy.furthest_blind then
			broadcast("pvp_win", { winner_id = from })
		end
	end
end

-- newRound: re-arm loseLife for the next round (resetBlocker).
function MP.referee_on_new_round(from)
	if not is_host() then
		return
	end
	ref_player(from).lives_blocker = false
end

-- failRound: mode-dependent life loss (death_on_round_loss) and match end.
function MP.referee_on_fail_round(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	if MP.LOBBY.config.death_on_round_loss then
		lose_life(pl)
	end
	if pl.lives == 0 then
		local opp = opponent_of(from)
		if MP.LOBBY.config.gamemode == "gamemode_mp_survival" then
			local enemy = opp and ref_player(opp)
			if enemy and pl.furthest_blind == enemy.furthest_blind then
				broadcast("pvp_win", { winner_id = "*draw*" })
			else
				local winner = (enemy and pl.furthest_blind < enemy.furthest_blind) and opp or from
				broadcast("pvp_win", { winner_id = winner })
			end
		else
			broadcast("pvp_win", { winner_id = opp })
		end
	end
end

-- failTimer (non-PvP ante timer): sender loses a life; match ends only at 0.
function MP.referee_on_fail_timer(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	lose_life(pl)
	if pl.lives == 0 then
		broadcast("pvp_win", { winner_id = opponent_of(from) })
	end
end

-- failPvPTimer: sender loses the PvP round on the timer (always a life; round or match).
function MP.referee_on_fail_pvp_timer(from)
	if not is_host() then
		return
	end
	local pl = ref_player(from)
	lose_life(pl)
	if pl.lives == 0 then
		broadcast("pvp_win", { winner_id = opponent_of(from) })
	else
		pl.first_ready = false
		local opp = opponent_of(from)
		if opp then
			ref_player(opp).first_ready = false
		end
		broadcast("pvp_end_pvp", { loser_id = from, pvp_timer_lost = true })
	end
end
