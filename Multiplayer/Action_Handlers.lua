--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD ACTION_HANDLERS--------------------
local Lobby = require("Lobby")

ActionHandlers = {}
ActionHandlers.Client = {}

function ActionHandlers.Client.send(msg)
	love.thread.getChannel("uiToNetwork"):push(msg)
end

-- Server to Client
function ActionHandlers.set_username(username)
	Lobby.username = username or "Guest"
	if Lobby.connected then
		ActionHandlers.Client.send("action:username,username:" .. Lobby.username)
	end
end

local function action_connected()
	sendDebugMessage("Client connected to multiplayer server")
	Lobby.connected = true
	Lobby.update_connection_status()
	ActionHandlers.Client.send("action:username,username:" .. Lobby.username)
end

local function action_joinedLobby(code)
	sendDebugMessage("Joining lobby " .. code)
	Lobby.code = code
	ActionHandlers.lobby_info()
	Lobby.update_connection_status()
end

local function action_lobbyInfo(host, guest, is_host)
	Lobby.players = {}
	Lobby.is_host = is_host == "true"
	Lobby.host = { username = host }
	if guest ~= nil then
		Lobby.guest = { username = guest }
	end
	Lobby.update_player_usernames()
end

local function action_error(message)
	sendDebugMessage(message)

	Utils.overlay_message(message)
end

local function action_keep_alive()
	ActionHandlers.Client.send("action:keepAliveAck")
end

-- Client to Server
function ActionHandlers.create_lobby()
	-- TODO: This is hardcoded to attrition for now, must be changed
	ActionHandlers.Client.send("action:createLobby,gameMode:attrition")
end

function ActionHandlers.join_lobby(code)
	ActionHandlers.Client.send("action:joinLobby,code:" .. code)
end

function ActionHandlers.lobby_info()
	ActionHandlers.Client.send("action:lobbyInfo")
end

function ActionHandlers.leave_lobby()
	ActionHandlers.Client.send("action:leaveLobby")
end

-- Utils
function ActionHandlers.connect()
	ActionHandlers.Client.send("connect")
end

local function string_to_table(str)
	local tbl = {}
	for key, value in string.gmatch(str, "([^,]+):([^,]+)") do
		tbl[key] = value
	end
	return tbl
end

local game_update_ref = Game.update
function Game.update(arg_298_0, arg_298_1)
	game_update_ref(arg_298_0, arg_298_1)

	repeat
		local msg = love.thread.getChannel("networkToUi"):pop()
		if msg then
			local parsedAction = string_to_table(msg)

			sendDebugMessage("Client got " .. parsedAction.action .. " message")

			sendDebugMessage(msg)

			if parsedAction.action == "connected" then
				action_connected()
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

return ActionHandlers

----------------------------------------------
------------MOD ACTION_HANDLERS END----------------
