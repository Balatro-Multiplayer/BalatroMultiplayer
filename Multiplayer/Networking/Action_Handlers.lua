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
	G.MULTIPLAYER.update_player_usernames()
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

-- Client to Server
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
