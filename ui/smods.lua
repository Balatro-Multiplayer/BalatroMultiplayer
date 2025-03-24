SMODS.Mods.Multiplayer.credits_tab = function()
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
							text = localize("k_join_discord"),
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
							localize("b_mp_discord"),
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
							text = localize("k_discord_msg"),
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

SMODS.Mods.Multiplayer.config_tab = function()
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
				},
				nodes = {
					create_toggle({
						id = "misprint_display_toggle",
						label = localize("b_misprint_display"),
						ref_table = SMODS.Mods["Multiplayer"].config,
						ref_value = "misprint_display",
					}),
				},
			},
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
							text = localize("k_username"),
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
					create_text_input({
						w = 4,
						max_length = 25,
						prompt_text = localize("k_enter_username"),
						ref_table = MP.LOBBY,
						ref_value = "username",
						extended_corpus = true,
						keyboard_offset = 1,
						callback = function(val)
							MP.UTILS.save_username(MP.LOBBY.username)
						end,
					}),
					{
						n = G.UIT.T,
						config = {
							scale = 0.3,
							text = G.localization.misc.dictionary["k_enter_to_save"] or "Press enter to save",
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
