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
			{n=G.UIT.R, config={align = "tm", padding = 0.05}, nodes={
				{n=G.UIT.T, config={text = (localize("k_" .. ruleset) .. " " .. localize("k_" .. gamemode)), colour = G.C.UI.TEXT_LIGHT, scale = 0.6}}}},
			{n=G.UIT.R, config={align = "tm", padding = 0.05}, nodes={
				{n=G.UIT.T, config={text = (localize("k_current_seed") .. seed), colour = G.C.UI.TEXT_LIGHT, scale = 0.6}}}},
			{n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
					},
				nodes = {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_cb_money"),
					ref_table = MP.LOBBY.config,
					ref_value = "gold_on_life_loss",})}},
			{n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
					},
				nodes = {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_no_gold_on_loss"),
					ref_table = MP.LOBBY.config,
					ref_value = "no_gold_on_round_loss",})}},
			{n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
					},
				nodes = {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_death_on_loss"),
					ref_table = MP.LOBBY.config,
					ref_value = "death_on_round_loss",})}},
			{n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
					},
				nodes = {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_diff_seeds"),
					ref_table = MP.LOBBY.config,
					ref_value = "different_seeds",})}},
			{n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
					},
				nodes = {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_player_diff_deck"),
					ref_table = MP.LOBBY.config,
					ref_value = "different_decks",})}},
			{n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
					},
				nodes = {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_multiplayer_jokers"),
					ref_table = MP.LOBBY.config,
					ref_value = "multiplayer_jokers",})}},
			{n = G.UIT.R,
				config = {
					padding = 0,
					align = "cr",
					},
				nodes = {
				Disableable_Toggle({
					enabled_ref_table = MP.LOBBY,
					label = localize("b_opts_normal_bosses"),
					ref_table = MP.LOBBY.config,
					ref_value = "normal_bosses",})}},
		}
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
			{ n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = players },
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
				nodes = MP.UI.hash_str_to_view(
					type == "host" and MP.LOBBY.host.hash_str or MP.LOBBY.guest.hash_str,
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

local ease_round_ref = ease_round
function ease_round(mod)
	if MP.LOBBY.code and (not MP.LOBBY.config.disable_live_and_timer_hud) and MP.LOBBY.config.timer then
		return
	end
	ease_round_ref(mod)
end

function G.FUNCS.mp_timer_button(e)
	if MP.LOBBY.config.timer then
		if MP.GAME.ready_blind then
			if not MP.GAME.timer_started then
				MP.ACTIONS.start_ante_timer()
			else
				MP.ACTIONS.pause_ante_timer()
			end
		end
	end
end

function MP.UI.timer_hud()
	if MP.LOBBY.config.timer then
		return {
			n = G.UIT.C,
			config = {
				align = "cm",
				padding = 0.05,
				minw = 1.45,
				minh = 1,
				colour = G.C.DYN_UI.BOSS_MAIN,
				emboss = 0.05,
				r = 0.1,
			},
			nodes = {
				{
					n = G.UIT.R,
					config = { align = "cm", maxw = 1.35 },
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_timer"),
								minh = 0.33,
								scale = 0.34,
								colour = G.C.UI.TEXT_LIGHT,
								shadow = true,
							},
						},
					},
				},
				{
					n = G.UIT.R,
					config = {
						align = "cm",
						r = 0.1,
						minw = 1.2,
						colour = G.C.DYN_UI.BOSS_DARK,
						id = "row_round_text",
						func = "set_timer_box",
						button = "mp_timer_button",
					},
					nodes = {
						{
							n = G.UIT.O,
							config = {
								object = DynaText({
									string = { { ref_table = MP.GAME, ref_value = "timer" } },
									colours = { G.C.UI.TEXT_DARK },
									shadow = true,
									scale = 0.8,
								}),
								id = "timer_UI_count",
							},
						},
					},
				},
			},
		}
	end
end

function MP.UI.start_pvp_countdown(callback)
    local seconds = countdown_seconds
	local tick_delay = 2
    if MP.LOBBY and MP.LOBBY.config and MP.LOBBY.config.pvp_countdown_seconds then
        seconds = MP.LOBBY.config.pvp_countdown_seconds
    end
    MP.GAME.pvp_countdown = seconds

    local function show_next()
        if MP.GAME.pvp_countdown <= 0 then
            if callback then callback() end
            return true
        end

        attention_text({
            text = tostring(MP.GAME.pvp_countdown),
            scale = 5,
            hold = 0.9,
            align = "cm",
            major = G.play,
			backdrop_colour = G.C.MULT,
        })

		play_sound("tarot2", 1, 0.4)

        MP.GAME.pvp_countdown = MP.GAME.pvp_countdown - 1

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = tick_delay,
            blockable = false,
            func = show_next,
        }))
        return true
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0,
        blockable = false,
        func = show_next,
    }))
end

function G.FUNCS.set_timer_box(e)
	if MP.LOBBY.config.timer then
		if MP.GAME.timer_started then
			e.config.colour = G.C.DYN_UI.BOSS_DARK
			e.children[1].config.object.colours = { G.C.IMPORTANT }
			return
		end
		if not MP.GAME.timer_started and MP.GAME.ready_blind then
			e.config.colour = G.C.IMPORTANT
			e.children[1].config.object.colours = { G.C.UI.TEXT_LIGHT }
			return
		end
		e.config.colour = G.C.DYN_UI.BOSS_DARK
		e.children[1].config.object.colours = { G.C.UI.TEXT_DARK }
	end
end

MP.timer_event = Event({
	blockable = false,
	blocking = false,
	pause_force = true,
	no_delete = true,
	trigger = "after",
	delay = 1,
	timer = "UPTIME",
	func = function()
		if not MP.GAME.timer_started then
			return true
		end
		MP.GAME.timer = MP.GAME.timer - 1
		if MP.GAME.timer <= 0 then
			MP.GAME.timer = 0
			if not MP.GAME.ready_blind and not MP.is_pvp_boss() then
				MP.ACTIONS.fail_timer()
			end
			return true
		end
		MP.timer_event.start_timer = false
	end,
})
