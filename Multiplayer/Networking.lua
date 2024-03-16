--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD NETWORKING--------------------

-- Code for networking stuff that runs in a separate thread

-- Since threads run on a separate lua environment, we need to require
-- the necessary modules again
local CONFIG_URL, CONFIG_PORT = ...

require("love.filesystem")
SOCKET = require("socket")

-- Defining this again, for debugging this thread
local function initializeThreadDebugSocketConnection()
	CLIENT = SOCKET.connect("localhost", 12346)
	if not CLIENT then
		print("Failed to connect to the debug server")
	end
end

function SEND_THREAD_DEBUG_MESSAGE(message)
	if CLIENT and message then
		CLIENT:send(message .. "\n")
	end
end

initializeThreadDebugSocketConnection()

Networking = {}

function Networking.connect()
	SEND_THREAD_DEBUG_MESSAGE(
		string.format("Attempting to connect to multiplayer server... URL: %s, PORT: %d", CONFIG_URL, CONFIG_PORT)
	)

	Networking.Client = SOCKET.tcp()

	Networking.Client:setoption("tcp-nodelay", true)
	local connectionResult, errorMessage = Networking.Client:connect(CONFIG_URL, CONFIG_PORT) -- Not sure if I want to make these values public yet

	if connectionResult ~= 1 then
		SEND_THREAD_DEBUG_MESSAGE(string.format("%s", errorMessage))
	end

	Networking.Client:settimeout(0)
end

-- TODO: Put this in a coroutine
while true do
	-- Check for messages from the main thread
	repeat
		local msg = love.thread.getChannel("uiToNetwork"):pop()
		if msg then
			if msg:find("^action") ~= nil then
				Networking.Client:send(msg .. "\n")
			elseif msg == "connect" then
				Networking.connect()
			end
		end
	until not msg

	-- Do networking stuff
	if Networking.Client then
		repeat
			local data, error, partial = Networking.Client:receive()
			if data then
				-- For now, we just send the string as is to the main thread
				love.thread.getChannel("networkToUi"):push(data)
			end
		until not data
	end
end

----------------------------------------------
------------MOD NETWORKING END----------------
