--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD NETWORKING--------------------
local Lobby = require "Lobby"
local Config = require "Config"
local socket = require "socket"

Networking = {}

function string_to_table(str)
  local tbl = {}
  for key, value in string.gmatch(str, '([^,]+):([^,]+)') do
      tbl[key] = value
  end
  return tbl
end

function Networking.set_username(username)
  Lobby.username = username or 'Guest'
  if Lobby.connected then
    Networking.Client:send('action:username,username:'..Lobby.username)
  end
end

local function action_connected()
  sendDebugMessage("Client connected to multiplayer server")
  Lobby.connected = true
  Lobby.update_connection_status()
  Networking.Client:send('action:username,username:'..Lobby.username)
end

local function action_joinedLobby(code)
  sendDebugMessage("Joining lobby " .. code)
  Lobby.code = code
  Lobby.update_connection_status()
  Networking.lobby_info()
end

local function action_lobbyInfo(host, guest)
  Lobby.players = {}
  table.insert(Lobby.players, { username = host })
  if guest ~= nil then
    table.insert(Lobby.players, { username = guest })
  end
  Lobby.update_player_usernames()
end

local function action_error(message)
  sendDebugMessage(message)

  Utils.overlay_message(message)
end

local function action_keep_alive()
  Networking.Client:send('action:keepAliveAck')
end

local game_update_ref = Game.update
function Game.update(arg_298_0, arg_298_1)
  if Networking.Client then
    repeat
      local data, error, partial = Networking.Client:receive()
      if data then
        local t = string_to_table(data)

        sendDebugMessage('Client got ' .. t.action .. ' message')

        if t.action == 'connected' then
          action_connected()
        elseif t.action == 'joinedLobby' then
          action_joinedLobby(t.code)
        elseif t.action == 'lobbyInfo' then
          action_lobbyInfo(t.host, t.guest)
        elseif t.action == 'error' then
          action_error(t.message)
        elseif t.action == 'keepAlive' then
          action_keep_alive()
        end
      end
    until not data
  end

  game_update_ref(arg_298_0, arg_298_1)
end

function Networking.authorize()
  sendDebugMessage(string.format("Attempting to connect to multiplayer server... URL: %s, PORT: %d", Config.URL, Config.PORT))

  Networking.Client = socket.tcp()

  Networking.Client:setoption('tcp-nodelay', true)
  local connectionResult, errorMessage = Networking.Client:connect(Config.URL, Config.PORT) -- Not sure if I want to make these values public yet

  if connectionResult ~= 1 then
    sendDebugMessage(string.format("%s", errorMessage))
  end

  Networking.Client:settimeout(0)
end

function Networking.create_lobby()
  Networking.Client:send('action:createLobby')
end

function Networking.join_lobby(code)
  Networking.Client:send('action:joinLobby,code:' .. code)
end

function Networking.lobby_info()
  Networking.Client:send('action:lobbyInfo')
end

function Networking.leave_lobby()
  Networking.Client:send('action:leaveLobby')
end

return Networking

----------------------------------------------
------------MOD NETWORKING END----------------