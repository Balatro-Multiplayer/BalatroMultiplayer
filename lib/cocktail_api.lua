local BMP_API_URL = "https://bmp.casjb.co.uk" -- british man

-- Background thread that fetches the current weekly cocktail without blocking the main thread.
-- Result is pushed to a love.thread.Channel and polled from the main thread.
local _cocktail_thread_code = [[
	local json = require("json")
	local url = ...
	local ch = love.thread.getChannel("mp_cocktail_api")
	local ok, err = pcall(function()
		local handle = io.popen('curl -s -m 5 "' .. url .. '/cocktails/current?gamemode=weekly"')
		if not handle then ch:push("null"); return end
		local response = handle:read("*a")
		handle:close()
		if not response or response == "" then ch:push("null"); return end
		ch:push(response)
	end)
	if not ok then ch:push("null") end
]]

function MP.fetch_current_cocktail()
	local thread = love.thread.newThread(_cocktail_thread_code)
	thread:start(BMP_API_URL)
end

-- Call from apply() or wherever the result is needed.
-- Returns true if an override was found and applied, false otherwise.
function MP.poll_cocktail_override()
	local ch = love.thread.getChannel("mp_cocktail_api")
	local response = ch:pop()
	if not response or response == "null" then
		MP.LOBBY.cocktail_override = nil
		MP.LOBBY.cocktail_override_name = nil
		return false
	end
	local ok, decoded = pcall(json.decode, response)
	if ok and decoded and decoded.backs and type(decoded.backs) == "table" and #decoded.backs >= 1 then
		MP.LOBBY.cocktail_override = decoded.backs
		MP.LOBBY.cocktail_override_name = decoded.name
		sendDebugMessage("Fetched weekly cocktail: " .. (decoded.name or "unknown"), "MULTIPLAYER")
		return true
	end
	MP.LOBBY.cocktail_override = nil
	MP.LOBBY.cocktail_override_name = nil
	return false
end
