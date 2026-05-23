local networkToUi = love.thread.getChannel("networkToUi")

-- water is wet
function MP.UTILS.log_mem_debug_messages()
	-- respect opt-out
	if MP.EXPERIMENTAL.mem_debug then
		sendDebugMessage("Lua memory in use: "..(collectgarbage("count")/1024).." MiB", "MULTIPLAYER")
		sendDebugMessage("Texture memory in use: "..(love.graphics.getStats().texturememory/1024/1024).." MiB", "MULTIPLAYER")
		if networkToUi:getCount() > 10 then -- look i have no idea what's high but i checked briefly and it doesn't seem to go above 0
			sendDebugMessage("High networkToUi count: "..networkToUi:getCount(), "MULTIPLAYER")
		end
		if MP._DEBUG_PANIC_COLLECTS then
			sendDebugMessage("nuGC panic collects: "..MP._DEBUG_PANIC_COLLECTS, "MULTIPLAYER")
		end
	end
end