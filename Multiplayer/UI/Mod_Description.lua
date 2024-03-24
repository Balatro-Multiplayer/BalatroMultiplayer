--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

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
	})
end

return Description

----------------------------------------------
------------MOD DESCRIPTION END---------------
