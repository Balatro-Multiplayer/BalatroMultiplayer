-- Code for networking stuff that runs in a separate thread

-- Since threads run on a separate lua environment, we need to require
-- the necessary modules again
return [[
local CONFIG_URL, CONFIG_PORT = ...

require("love.filesystem")
local socket = require("socket")

local DEBUGGING = false

-- Defining this again, for debugging this thread
local function initializeThreadDebugSocketConnection()
	CLIENT = socket.connect("localhost", 12346)
	if not CLIENT then
		sendWarnMessage("Failed to connect to the debug server", "MULTIPLAYER")
	end
end

function SEND_THREAD_DEBUG_MESSAGE(message)
	if DEBUGGING and CLIENT and message then
		CLIENT:send(message .. "\n")
	end
end

if DEBUGGING then
	initializeThreadDebugSocketConnection()
end

Networking = {}
local isSocketClosed = true
local networkToUiChannel = love.thread.getChannel("networkToUi")
local uiToNetworkChannel = love.thread.getChannel("uiToNetwork")

function Networking.connect()
	-- TODO: Check first if Networking.Client is not null
	-- and if it is, skip this function

	SEND_THREAD_DEBUG_MESSAGE(
		string.format("Attempting to connect to multiplayer server... URL: %s, PORT: %d", CONFIG_URL, CONFIG_PORT)
	)

	Networking.Client = socket.tcp()
	-- Allow for 10 seconds to reconnect
	Networking.Client:settimeout(10)

	Networking.Client:setoption("tcp-nodelay", true)
	local connectionResult, errorMessage = Networking.Client:connect(CONFIG_URL, CONFIG_PORT) -- Not sure if I want to make these values public yet

	if connectionResult ~= 1 then
		SEND_THREAD_DEBUG_MESSAGE(string.format("%s", errorMessage))
		networkToUiChannel:push("action:error,message:Failed to connect to multiplayer server")
	else
		isSocketClosed = false
	end

	Networking.Client:settimeout(0)
end

-- Check for messages from the main thread
local mainThreadMessageQueue = function()
	-- Executes a max of requestsPerCycle action requests
	-- from the main thread and then yields
	local requestsPerCycle = 25
	while true do
		for _ = 1, requestsPerCycle do
			local msg = uiToNetworkChannel:pop()
			if msg then
				if msg:find("^action") ~= nil then
					Networking.Client:send(msg .. "\n")
				elseif msg == "connect" then
					Networking.connect()
				end
			else
				-- If there are no more messages, yield
				coroutine.yield()
			end
		end

		coroutine.yield()
	end
end
local mainThreadCoroutine = coroutine.create(mainThreadMessageQueue)

local timer = function(time)
	local init = os.time()
	local diff = os.difftime(os.time(), init)
	while diff < time do
		coroutine.yield(diff)
		diff = os.difftime(os.time(), init)
	end
end
local timerCoroutine = coroutine.create(timer)

-- All values are in seconds
local keepAliveInitialTimeout = 7
local keepAliveRetryTimeout = 3
local keepAliveRetryCount = 3

local isRetry = false
local retryCount = 0

-- Check for network packets
local networkPacketQueue = function()
	local packetsPerCycle = 25
	while true do
		if Networking.Client then
			-- Tries to fetch a packet a max of packetsPerCycle times
			-- and then yields
			for _ = 1, packetsPerCycle do
				local data, error, partial = Networking.Client:receive()
				if data then
					-- Packet arrived, reset retries
					isRetry = false
					retryCount = 0
					-- Also reset timer
					timerCoroutine = coroutine.create(timer)

					-- For now, we just send the string as is to the main thread
					networkToUiChannel:push(data)
				elseif error == "close" then
					-- Handle connection closed gracefully
					isSocketClosed = true
					retryCount = 0
					isRetry = false

					timerCoroutine = coroutine.create(timer)
					networkToUiChannel:push("action:disconnected")
				else
					-- If there are no more packets, yield
					coroutine.yield()
				end
			end

			coroutine.yield()
		end

		coroutine.yield()
	end
end
local networkCoroutine = coroutine.create(networkPacketQueue)

-- Checks for network packets,
-- then sends them to the main thread
-- then advances timers
-- and then sleeps
while true do
	coroutine.resume(mainThreadCoroutine)
	coroutine.resume(networkCoroutine)

	-- Run Timer
	if not isSocketClosed and coroutine.status(timerCoroutine) ~= "dead" then
		coroutine.resume(timerCoroutine, keepAliveInitialTimeout)
	elseif not isSocketClosed then
		-- Timer triggered
		isRetry = true

		if retryCount > keepAliveRetryCount then
			Networking.Client:close()

			-- Connection closed, restart everything
			isSocketClosed = true
			retryCount = 0
			isRetry = false

			timerCoroutine = coroutine.create(timer)

			networkToUiChannel:push("action:disconnected")
		end

		if isRetry then
			retryCount = retryCount + 1
			-- Send keepAlive without cutting the line
			uiToNetworkChannel:push("action:keepAlive")

			-- Restart the timer
			timerCoroutine = coroutine.create(timer)
			coroutine.resume(timerCoroutine, keepAliveRetryTimeout)
		end
	end

	-- Sleeps for 200 milliseconds
	socket.sleep(0.2)
end
]]
