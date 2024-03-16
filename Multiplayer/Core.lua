--- STEAMODDED HEADER
--- MOD_NAME: Multiplayer
--- MOD_ID: VirtualizedMultiplayer
--- MOD_AUTHOR: [virtualized, TGMM]
--- MOD_DESCRIPTION: Allows players to compete with their friends! Contact @virtualized on discord for mod assistance.

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
	table.insert(package.loaders, 1, customLoader)
	require("Blind")
	require("Deck")
	require("Main_Menu")
	require("Utils").get_username()
	require("Action_Handlers")
	require("Mod_Description").load_description_gui()
	require("Game_UI")

	CONFIG = require("Config")
	NETWORKING_THREAD = love.thread.newThread(relativeModPath .. "Networking.lua")
	NETWORKING_THREAD:start(CONFIG.URL, CONFIG.PORT)

	ActionHandlers.connect()
end

----------------------------------------------
------------MOD CORE END----------------------
