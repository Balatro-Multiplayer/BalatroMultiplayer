-- MPAPI.ActionType definitions for the PvP peer protocol.
--
-- Each action is broadcast over the lobby (broadcast loops back to the sender, so
-- handlers guard on `from == self`). Two kinds:
--   * mirror/relay  - a client tells peers about its own state; the opponent applies
--                     it through the existing client handler (MP.dispatch_action).
--   * authoritative - the HOST computes an outcome in referee.lua and broadcasts it;
--                     every client (host included, via loopback) applies it.
--
-- Loaded inside MPAPI.on_loaded (see core.lua) so each ActionType is tagged to this
-- mod; per-lobby routing filters actions by owning mod id.

local function self_id()
	local lobby = MPAPI.get_current_lobby()
	return lobby and lobby.player_id
end

local function A(key, on_receive)
	-- prefix_config.key = false: keep the literal `pvp_*` key. Otherwise SMODS
	-- prepends this mod's prefix ("mp") -> "mp_pvp_*", and every lookup by "pvp_*"
	-- (here, the referee, net.lua, and the peer wire action name) misses.
	MPAPI.ActionType({ key = key, on_receive = on_receive, prefix_config = { key = false } })
end

-- Relay: opponent applies `wire` handler; sender ignores its own loopback.
local function relay(key, wire)
	A(key, function(_at, from, params)
		if from == self_id() then
			return
		end
		MP.dispatch_action(wire, params or {})
	end)
end

-- ── run lifecycle ────────────────────────────────────────────────────────────
A("pvp_start_game", function(_at, from, params)
	if MP.stop_ready_resync then
		MP.stop_ready_resync()
	end
	if MP.reset_ready_state then
		MP.reset_ready_state()
	end

	local lobby = MPAPI.get_current_lobby()
	local meta = (lobby and lobby:get_metadata()) or {}
	local gm_def = meta.gamemode and MPAPI.GameModes[meta.gamemode]

	-- Ban-pick survivors are center KEYS (e.g. 'b_red'); MP's run start wants a deck
	-- NAME. Resolve either form to a name, and pin it as the lobby deck so MP's
	-- copy_host_deck (config.back -> deck.back) doesn't clobber the drafted deck.
	local function apply_deck(ref)
		if not ref then
			return
		end
		local center = G.P_CENTERS[ref]
		local name = (center and center.name) or ref
		MP.LOBBY.config.back = name
		MP.LOBBY.deck.back = name
	end

	-- picked is a { key, stake } item (deck+stake draft), a plain deck key/name, or nil.
	local function proceed(picked)
		local deck_ref, stake
		if type(picked) == "table" then
			deck_ref, stake = picked.key, picked.stake
		else
			deck_ref = picked
		end
		apply_deck(deck_ref)
		if stake then
			MP.LOBBY.config.stake = stake
			MP.LOBBY.deck.stake = stake
		end
		if lobby and lobby.is_host then
			MP.referee_reset(MP.LOBBY.config.starting_lives)
		end
		MP.dispatch_action("startGame", { seed = params.seed, stake = stake or params.stake })
	end

	-- Matchmaking (2 players) with a ban_pick config: run the deck+stake draft first, in
	-- lockstep off this same broadcast; the picked deck+stake then starts the run.
	if gm_def and gm_def.ban_pick and MP.is_matchmaking and MP.is_matchmaking() then
		local bp = gm_def.ban_pick
		MPAPI.BanPick.start(lobby, {
			pool_size = bp.pool_size,
			keep = bp.keep,
			schedule = bp.schedule,
			-- 9 distinct random deck backs, each paired with a random stake. The stake
			-- cap mirrors MP's own (ui/lobby/lobby.lua:346): MP.DECK.MAX_STAKE when a
			-- compatibility mod restricts it, else all 8.
			build_pool = function()
				local cap = (MP.DECK and MP.DECK.MAX_STAKE and MP.DECK.MAX_STAKE > 0) and MP.DECK.MAX_STAKE or 8
				local keys = {}
				for _, center in ipairs(G.P_CENTER_POOLS.Back or {}) do
					keys[#keys + 1] = center.key
				end
				for i = #keys, 2, -1 do
					local j = math.random(i)
					keys[i], keys[j] = keys[j], keys[i]
				end
				local pool = {}
				for i = 1, math.min(bp.pool_size, #keys) do
					pool[i] = { key = keys[i], stake = math.random(cap) }
				end
				return pool
			end,
			-- Stamp the stake sticker onto each deck back (see the game's back_sticker DrawStep).
			decorate_tile = function(card, item)
				if type(item) == "table" and item.stake then
					card.sticker = G.sticker_map[SMODS.stake_from_index(item.stake)]
				end
			end,
			state_action = "pvp_ban_pick_state",
			ban_action = "pvp_ban_pick_ban",
			on_refresh = function()
				if MP.lobby and MP.lobby.refresh_mm_status then
					MP.lobby.refresh_mm_status()
				end
			end,
		}, function(survivors)
			proceed(survivors and survivors[1])
		end)
	else
		proceed(meta.deck)
	end
end)

relay("pvp_stop_game", "stopGame")

-- ── deck ban-pick draft (engine lives in MPAPI.BanPick) ──────────────────────
-- Host -> all: the full canonical ban-pick state, rebroadcast after every change.
MPAPI.ActionType({
	key = "pvp_ban_pick_state",
	prefix_config = { key = false },
	parameters = { { key = "state", type = "table", required = true } },
	on_receive = function(_at, _from, params)
		local lobby = MPAPI.get_current_lobby()
		if lobby then
			MPAPI.BanPick.on_state(lobby, params.state)
		end
	end,
})

-- Guest -> host: a request to ban a deck; only the host applies it (authority).
MPAPI.ActionType({
	key = "pvp_ban_pick_ban",
	prefix_config = { key = false },
	parameters = { { key = "item_key", type = "string", required = true } },
	on_receive = function(_at, from, params)
		local lobby = MPAPI.get_current_lobby()
		if not lobby or not lobby.is_host then
			return
		end
		if MPAPI.BanPick.apply_ban(lobby, from, params.item_key) then
			MPAPI.BanPick.broadcast_state(lobby)
		end
	end,
})

-- ── lobby ready handshake ────────────────────────────────────────────────────
A("pvp_player_ready", function(_at, from, params)
	sendDebugMessage("[pvp] RECV pvp_player_ready from=" .. tostring(from) .. " ready=" .. tostring(params and params.ready), "MULTIPLAYER")
	-- Every client tallies (own arrives via loopback); the host gates Start on it.
	MP.set_player_ready(from, params and params.ready)
end)

-- ── blind handshake (host-authoritative) ─────────────────────────────────────
A("pvp_ready_blind", function(_at, from, _params)
	MP.referee_on_ready_blind(from)
end)

A("pvp_unready_blind", function(_at, from, _params)
	MP.referee_on_unready_blind(from)
end)

A("pvp_start_blind", function(_at, _from, params)
	local lobby = MPAPI.get_current_lobby()
	if not lobby then
		return
	end
	-- action_start_blind compares firstPlayer to (is_host and "host" or "guest");
	-- translate the authoritative first-player id into this client's frame.
	local me = lobby.is_host and "host" or "guest"
	local other = lobby.is_host and "guest" or "host"
	local fp = (params.first_player == lobby.player_id) and me or other
	MP.dispatch_action("startBlind", { firstPlayer = fp })
end)

-- ── score / state resolution (referee) ───────────────────────────────────────
-- The opponent-facing DISPLAY of score/hands/skips/lives is synced separately via the
-- nemesis blind's on_sync (see objects/blinds/nemesis.lua + MP.sync_pvp_blind); these
-- handlers now only feed the host-authoritative referee.
A("pvp_play_hand", function(_at, from, params)
	MP.referee_on_play_hand(from, params or {})
end)

A("pvp_skip", function(_at, from, params)
	MP.referee_on_skip(from, params or {})
end)

relay("pvp_location", "enemyLocation")

A("pvp_set_ante", function(_at, from, params)
	MP.referee_on_set_ante(from, params or {})
end)

A("pvp_set_furthest_blind", function(_at, from, params)
	MP.referee_on_set_furthest_blind(from, params or {})
end)

A("pvp_new_round", function(_at, from, _params)
	MP.referee_on_new_round(from)
end)

-- ── round / match resolution (host-authoritative inputs) ─────────────────────
A("pvp_fail_round", function(_at, from, _params)
	MP.referee_on_fail_round(from)
end)

A("pvp_fail_timer", function(_at, from, _params)
	MP.referee_on_fail_timer(from)
end)

A("pvp_fail_pvp_timer", function(_at, from, _params)
	MP.referee_on_fail_pvp_timer(from)
end)

-- ── authoritative outcomes (host -> all) ─────────────────────────────────────
A("pvp_end_pvp", function(_at, _from, params)
	local sid = self_id()
	local lost = params.loser_id ~= nil and params.loser_id ~= "" and params.loser_id == sid
	MP.dispatch_action("endPvP", { lost = lost, pvpTimerLost = params.pvp_timer_lost and true or false })
end)

A("pvp_player_lives", function(_at, _from, params)
	local sid = self_id()
	local lives = tonumber(params.lives)
	if params.player_id == "*all*" then
		MP.GAME.lives = lives
		if MP.GAME.enemy then
			MP.GAME.enemy.lives = lives
		end
		MP.dispatch_action("playerInfo", { lives = lives })
	elseif params.player_id == sid then
		MP.dispatch_action("playerInfo", { lives = lives })
	else
		if MP.GAME.enemy then
			MP.GAME.enemy.lives = lives
			if MP.UI and MP.UI.juice_up_pvp_hud then
				pcall(MP.UI.juice_up_pvp_hud)
			end
		end
	end
end)

A("pvp_win", function(_at, _from, params)
	local sid = self_id()
	if params.winner_id == "*draw*" then
		MP.dispatch_action("winGame")
	elseif params.winner_id == sid then
		MP.dispatch_action("winGame")
	else
		MP.dispatch_action("loseGame")
	end
	-- Host reports the matchmaking result (ELO + leaderboard) once per match.
	local lobby = MPAPI.get_current_lobby()
	if lobby and lobby.is_host and MP.report_match_result then
		MP.report_match_result(params.winner_id)
	end
end)

-- Opponent-forfeit win (broadcast from the gamemode's on_player_forfeit).
A("pvp_player_won", function(_at, _from, params)
	local sid = self_id()
	if params.player_id == sid then
		MP.dispatch_action("winGame")
	else
		MP.dispatch_action("loseGame")
	end
end)

-- ── timers ───────────────────────────────────────────────────────────────────
A("pvp_ante_timer", function(_at, from, params)
	if from == self_id() then
		return
	end
	MP.dispatch_action("startAnteTimer", { time = params.time, isPvP = params.isPvP, fromNemesis = true })
end)

A("pvp_pause_ante_timer", function(_at, from, params)
	if from == self_id() then
		return
	end
	MP.dispatch_action("pauseAnteTimer", { time = params.time, fromNemesis = true })
end)

-- ── pure relays (opponent-only side effects) ─────────────────────────────────
relay("pvp_send_phantom", "sendPhantom")
relay("pvp_remove_phantom", "removePhantom")
relay("pvp_magnet", "magnet")
relay("pvp_magnet_response", "magnetResponse")
relay("pvp_sold_joker", "soldJoker")
relay("pvp_asteroid", "asteroid")
relay("pvp_eat_pizza", "eatPizza")
relay("pvp_spent_last_shop", "spentLastShop")
relay("pvp_lets_go_gambling_nemesis", "letsGoGamblingNemesis")
relay("pvp_get_end_game_jokers", "getEndGameJokers")
relay("pvp_receive_end_game_jokers", "receiveEndGameJokers")
relay("pvp_get_nemesis_deck", "getNemesisDeck")
relay("pvp_receive_nemesis_deck", "receiveNemesisDeck")
relay("pvp_end_game_stats_requested", "endGameStatsRequested")
relay("pvp_nemesis_end_game_stats", "nemesisEndGameStats")
relay("pvp_jimbo_appear", "jimboAppear")
relay("pvp_jimbo_talk", "jimboTalk")
relay("pvp_jimbo_move", "jimboMove")
relay("pvp_jimbo_remove", "jimboRemove")
