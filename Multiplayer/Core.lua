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

function LoadMod()
	---@diagnostic disable-next-line: deprecated
	table.insert(package.loaders, 1, customLoader)
	require("Lobby")
	require("Networking.Action_Handlers")
	require("Utils").get_username()
	require("UI.Localization")
	require("Items.Blind")
	require("Items.Deck")
	require("UI.Lobby_UI")
	require("UI.Main_Menu")
	require("UI.Game_UI")
	require("Misc.Disable_Restart")
	require("Misc.Mod_Hash")

	CONFIG = require("Config")
	NETWORKING_THREAD = love.thread.newThread(string.format("%sNetworking/Socket.lua", relativeModPath))
	NETWORKING_THREAD:start(CONFIG.URL, CONFIG.PORT)

	G.MULTIPLAYER.connect()
end

SMODS.Mods.VirtualizedMultiplayer.credits_tab = function()
	return {
		n = G.UIT.ROOT,
		config = {
			r = 0.1,
			minw = 5,
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = mp_localize("join_discord", "Join the "),
							shadow = true,
							scale = 0.6,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0.2,
					align = "cm",
				},
				nodes = {
					UIBox_button({
						minw = 6,
						button = "multiplayer_discord",
						label = {
							mp_localize("discord_name", "Balatro Multiplayer Discord Server"),
						},
					}),
				},
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0.2,
					align = "cm",
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = mp_localize(
								"discord_msg",
								"You can report any bugs and find people to play with there!"
							),
							shadow = true,
							scale = 0.375,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
		},
	}
end

SMODS.Mods.VirtualizedMultiplayer.config_tab = function()
	return {
		n = G.UIT.ROOT,
		config = {
			r = 0.1,
			minw = 5,
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			{
				n = G.UIT.R,
				config = {
					padding = 0.5,
					align = "cm",
					id = "username_input_box",
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							scale = 0.6,
							text = mp_localize("username", "Username:"),
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
					create_text_input({
						w = 4,
						max_length = 25,
						prompt_text = mp_localize("enter_username", "Enter Username"),
						ref_table = G.LOBBY,
						ref_value = "username",
						extended_corpus = true,
						keyboard_offset = 1,
						callback = function(val)
							Utils.save_username(G.LOBBY.username)
						end,
					}),
					{
						n = G.UIT.T,
						config = {
							scale = 0.3,
							text = mp_localize("enter_to_save", "Press enter to save"),
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
		},
	}
end

function G.FUNCS.multiplayer_discord(e)
	love.system.openURL("https://discord.gg/gEemz4ptuF")
end

LoadMod()
