-- Outgoing transport bridge.
--
-- The whole MP codebase emits network messages through Client.send({action=..., ...})
-- (defined in networking/action_handlers.lua). In the old model those went to the
-- TCP server, which relayed/transformed them to the opponent. Here we override
-- Client.send to translate each legacy message into the equivalent pvp_* ActionType
-- broadcast over the API lobby (see actions.lua). All the per-action LOCAL work in
-- MP.ACTIONS.* still runs unchanged; only the transport + the server's transforms
-- move here.
--
-- Loaded inside MPAPI.on_loaded, after action_handlers.lua, so this override wins.

local function lobby()
	return MPAPI.get_current_lobby()
end

local function broadcast(key, params)
	local l = lobby()
	if l and MPAPI.ActionTypes[key] then
		l:action(MPAPI.ActionTypes[key]):broadcast(params or {})
	end
end

-- Local player's live game state, for payloads the old server used to fill in.
local function my_score_str()
	return (MP.GAME.score and MP.INSANE_INT.to_string(MP.GAME.score)) or "0"
end
local function my_hands()
	return (G.GAME and G.GAME.current_round and G.GAME.current_round.hands_left) or 0
end
local function my_skips()
	return (G.GAME and G.GAME.skips) or 0
end
local function my_lives()
	return MP.GAME.lives or 0
end

local function gen_seed()
	local cfg = MP.LOBBY.config
	if cfg.custom_seed and cfg.custom_seed ~= "random" and cfg.custom_seed ~= "" then
		return cfg.custom_seed
	end
	return MP.generate_seed()
end

-- Map each legacy action to its peer broadcast. Anything not listed (lobby/auth/
-- version/replay-stream actions the API now owns) is silently dropped.
local ROUTES = {
	startGame = function(_msg)
		-- Host generates the shared seed and starts everyone (host included via loopback).
		local seed = gen_seed()
		local stake = MP.LOBBY.deck.stake or MP.LOBBY.config.stake or 1
		broadcast("pvp_start_game", { seed = seed, stake = tostring(stake) })
	end,
	stopGame = function(_msg)
		broadcast("pvp_stop_game", {})
	end,
	readyBlind = function(_msg)
		broadcast("pvp_ready_blind", {})
	end,
	unreadyBlind = function(_msg)
		broadcast("pvp_unready_blind", {})
	end,
	failRound = function(_msg)
		broadcast("pvp_fail_round", {})
	end,
	failTimer = function(_msg)
		broadcast("pvp_fail_timer", {})
	end,
	failPvPTimer = function(_msg)
		broadcast("pvp_fail_pvp_timer", {})
	end,
	setLocation = function(msg)
		broadcast("pvp_location", { location = msg.location })
	end,
	playHand = function(msg)
		broadcast("pvp_play_hand", { score = msg.score, handsLeft = msg.handsLeft, skips = my_skips(), lives = my_lives() }) -- referee (host-authoritative)
		-- Display sync is the active blind's own decision now (see objects/blinds/nemesis.lua).
		MPAPI.calculate_blind({ hand_played = true, score = msg.score, hands_left = msg.handsLeft, skips = my_skips(), lives = my_lives() })
	end,
	setAnte = function(msg)
		broadcast("pvp_set_ante", { ante = msg.ante })
	end,
	newRound = function(_msg)
		broadcast("pvp_new_round", {})
	end,
	setFurthestBlind = function(msg)
		broadcast("pvp_set_furthest_blind", { furthestBlind = msg.furthestBlind })
	end,
	skip = function(msg)
		broadcast("pvp_skip", { skips = msg.skips, score = my_score_str(), handsLeft = my_hands(), lives = my_lives() }) -- referee (host-authoritative)
		-- Display sync is the active blind's own decision now (see objects/blinds/nemesis.lua).
		MPAPI.calculate_blind({ discarded = true, skips = msg.skips, score = my_score_str(), hands_left = my_hands(), lives = my_lives() })
	end,
	startAnteTimer = function(msg)
		broadcast("pvp_ante_timer", { time = msg.time, isPvP = msg.isPvP })
	end,
	pauseAnteTimer = function(msg)
		broadcast("pvp_pause_ante_timer", { time = msg.time })
	end,
	sendPhantom = function(msg)
		broadcast("pvp_send_phantom", { key = msg.key })
	end,
	removePhantom = function(msg)
		broadcast("pvp_remove_phantom", { key = msg.key })
	end,
	magnet = function(_msg)
		broadcast("pvp_magnet", {})
	end,
	magnetResponse = function(msg)
		broadcast("pvp_magnet_response", { key = msg.key })
	end,
	soldJoker = function(_msg)
		broadcast("pvp_sold_joker", {})
	end,
	asteroid = function(_msg)
		broadcast("pvp_asteroid", {})
	end,
	eatPizza = function(msg)
		broadcast("pvp_eat_pizza", { whole = msg.whole })
	end,
	spentLastShop = function(msg)
		broadcast("pvp_spent_last_shop", { amount = msg.amount })
	end,
	letsGoGamblingNemesis = function(_msg)
		broadcast("pvp_lets_go_gambling_nemesis", {})
	end,
	getEndGameJokers = function(_msg)
		broadcast("pvp_get_end_game_jokers", {})
	end,
	receiveEndGameJokers = function(msg)
		broadcast("pvp_receive_end_game_jokers", msg)
	end,
	getNemesisDeck = function(_msg)
		broadcast("pvp_get_nemesis_deck", {})
	end,
	receiveNemesisDeck = function(msg)
		broadcast("pvp_receive_nemesis_deck", msg)
	end,
	sendGameStats = function(_msg) end, -- local-only (handled by action_send_game_stats)
	endGameStatsRequested = function(_msg)
		broadcast("pvp_end_game_stats_requested", {})
	end,
	nemesisEndGameStats = function(msg)
		broadcast("pvp_nemesis_end_game_stats", msg)
	end,
	jimboAppear = function(msg)
		broadcast("pvp_jimbo_appear", msg)
	end,
	jimboTalk = function(msg)
		broadcast("pvp_jimbo_talk", msg)
	end,
	jimboMove = function(msg)
		broadcast("pvp_jimbo_move", msg)
	end,
	jimboRemove = function(_msg)
		broadcast("pvp_jimbo_remove", {})
	end,
}

function MP.net_route(msg)
	if type(msg) ~= "table" or not msg.action then
		return
	end
	local route = ROUTES[msg.action]
	if route then
		route(msg)
	end
	-- Unlisted actions (createLobby/joinLobby/readyLobby/leaveLobby/username/version/
	-- lobbyInfo/lobbyOptions/syncClient/streamLogLines/submitLogHashes) are owned by
	-- the API now, or are replay-stream features deferred for the port; drop them.
end

-- Replace the socket transport with the peer router. Client is the global table
-- defined in networking/action_handlers.lua.
if Client then
	Client.send = function(msg)
		MP.net_route(msg)
	end
end
