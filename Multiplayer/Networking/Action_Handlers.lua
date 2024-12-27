----------------------------------------------
------------MOD ACTION HANDLERS---------------

Client = {}

function Client.send(msg)
	love.thread.getChannel("uiToNetwork"):push(msg)
end

-- Server to Client
function G.MULTIPLAYER.set_username(username)
	G.LOBBY.username = username or "Guest"
	if G.LOBBY.connected then
		Client.send(string.format("action:username,username:%s", G.LOBBY.username))
	end
end

local function action_connected()
	sendDebugMessage("Client connected to multiplayer server")
	G.LOBBY.connected = true
	G.MULTIPLAYER.update_connection_status()
	Client.send(string.format("action:username,username:%s", G.LOBBY.username))
end

local function action_joinedLobby(code, type)
	sendDebugMessage(string.format("Joining lobby %s", code))
	G.LOBBY.code = code
	G.LOBBY.type = type
	reset_gamemode_modifiers()
	G.MULTIPLAYER.lobby_info()
	G.MULTIPLAYER.update_connection_status()
end

local function action_lobbyInfo(host, guest, is_host)
	G.LOBBY.players = {}
	G.LOBBY.is_host = is_host == "true"
	if is_host == "true" then
		G.MULTIPLAYER.lobby_options()
	end
	G.LOBBY.host = { username = host }
	if guest ~= nil then
		G.LOBBY.guest = { username = guest }
	else
		G.LOBBY.guest = {}
	end
	-- TODO: This should check for player count instead
	-- once we enable more than 2 players
	G.LOBBY.ready_to_start = G.LOBBY.is_host and guest ~= nil

	if G.STAGE == G.STAGES.MAIN_MENU then
		G.MULTIPLAYER.update_player_usernames()
	end
end

local function action_error(message)
	sendDebugMessage(message)

	Utils.overlay_message(message)
end

local function action_keep_alive()
	Client.send("action:keepAliveAck")
end

local function action_disconnected()
	G.LOBBY.connected = false
	if G.LOBBY.code then
		G.LOBBY.code = nil
	end
	G.MULTIPLAYER.update_connection_status()
end

---@param deck string
---@param seed string
---@param stake_str string
local function action_start_game(deck, seed, stake_str)
	reset_game_states()
	local stake = tonumber(stake_str)
	G.MULTIPLAYER.set_ante(0)
	G.FUNCS.lobby_start_run(nil, { deck = deck, seed = seed, stake = stake })
end

local function action_start_blind()
	G.MULTIPLAYER_GAME.ready_blind = false
	-- TODO: This should check that player is in a
	-- multiplayer game
	G.FUNCS.toggle_shop()
end

---@param score_str string
---@param hands_left_str string
local function action_enemy_info(score_str, hands_left_str)
	local score = tonumber(score_str)
	local hands_left = tonumber(hands_left_str)

	if score == nil or hands_left == nil then
		sendDebugMessage("Invalid score or hands_left")
		return
	end

	G.MULTIPLAYER_GAME.enemy.score = score
	G.MULTIPLAYER_GAME.enemy.hands = hands_left
	if is_pvp_boss() then
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count"):juice_up()
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned"):juice_up()
	end
end

local function action_stop_game()
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		G.FUNCS.go_to_menu()
		G.MULTIPLAYER.update_connection_status()
		reset_game_states()
	end
end

local function action_end_pvp()
	G.MULTIPLAYER_GAME.end_pvp = true
end

---@param lives number
local function action_player_info(lives)
	if G.MULTIPLAYER_GAME.lives ~= lives then
		if G.MULTIPLAYER_GAME.lives ~= 0 and G.LOBBY.config.gold_on_life_loss then
			G.MULTIPLAYER_GAME.comeback_bonus_given = false
			G.MULTIPLAYER_GAME.comeback_bonus = G.MULTIPLAYER_GAME.comeback_bonus + 1
		end
		ease_lives(lives - G.MULTIPLAYER_GAME.lives)
	end
	G.MULTIPLAYER_GAME.lives = lives
end

local function action_win_game()
	win_game()
	G.GAME.won = true
end

local function action_lose_game()
	G.STATE_COMPLETE = false
	G.STATE = G.STATES.GAME_OVER
end

local function action_game_info(small, big, boss)
	G.GAME.round_resets.blind_choices = {
		Small = small or "bl_small",
		Big = big or "bl_big",
		Boss = boss or get_new_boss(),
	}
	G.MULTIPLAYER_GAME.loaded_ante = G.GAME.round_resets.ante
	G.MULTIPLAYER.loading_blinds = false
end

local function action_lobby_options(options)
	for k, v in pairs(options) do
		local parsed_v = v
		if v == "true" then
			parsed_v = true
		elseif v == "false" then
			parsed_v = false
		end
		if k == "starting_lives" or k == "draft_starting_antes" then
			parsed_v = tonumber(v)
		end
		G.LOBBY.config[k] = parsed_v
		if G.OVERLAY_MENU then
			local config_uie = G.OVERLAY_MENU:get_UIE_by_ID(k .. "_toggle")
			if config_uie then
				G.FUNCS.toggle(config_uie)
			end
		end
	end
end

local function action_version()
	G.MULTIPLAYER.version()
end

-- #region Client to Server
function G.MULTIPLAYER.create_lobby(gamemode)
	Client.send(string.format("action:createLobby,gameMode:%s", gamemode))
end

function G.MULTIPLAYER.join_lobby(code)
	Client.send(string.format("action:joinLobby,code:%s", code))
end

function G.MULTIPLAYER.lobby_info()
	Client.send("action:lobbyInfo")
end

function G.MULTIPLAYER.leave_lobby()
	Client.send("action:leaveLobby")
end

function G.MULTIPLAYER.start_game()
	Client.send("action:startGame")
end

function G.MULTIPLAYER.ready_blind()
	Client.send("action:readyBlind")
end

function G.MULTIPLAYER.unready_blind()
	Client.send("action:unreadyBlind")
end

function G.MULTIPLAYER.stop_game()
	Client.send("action:stopGame")
end

function G.MULTIPLAYER.game_info()
	Client.send("action:gameInfo")
end

function G.MULTIPLAYER.fail_round()
	if G.LOBBY.config.no_gold_on_round_loss then
		G.GAME.blind.dollars = 0
	end
	Client.send("action:failRound")
end

function G.MULTIPLAYER.version()
	Client.send(string.format("action:version,version:%s", MULTIPLAYER_VERSION))
end

---@param score number
---@param hands_left number
function G.MULTIPLAYER.play_hand(score, hands_left)
	Client.send(string.format("action:playHand,score:%d,handsLeft:%d", score, hands_left))
end

function G.MULTIPLAYER.lobby_options()
	local msg = "action:lobbyOptions"
	for k, v in pairs(G.LOBBY.config) do
		msg = msg .. string.format(",%s:%s", k, tostring(v))
	end
	Client.send(msg)
end

function G.MULTIPLAYER.set_ante(ante)
	Client.send(string.format("action:setAnte,ante:%d", ante))
end
-- #endregion Client to Server

-- Utils
function G.MULTIPLAYER.connect()
	Client.send("connect")
end

local function string_to_table(str)
	local tbl = {}
	for part in string.gmatch(str, "([^,]+)") do
		local key, value = string.match(part, "([^:]+):(.+)")
		if key and value then
			tbl[key] = value
		end
	end
	return tbl
end

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	game_update_ref(self, dt)

	repeat
		local msg = love.thread.getChannel("networkToUi"):pop()
		if msg then
			local parsedAction = string_to_table(msg)

			sendDebugMessage(string.format("Client got %s message", parsedAction.action))

			if parsedAction.action == "connected" then
				action_connected()
			elseif parsedAction.action == "version" then
				action_version()
			elseif parsedAction.action == "disconnected" then
				action_disconnected()
			elseif parsedAction.action == "joinedLobby" then
				action_joinedLobby(parsedAction.code, parsedAction.type)
			elseif parsedAction.action == "lobbyInfo" then
				action_lobbyInfo(parsedAction.host, parsedAction.guest, parsedAction.isHost)
			elseif parsedAction.action == "startGame" then
				action_start_game(parsedAction.deck, parsedAction.seed, parsedAction.stake)
			elseif parsedAction.action == "startBlind" then
				action_start_blind()
			elseif parsedAction.action == "enemyInfo" then
				action_enemy_info(parsedAction.score, parsedAction.handsLeft)
			elseif parsedAction.action == "stopGame" then
				action_stop_game()
			elseif parsedAction.action == "endPvP" then
				action_end_pvp()
			elseif parsedAction.action == "playerInfo" then
				action_player_info(parsedAction.lives)
			elseif parsedAction.action == "winGame" then
				action_win_game()
			elseif parsedAction.action == "loseGame" then
				action_lose_game()
			elseif parsedAction.action == "gameInfo" then
				action_game_info(parsedAction.small, parsedAction.big, parsedAction.boss)
			elseif parsedAction.action == "lobbyOptions" then
				action_lobby_options(parsedAction)
			elseif parsedAction.action == "error" then
				action_error(parsedAction.message)
			elseif parsedAction.action == "keepAlive" then
				action_keep_alive()
			end
		end
	until not msg
end

----------------------------------------------
------------MOD ACTION HANDLERS END-----------
