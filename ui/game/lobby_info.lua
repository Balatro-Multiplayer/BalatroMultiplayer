local Disableable_Toggle = MP.UI.Disableable_Toggle

function G.FUNCS.lobby_info(e)
	G.SETTINGS.paused = true
	G.FUNCS.overlay_menu({
		definition = MP.UI.lobby_info(),
	})
end

function MP.UI.lobby_info()
	return create_UIBox_generic_options({
		contents = {
			create_tabs({
				tabs = {
					{
						label = localize("b_players"),
						chosen = true,
						tab_definition_function = MP.UI.create_UIBox_players,
					},
					{
						label = localize("b_lobby_info"),
						chosen = false,
						tab_definition_function = MP.UI.create_UIBox_settings, -- saying settings because _options is used in lobby
					},
				},
				tab_h = 8,
				snap_to_nav = true,
			}),
		},
	})
end

function MP.UI.create_UIBox_settings() -- optimize this please
	local ruleset = string.sub(MP.LOBBY.config.ruleset, 12, -1)
	local gamemode = string.sub(MP.LOBBY.config.gamemode, 13, -1)
	local seed = MP.LOBBY.config.custom_seed == "random" and localize("k_random") or MP.LOBBY.config.custom_seed
	return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 6,
			r = 0.1,
			minw = 10,
			align = "tm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			MP.UI.UTILS.create_row({ align = "cm", padding = 0.05 }, {
				MP.UI.UTILS.create_text_node((localize("k_" .. ruleset) .. " " .. localize("k_" .. gamemode)), {
					colour = G.C.UI.TEXT_LIGHT,
					scale = 0.6,
				}),
			}),
			MP.UI.UTILS.create_row({ align = "cm", padding = 0.05 }, {
				MP.UI.UTILS.create_text_node((localize("k_current_seed") .. seed), {
					colour = G.C.UI.TEXT_LIGHT,
					scale = 0.6,
				}),
			}),
			MP.UI.UTILS.create_row({ padding = 0, align = "cr" }, {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_cb_money"),
					ref_table = MP.LOBBY.config,
					ref_value = "gold_on_life_loss",
				}),
			}),
			MP.UI.UTILS.create_row({ padding = 0, align = "cr" }, {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_no_gold_on_loss"),
					ref_table = MP.LOBBY.config,
					ref_value = "no_gold_on_round_loss",
				}),
			}),
			MP.UI.UTILS.create_row({ padding = 0, align = "cr" }, {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_death_on_loss"),
					ref_table = MP.LOBBY.config,
					ref_value = "death_on_round_loss",
				}),
			}),
			MP.UI.UTILS.create_row({ padding = 0, align = "cr" }, {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_diff_seeds"),
					ref_table = MP.LOBBY.config,
					ref_value = "different_seeds",
				}),
			}),
			MP.UI.UTILS.create_row({ padding = 0, align = "cr" }, {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_player_diff_deck"),
					ref_table = MP.LOBBY.config,
					ref_value = "different_decks",
				}),
			}),
			MP.UI.UTILS.create_row({ padding = 0, align = "cr" }, {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_multiplayer_jokers"),
					ref_table = MP.LOBBY.config,
					ref_value = "multiplayer_jokers",
				}),
			}),
			MP.UI.UTILS.create_row({ padding = 0, align = "cr" }, {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_normal_bosses"),
					ref_table = MP.LOBBY.config,
					ref_value = "normal_bosses",
				}),
			}),
		},
	}
end

function MP.UI.create_UIBox_players()
	local players = {
		MP.UI.create_UIBox_player_row("host"),
		MP.UI.create_UIBox_player_row("guest"),
	}

	local t = {
		n = G.UIT.ROOT,
		config = { align = "cm", minw = 3, padding = 0.1, r = 0.1, colour = G.C.CLEAR },
		nodes = {
			MP.UI.UTILS.create_row({ align = "cm", padding = 0.04 }, players),
		},
	}

	return t
end

function MP.UI.create_UIBox_mods_list(type)
	return {
		n = G.UIT.R,
		config = { align = "cm", colour = G.C.WHITE, r = 0.1 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm" },
				nodes = MP.UI.modlist_to_view(
					type == "host" and MP.LOBBY.host.config.Mods or MP.LOBBY.guest.config.Mods,
					G.C.UI.TEXT_DARK
				),
			},
		},
	}
end

function MP.UI.create_UIBox_player_row(type)
	local player_name = type == "host" and MP.LOBBY.host.username or MP.LOBBY.guest.username
	local lives = MP.GAME.enemy.lives
	local highest_score = MP.GAME.enemy.highest_score
	if (type == "host" and MP.LOBBY.is_host) or (type == "guest" and not MP.LOBBY.is_host) then
		lives = MP.GAME.lives
		highest_score = MP.GAME.highest_score
	end
	return {
		n = G.UIT.R,
		config = {
			align = "cm",
			padding = 0.05,
			r = 0.1,
			colour = darken(G.C.JOKER_GREY, 0.1),
			emboss = 0.05,
			hover = true,
			force_focus = true,
			on_demand_tooltip = {
				text = { localize("k_mods_list") },
				filler = { func = MP.UI.create_UIBox_mods_list, args = type },
			},
		},
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cl", padding = 0, minw = 5 },
				nodes = {
					{
						n = G.UIT.C,
						config = {
							align = "cm",
							padding = 0.02,
							r = 0.1,
							colour = G.C.RED,
							minw = 2,
							outline = 0.8,
							outline_colour = G.C.RED,
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = tostring(lives) .. " " .. localize("k_lives"),
									scale = 0.4,
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					},
					{
						n = G.UIT.C,
						config = { align = "cm", minw = 4.5, maxw = 4.5 },
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = " " .. player_name,
									scale = 0.45,
									colour = G.C.UI.TEXT_LIGHT,
									shadow = true,
								},
							},
						},
					},
				},
			},
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.05, colour = G.C.BLACK, r = 0.1 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cr", padding = 0.01, r = 0.1, colour = G.C.CHIPS, minw = 1.1 },
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "???", -- Will be hands in the future
									scale = 0.45,
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
							{ n = G.UIT.B, config = { w = 0.08, h = 0.01 } },
						},
					},
					{
						n = G.UIT.C,
						config = { align = "cl", padding = 0.01, r = 0.1, colour = G.C.MULT, minw = 1.1 },
						nodes = {
							{ n = G.UIT.B, config = { w = 0.08, h = 0.01 } },
							{
								n = G.UIT.T,
								config = {
									text = "???", -- Will be discards in the future
									scale = 0.45,
									colour = G.C.UI.TEXT_LIGHT,
								},
							},
						},
					},
				},
			},
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.05, colour = G.C.L_BLACK, r = 0.1, minw = 1.5 },
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = MP.INSANE_INT.to_string(highest_score),
							scale = 0.45,
							colour = G.C.FILTER,
							shadow = true,
						},
					},
				},
			},
		},
	}
end
