-- Read-only status toggles: delegate to the API's disableable widget (these calls pass
-- no enabled_ref_value, so they render non-interactive). `.node` unwraps MPAPI's reactive
-- el wrapper into an embeddable UI node.
local function Disableable_Toggle(args)
	return MPAPI.disableable_toggle(args).node
end

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
	-- The player's mod list comes from the legacy mod-hash system (config.Mods), which
	-- the API-based lobby flow does not populate, so config can be nil. Guard it (an
	-- absent list renders as an empty box) instead of indexing a nil config.
	local player = (type == "host") and MP.LOBBY.host or MP.LOBBY.guest
	local mods = player and player.config and player.config.Mods or nil
	return {
		n = G.UIT.R,
		config = { align = "cm", colour = G.C.WHITE, r = 0.1 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm" },
				nodes = MP.UI.modlist_to_view(mods, G.C.UI.TEXT_DARK),
			},
		},
	}
end

-- Builds the mods-list view rows for a player (relocated from the removed legacy
-- ui/lobby/lobby.lua; sole caller is create_UIBox_mods_list above). Buckets special
-- mods (Lovely/Steamodded/Multiplayer/Preview) first, then the rest alphabetically,
-- colouring banned mods red.
function MP.UI.modlist_to_view(mods, text_colour)
	local t = {}

	if not mods then
		return t
	end

	local special_mods_targets = {
		"Steamodded",
		"Lovely",
		"Multiplayer",
		"Preview",
	}
	local special_mods_found = {}
	local other_mods = {}
	for mod_name, mod_version in pairs(mods) do
		local found = false
		for _, id in ipairs(special_mods_targets) do
			if not special_mods_found[id] and MP.UTILS.string_starts(mod_name, id) then
				special_mods_found[id] = { name = mod_name, version = mod_version }
				found = true
				break
			end
		end
		if not found then
			table.insert(other_mods, { name = mod_name, version = mod_version })
		end
	end

	table.sort(other_mods, function(a, b)
		return a.name < b.name
	end)

	local function add_mod_row(mod)
		local mod_name, mod_version = MP.UTILS.resolve_mod_name_and_version(mod.name, mod.version)
		local color = MP.BANNED_MODS[mod.name] and G.C.RED or text_colour
		table.insert(t, {
			n = G.UIT.R,
			config = {
				padding = 0.025,
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = mod_name,
						scale = 0.32,
						colour = color,
					},
				},
				mod_version and {
					n = G.UIT.T,
					config = {
						text = " " .. mod_version,
						scale = 0.32,
						colour = adjust_alpha(color, 0.6),
					},
				} or nil,
			},
		})
	end
	local function add_separator()
		table.insert(t, {
			n = G.UIT.R,
			config = {
				minh = 0.025,
				colour = adjust_alpha(text_colour, 0.25),
			},
		})
	end

	for _, mod in pairs({ special_mods_found.Lovely, special_mods_found.Steamodded }) do
		add_mod_row(mod)
	end
	add_separator()
	for _, mod in pairs({ special_mods_found.Multiplayer, special_mods_found.Preview }) do
		add_mod_row(mod)
	end
	add_separator()
	for _, mod in ipairs(other_mods) do
		add_mod_row(mod)
	end
	return t
end

function MP.UI.create_UIBox_player_row(type)
	local player_name = type == "host" and MP.LOBBY.host.username or MP.LOBBY.guest.username
	local lives = MP.GAME.enemy.lives
	local highest_score = MP.GAME.enemy.highest_score
	local skips = MP.GAME.enemy.skips or 0
	if (type == "host" and MP.LOBBY.is_host) or (type == "guest" and not MP.LOBBY.is_host) then
		lives = MP.GAME.lives
		highest_score = MP.GAME.highest_score
		skips = G.GAME.skips or 0
	end
	return {
		n = G.UIT.R,
		config = {
			align = "cm",
			padding = 0.1,
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
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.C,
						config = {
							align = "cm",
							padding = 0.05,
							r = 0.1,
							colour = G.C.MULT,
							minw = 2,
							maxw = 2,
							outline = 0.5,
							outline_colour = G.C.MULT,
							emboss = 0.07,
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = tostring(lives) .. " " .. localize("k_lives"),
									scale = 0.375,
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
				config = { align = "cl", padding = 0, minw = 4 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", minw = 4.5, maxw = 4.5 },
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "" .. player_name,
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
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.C,
						config = {
							align = "cm",
							padding = 0.05,
							r = 0.1,
							colour = G.C.PURPLE,
							minw = 1.75,
							maxw = 1.75,
							outline = 0.5,
							outline_colour = G.C.PURPLE,
							emboss = 0.07,
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = tostring(skips) .. " " .. localize("k_skips"),
									scale = 0.375,
									colour = G.C.UI.TEXT_LIGHT,
                                    shadow = true,
								},
							},
						},
					},
                    -- Let's keep it for future, just in case
					-- {
					-- 	n = G.UIT.C,
					-- 	config = { align = "cr", padding = 0.01, r = 0.1, colour = G.C.CHIPS, minw = 1.1 },
					-- 	nodes = {
					-- 		{
					-- 			n = G.UIT.T,
					-- 			config = {
					-- 				text = "???", -- Will be hands in the future
					-- 				scale = 0.45,
					-- 				colour = G.C.UI.TEXT_LIGHT,
					-- 			},
					-- 		},
					-- 		{ n = G.UIT.B, config = { w = 0.08, h = 0.01 } },
					-- 	},
					-- },
					-- {
					-- 	n = G.UIT.C,
					-- 	config = { align = "cl", padding = 0.01, r = 0.1, colour = G.C.MULT, minw = 1.1 },
					-- 	nodes = {
					-- 		{ n = G.UIT.B, config = { w = 0.08, h = 0.01 } },
					-- 		{
					-- 			n = G.UIT.T,
					-- 			config = {
					-- 				text = "???", -- Will be discards in the future
					-- 				scale = 0.45,
					-- 				colour = G.C.UI.TEXT_LIGHT,
					-- 			},
					-- 		},
					-- 	},
					-- },
				},
			},
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.05, colour = G.C.L_BLACK, r = 0.1, minw = 3, maxw = 3 },
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = MP.INSANE_INT.to_string(highest_score),
							scale = 0.425,
							colour = G.C.FILTER,
							shadow = true,
						},
					},
				},
			},
		},
	}
end
