--- STEAMODDED HEADER
--- MOD_NAME: Multiplayer
--- MOD_ID: VirtualizedMultiplayer
--- MOD_AUTHOR: [virtualized, TGMM]
--- MOD_DESCRIPTION: Allows players to compete with their friends!
----------------------------------------------
------------MOD CORE--------------------------

-- Credit to Nyoxide for this custom loader
local moduleCache = {}
local relativeModPath = "Mods/Multiplayer/"
local function customLoader(moduleName)
	local filename = moduleName:gsub("%.", "/") .. ".lua"
	if moduleCache[filename] then
		return moduleCache[filename]
	end

	local filePath = relativeModPath .. filename
	local fileContent = love.filesystem.read(filePath)
	if fileContent then
		local moduleFunc = assert(load(fileContent, "@" .. filePath))
		moduleCache[filename] = moduleFunc
		return moduleFunc
	end

	return "\nNo module found: " .. moduleName
end

function SMODS.INIT.VirtualizedMultiplayer()
	---@diagnostic disable-next-line: deprecated
	table.insert(package.loaders, 1, customLoader)
	require("Items.Blind")
	require("Items.Deck")
	require("Lobby")
	require("Networking.Action_Handlers")
	require("Utils").get_username()
	require("UI.Lobby_UI")
	require("UI.Main_Menu")
	require("UI.Mod_Description").load_description_gui()
	require("UI.Game_UI")
	require("Misc.Disable_Restart")

	CONFIG = require("Config")
	NETWORKING_THREAD = love.thread.newThread(string.format("%sNetworking/Socket.lua", relativeModPath))
	NETWORKING_THREAD:start(CONFIG.URL, CONFIG.PORT)

	G.MULTIPLAYER.connect()
end

----------------------------------------------
------------MOD CORE END----------------------
