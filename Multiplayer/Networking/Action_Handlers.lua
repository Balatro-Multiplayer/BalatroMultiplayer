--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

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

local function action_joinedLobby(code)
	sendDebugMessage(string.format("Joining lobby %s", code))
	G.LOBBY.code = code
	G.MULTIPLAYER.lobby_info()
	G.MULTIPLAYER.update_connection_status()
end

local function action_lobbyInfo(host, guest, is_host)
	G.LOBBY.players = {}
	G.LOBBY.is_host = is_host == "true"
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
		G.FUNCS.go_to_menu()
	end
	G.MULTIPLAYER.update_connection_status()
end

---@param deck string
---@param seed string
---@param stake_str string
local function action_start_game(deck, seed, stake_str)
	local stake = tonumber(stake_str)
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

	G.LOBBY.enemy.score = score
	G.LOBBY.enemy.hands = hands_left
	if G.GAME.blind.boss then
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count"):juice_up()
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned"):juice_up()
	end
end

local function action_stop_game()
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		G.FUNCS.go_to_menu()
		G.MULTIPLAYER.update_connection_status()
	end
end

local function action_end_pvp()
	G.STATE_COMPLETE = false
	G.STATE = G.STATES.NEW_ROUND
end

---@param lives number
local function action_player_info(lives)
	if (G.MULTIPLAYER_GAME.lives ~= lives) then
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

-- #region Client to Server
function G.MULTIPLAYER.create_lobby()
	-- TODO: This is hardcoded to attrition for now, must be changed
	Client.send("action:createLobby,gameMode:attrition")
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

---@param score number
---@param hands_left number
function G.MULTIPLAYER.play_hand(score, hands_left)
	Client.send(string.format("action:playHand,score:%d,handsLeft:%d", score, hands_left))
end
-- #endregion Client to Server

-- Utils
function G.MULTIPLAYER.connect()
	Client.send("connect")
end

local function string_to_table(str)
	local tbl = {}
	for key, value in string.gmatch(str, "([^,]+):([^,]+)") do
		tbl[key] = value
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
			elseif parsedAction.action == "disconnected" then
				action_disconnected()
			elseif parsedAction.action == "joinedLobby" then
				action_joinedLobby(parsedAction.code)
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
