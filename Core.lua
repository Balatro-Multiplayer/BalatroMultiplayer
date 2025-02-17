G.MULTIPLAYER = {}

SMODS.Atlas({
	key = "modicon",
	path = "modicon.png",
	px = 34,
	py = 34,
})

function G.MULTIPLAYER.load_mp_file(file)
	local chunk, err = SMODS.load_file(file, "VirtualizedMultiplayer")
	if chunk then
		local ok, func = pcall(chunk)
		if ok then
			return func
		else
			sendWarnMessage("Failed to process file: " .. func, "MULTIPLAYER")
		end
	else
		sendWarnMessage("Failed to find or compile file: " .. tostring(err), "MULTIPLAYER")
	end
	return nil
end

local load_mp_file = G.MULTIPLAYER.load_mp_file

load_mp_file("Utils.lua")

load_mp_file("Compatibility/CompatibilityUtils.lua")
load_mp_file("Compatibility/Talisman.lua")
load_mp_file("Compatibility/Cryptid.lua")
load_mp_file("Compatibility/Pokermon.lua")
load_mp_file("Compatibility/Ortalab.lua")
load_mp_file("Compatibility/Jen.lua")
load_mp_file("Compatibility/Draft.lua")
load_mp_file("Compatibility/JokerDisplay.lua")
load_mp_file("Compatibility/Distro.lua")

load_mp_file("Lobby.lua")
load_mp_file("Networking/Action_Handlers.lua")

load_mp_file("Items/ItemUtils.lua")
load_mp_file("Items/Edition.lua")
load_mp_file("Items/Sticker.lua")
load_mp_file("Items/Blind.lua")
load_mp_file("Items/Deck.lua")
load_mp_file("Items/Jokers.lua")
load_mp_file("Items/Consumables.lua")

G.MULTIPLAYER.COMPONENTS = {}
load_mp_file("Components/Disableable_Button.lua")
load_mp_file("Components/Disableable_Option_Cycle.lua")
load_mp_file("Components/Disableable_Toggle.lua")

load_mp_file("UI/Lobby_UI.lua")
load_mp_file("UI/Main_Menu.lua")
load_mp_file("UI/Game_UI.lua")

load_mp_file("Misc/Disable_Restart.lua")
load_mp_file("Misc/Mod_Hash.lua")

local SOCKET = load_mp_file("Networking/Socket.lua")
NETWORKING_THREAD = love.thread.newThread(SOCKET)
NETWORKING_THREAD:start(
	SMODS.Mods["VirtualizedMultiplayer"].config.server_url,
	SMODS.Mods["VirtualizedMultiplayer"].config.server_port
)
G.MULTIPLAYER.connect()

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
							text = G.localization.misc.dictionary["join_discord"] or "Join the ",
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
							G.localization.misc.dictionary["discord_name"] or "Balatro Multiplayer Discord Server",
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
							text = G.localization.misc.dictionary["discord_msg"]
								or "You can report any bugs and find people to play with there!",
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
							text = G.localization.misc.dictionary["username"] or "Username:",
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
					create_text_input({
						w = 4,
						max_length = 25,
						prompt_text = G.localization.misc.dictionary["enter_username"] or "Enter Username",
						ref_table = G.LOBBY,
						ref_value = "username",
						extended_corpus = true,
						keyboard_offset = 1,
						callback = function(val)
							G.MULTIPLAYER.UTILS.save_username(G.LOBBY.username)
						end,
					}),
					{
						n = G.UIT.T,
						config = {
							scale = 0.3,
							text = G.localization.misc.dictionary["enter_to_save"] or "Press enter to save",
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

G.C.MULITPLAYER = HEX("AC3232")
