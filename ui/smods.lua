SMODS.Mods.Multiplayer.credits_tab = function()
    local scale = 0.75
	return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 6,
			r = 0.1,
			minw = 6,
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK
		},
		nodes = {
			{
				n = G.UIT.R,
				config = {
					padding = 0.2,
					align = "cm"
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize('k_created_by'),
							shadow = true,
							scale = scale * 0.8,
							colour = G.C.UI.TEXT_LIGHT
						}
					},
					{
						n = G.UIT.T,
						config = {
							text = "Virtualized",
							shadow = true,
							scale = scale * 0.8,
							colour = G.C.DARK_EDITION
						}
					}
				}
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm"
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize('k_major_contributors'),
							shadow = true,
							scale = scale * 0.8,
							colour = G.C.UI.TEXT_LIGHT
						}
					},
				}
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0.2,
					align = "cm"
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = "TGMM, Toneblock, CUexter, Brawmario, Divvy, Andy, and many more!",
							shadow = true,
							scale = scale * 0.8,
							colour = G.C.RED
						}
					}
				}
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
				},
				nodes = {
					UIBox_button({
						minw = 3.85,
						button = "bmp_github",
						label = {localize('b_github_project')}
					})
				}
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
				},
				nodes = {
					UIBox_button({
						minw = 3.85 * 2,
						button = "bmp_github",
						label = {localize('b_mp_discord')}
					})
				}
			},
		}
	}
end

SMODS.Mods.Multiplayer.config_tab = function()
	local blind_anim = AnimatedSprite(0,0, 1.4, 1.4, G.ANIMATION_ATLAS['mp_player_blind_col'], G.P_BLINDS[MP.UTILS.blind_col_numtokey(MP.LOBBY.blind_col)].pos)
	blind_anim:define_draw_steps({
		{shader = 'dissolve', shadow_height = 0.05},
		{shader = 'dissolve'}
	})
	local ret = {
		n = G.UIT.ROOT,
		config = {
			r = 0.1,
			minw = 5,
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			--[[{
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
			},]]
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm",
					on_demand_tooltip = {
						text = {
							localize('k_the_order_integration_desc'), 
							localize("k_the_order_credit")
						}
					},
				},
				nodes = {
					create_toggle({
						id = "the_order_integration_toggle",
						label = localize("b_the_order_integration"),
						ref_table = SMODS.Mods["Multiplayer"].config.integrations,
						ref_value = "TheOrder",
					}),
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
							text = localize("k_the_order_credit"),
							shadow = true,
							scale = 0.375,
							colour = G.C.UI.TEXT_INACTIVE,
						},
					},
					{
						n = G.UIT.B,
						config = {
							w = 0.1,
							h = 0.1,
						},
					},
					{
						n = G.UIT.T,
						config = {
							text = localize("k_requires_restart"),
							shadow = true,
							scale = 0.375,
							colour = G.C.UI.TEXT_INACTIVE,
						},
					},
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
							text = localize("k_enter_to_save"),
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0.1,
					align = "cm",
					id = "blind_col_changer",
				},
				nodes = {
					{n=G.UIT.C, config={align = "cm"}, nodes={
						{n=G.UIT.O, config={id = "blind_col_changer_sprite", object = blind_anim}},
					}},
					{n=G.UIT.C, config={align = "cm"}, nodes={
						create_option_cycle({
							id = "blind_col_changer_option",
							label = localize{type ='name_text', key = MP.UTILS.blind_col_numtokey(MP.LOBBY.blind_col), set = 'Blind'},
							scale = 0.8, 
							options = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25}, -- blind_cols are being saved as numbers because of this option cycle. if this is changed then we should probably change to keys
							opt_callback = 'change_blind_col', 
							current_option = MP.LOBBY.blind_col
						}),
					}},
				},
			},
		},
	}
	return ret
end

function G.FUNCS.bmp_discord(e)
	love.system.openURL("https://discord.gg/gEemz4ptuF")
end

function G.FUNCS.bmp_github(e)
	love.system.openURL("https://github.com/Balatro-Multiplayer/BalatroMultiplayer/")
end

function G.FUNCS.change_blind_col(args)	-- all we're doing is just saving + redefining the ui elements here
	MP.UTILS.save_blind_col(args.to_val)
	MP.LOBBY.blind_col = args.to_val
	local sprite = G.OVERLAY_MENU:get_UIE_by_ID('blind_col_changer_sprite')
	sprite.config.object:remove()
	sprite.config.object = AnimatedSprite(0,0, 1.4, 1.4, G.ANIMATION_ATLAS['mp_player_blind_col'], G.P_BLINDS[MP.UTILS.blind_col_numtokey(MP.LOBBY.blind_col)].pos)
	sprite.config.object:define_draw_steps({
		{shader = 'dissolve', shadow_height = 0.05},
		{shader = 'dissolve'}
	})
	sprite.UIBox:recalculate()
	local option = G.OVERLAY_MENU:get_UIE_by_ID('blind_col_changer_option')
	option.children[1].children[1].config.text = localize{type ='name_text', key = MP.UTILS.blind_col_numtokey(MP.LOBBY.blind_col), set = 'Blind'}
	option.UIBox:recalculate()
end