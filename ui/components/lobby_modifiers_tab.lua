-- Component for gamemode modifiers tab containing option cycles
G.FUNCS.change_starting_pvp_round = function(args)
	MP.LOBBY.config.pvp_start_round = args.to_val
	send_lobby_options()
end

G.FUNCS.change_timer_base_seconds = function(args)
	MP.LOBBY.config.timer_base_seconds = tonumber(args.to_val:sub(1, -2))
	send_lobby_options()
end

G.FUNCS.change_timer_increment_seconds = function(args)
	MP.LOBBY.config.timer_increment_seconds = tonumber(args.to_val:sub(1, -2))
	send_lobby_options()
end

G.FUNCS.change_showdown_starting_antes = function(args)
	MP.LOBBY.config.showdown_starting_antes = args.to_val
	send_lobby_options()
end

G.FUNCS.change_pvp_countdown_seconds = function(args)
	MP.LOBBY.config.pvp_countdown_seconds = args.to_val
	send_lobby_options()
end

function MP.UI.create_gamemode_modifiers_tab()
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
			{
				n = G.UIT.R,
				config = { padding = 0, align = "cm" },
				nodes = {
					create_lobby_option_cycle(
						"pvp_timer_seconds_option",
						"k_opts_pvp_timer",
						0.85,
						{ "30s", "60s", "90s", "120s", "150s", "180s", "210s", "240s" },
						MP.LOBBY.config.timer_base_seconds / 30,
						"change_timer_base_seconds"
					),
					create_lobby_option_cycle(
						"pvp_timer_increment_seconds_option",
						"k_opts_pvp_timer_increment",
						0.85,
						{ "0s", "30s", "60s", "90s", "120s", "150s", "180s" },
						MP.UTILS.get_array_index_by_value(
							{ 0, 30, 60, 90, 120, 150, 180 },
							MP.LOBBY.config.timer_increment_seconds
						),
						"change_timer_increment_seconds"
					),
					create_lobby_option_cycle(
						"pvp_round_start_option",
						"k_opts_pvp_start_round",
						0.85,
						{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 },
						MP.LOBBY.config.pvp_start_round,
						"change_starting_pvp_round"
					),
					create_lobby_option_cycle(
						"showdown_starting_antes_option",
						"k_opts_showdown_starting_antes",
						0.85,
						{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 },
						MP.LOBBY.config.showdown_starting_antes,
						"change_showdown_starting_antes"
					),
					create_lobby_option_cycle(
						"pvp_countdown_seconds_option",
						"k_opts_pvp_countdown_seconds",
						0.85,
						{ 0, 3, 5, 10 },
						MP.UTILS.get_array_index_by_value({ 0, 3, 5, 10 }, MP.LOBBY.config.pvp_countdown_seconds),
						"change_pvp_countdown_seconds"
					),
				},
			},
		},
	}
end
