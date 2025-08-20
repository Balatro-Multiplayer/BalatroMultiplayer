local Disableable_Toggle = MP.UI.Disableable_Toggle

-- TODO repetition but w/e...
function send_lobby_options(value)
	MP.ACTIONS.lobby_options()
end

function create_lobby_option_cycle(id, label_key, scale, options, current_option, callback)
	return MP.UI.Disableable_Option_Cycle({
		id = id,
		enabled_ref_table = MP.LOBBY,
		enabled_ref_value = "is_host",
		label = localize(label_key),
		scale = scale,
		options = options,
		current_option = current_option,
		opt_callback = callback,
	})
end

-- Component for lobby options tab containing toggles and custom seed section
function create_lobby_option_toggle(id, label_key, ref_value, callback)
	return {
		n = G.UIT.R,
		config = {
			padding = 0,
			align = "cr",
		},
		nodes = {
			Disableable_Toggle({
				id = id,
				enabled_ref_table = MP.LOBBY,
				enabled_ref_value = "is_host",
				label = localize(label_key),
				ref_table = MP.LOBBY.config,
				ref_value = ref_value,
				callback = callback or send_lobby_options,
			}),
		},
	}
end

G.FUNCS.change_starting_lives = function(args)
	MP.LOBBY.config.starting_lives = args.to_val
	send_lobby_options()
end

-- This needs to have a parameter because its a callback for inputs
local function send_lobby_options(value)
	MP.ACTIONS.lobby_options()
end

-- Creates the lobby options tab UI containing toggles for various multiplayer settings
-- Returns a UI table with lobby configuration options like gold on life loss, different seeds, etc.
function MP.UI.create_lobby_options_tab()
	return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 4,
			r = 0.1,
			minw = 10,
			align = "tm",
			padding = 0.2,
			colour = G.C.BLACK,
		},
		nodes = {
			create_lobby_option_cycle(
				"starting_lives_option",
				"b_opts_lives",
				0.85,
				{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 },
				MP.LOBBY.config.starting_lives,
				"change_starting_lives"
			),
			create_lobby_option_toggle("different_decks_toggle", "b_opts_player_diff_deck", "different_decks"),
			create_lobby_option_toggle("multiplayer_jokers_toggle", "b_opts_multiplayer_jokers", "multiplayer_jokers"),
			create_lobby_option_toggle("normal_bosses_toggle", "b_opts_normal_bosses", "normal_bosses"),
		},
	}
end
