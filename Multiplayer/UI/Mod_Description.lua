----------------------------------------------
------------MOD DESCRIPTION-------------------

local Utils = require("Utils")

Description = {}

function Description.load_description_gui()
	SMODS.registerUIElement("VirtualizedMultiplayer", {
		{
			n = G.UIT.R,
			config = {
				padding = 0.5,
				align = "cm",
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
								text = "Username:",
								colour = G.C.UI.TEXT_LIGHT,
							},
						},
						create_text_input({
							w = 4,
							max_length = 25,
							prompt_text = "Enter Username",
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
								text = "Press enter to save",
								colour = G.C.UI.TEXT_LIGHT,
							},
						},
					},
				},
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
								text = "Join the ",
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
								"Balatro Multiplayer Discord Server",
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
								text = "You can report any bugs and find people to play with there!",
								shadow = true,
								scale = 0.375,
								colour = G.C.UI.TEXT_LIGHT,
							},
						},
					},
				},
			},
		},
	})
end

function G.FUNCS.multiplayer_discord(e)
	love.system.openURL("https://discord.gg/gEemz4ptuF")
end

return Description

----------------------------------------------
------------MOD DESCRIPTION END---------------
