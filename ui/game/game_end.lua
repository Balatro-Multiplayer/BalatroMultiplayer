-- Leave to the main menu from the end screen (mirrors Speed's spdrn_leave_from_game).
-- The match is already over, so no confirm; lobby:leave() fires the DISCONNECTED handler
-- which tears down the MP-side lobby state.
function G.FUNCS.mp_pvp_leave_from_game()
	G.FUNCS.exit_overlay_menu()
	G.SETTINGS.paused = false
	local lobby = MPAPI.get_current_lobby()
	if lobby then
		lobby:leave()
	end
	G.FUNCS.go_to_menu()
end

function MP.UI.create_UIBox_round_scores_row_nemesis()
    local label = localize({ type = "name_text", set = "Blind", key = "bl_mp_nemesis" })
    local score_tab = {}
    local label_w, score_w, h = 2.9, 1, 0.5

    local blind_name_string
    if MP.GHOST.is_active() then
        blind_name_string = MP.GHOST.get_blind_name_ui() or "ERROR"
    else
        blind_name_string = (MP.LOBBY.is_host and MP.LOBBY.guest or MP.LOBBY.host or {})["username"] or "ERROR"
    end

    local nemesis_blind_col = MP.UTILS.get_nemesis_key()
    local blind_choice = {}
    blind_choice.animation = AnimatedSprite(0,0, 0.5, 0.5, G.ANIMATION_ATLAS["mp_player_blind_col"], G.P_BLINDS[nemesis_blind_col].pos)
    blind_choice.animation:define_draw_steps({
        {shader = 'dissolve', shadow_height = 0.05},
        {shader = 'dissolve'}
    })

    score_tab = {
        {n=G.UIT.C, config={align = "cm", minh = 0.7, padding = 0.1}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = blind_name_string, colours = {G.C.WHITE}, shadow = true, bump = true,maxw = 2.9, scale = 0.45})}}
        }},
        {n=G.UIT.C, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = blind_choice.animation}}
        }},
    }

    local label_scale = 0.5

    return {n=G.UIT.R, config={align = "cm", padding = 0.05, r = 0.1, colour = darken(G.C.JOKER_GREY, 0.1), emboss = 0.05, id = "mp_score_nemesis"}, nodes={
        {n=G.UIT.R, config={align = "cm", padding = 0.02, minw = label_w, maxw = label_w}, nodes={
            {n=G.UIT.T, config={text = label, scale = label_scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
        }},
        {n=G.UIT.R, config={align = "cr"}, nodes={
            {n=G.UIT.C, config={align = "cm", minh = h, r = 0.1, minw = label_w + 0.9, colour = G.C.BLACK, emboss = 0.05}, nodes={
                {n=G.UIT.C, config={align = "cm", padding = 0.05, r = 0.1, minw = score_w}, nodes=score_tab},
            }}
        }},
    }}
end

-- The mod-specific body of the PvP end screen, rendered inside the shared
-- MPAPI.end_screen shell: opponent jokers + toggle/view-deck buttons, the stat block +
-- Ko-fi, and the nemesis row + seed + lobby buttons.
function MP.UI.end_game_body(has_won)
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.15 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.08 },
						nodes = {
							{ n = G.UIT.T, config = { ref_table = MP, ref_value = "end_game_jokers_text", scale = 0.8, maxw = 5, shadow = true } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.08 },
						nodes = {
							{ n = G.UIT.O, config = { object = MP.end_game_jokers } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.08 },
						nodes = {
							{ n = G.UIT.C, config = { maxw = has_won and 0.8 or 1, minw = has_won and 0.8 or 1, minh = 0.7, colour = G.C.CLEAR, no_fill = false } },
							{
								n = G.UIT.C,
								config = { button = "toggle_players_jokers", align = "cm", padding = 0.12, colour = G.C.BLUE, emboss = 0.05, minh = 0.7, minw = 2, maxw = 2, r = 0.1, shadow = true, hover = true },
								nodes = {
									{ n = G.UIT.T, config = { text = localize("b_toggle_jokers"), colour = G.C.UI.TEXT_LIGHT, scale = 0.65, col = true } },
								},
							},
							{
								n = G.UIT.C,
								config = { id = "view_nemesis_deck_button", button = "view_nemesis_deck", align = "cm", padding = 0.12, colour = G.C.BLUE, emboss = 0.05, minh = 0.7, minw = 2, maxw = 2, r = 0.1, shadow = true, hover = true, focus_args = has_won and { nav = "wide" } or nil },
								nodes = {
									{ n = G.UIT.T, config = { text = localize("b_view_nemesis_deck"), colour = G.C.UI.TEXT_LIGHT, scale = 0.65, col = true } },
								},
							},
							{ n = G.UIT.C, config = { maxw = has_won and 0.8 or 1, minw = has_won and 0.8 or 1, minh = 0.7, colour = G.C.CLEAR, no_fill = false } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{
								n = G.UIT.C,
								config = { padding = 0.08 },
								nodes = {
									create_UIBox_round_scores_row("hand"),
									create_UIBox_round_scores_row("poker_hand"),
									{
										n = G.UIT.R,
										config = {},
										nodes = {
											{
												n = G.UIT.C,
												nodes = {
													create_UIBox_round_scores_row('cards_purchased', G.C.MONEY),
													{ n = G.UIT.R, config = { minh = 0.08 } },
													create_UIBox_round_scores_row('times_rerolled', G.C.GREEN),
												},
											},
											{ n = G.UIT.C, config = { minw = 0.08 } },
											{
												n = G.UIT.C,
												nodes = {
													create_UIBox_round_scores_row('furthest_ante', G.C.FILTER),
													{ n = G.UIT.R, config = { minh = 0.08 } },
													create_UIBox_round_scores_row('furthest_round', G.C.FILTER),
												},
											},
										},
									},
									{ n = G.UIT.R, config = { minh = 0.01 } },
									{
										n = G.UIT.R,
										config = { align = "cm", minw = 2 },
										nodes = {
											{ n = G.UIT.T, config = { text = localize("ml_mp_kofi_message")[1], scale = 0.35, colour = G.C.UI.TEXT_LIGHT, col = true } },
										},
									},
									{
										n = G.UIT.R,
										config = { align = "cm", minw = 2 },
										nodes = {
											{ n = G.UIT.T, config = { text = localize("ml_mp_kofi_message")[2], scale = 0.35, colour = G.C.UI.TEXT_LIGHT, col = true } },
										},
									},
									{
										n = G.UIT.R,
										config = { align = "cm", minw = 2 },
										nodes = {
											{ n = G.UIT.T, config = { text = localize("ml_mp_kofi_message")[3] .. (localize("ml_mp_kofi_message")[4] and (" " .. localize("ml_mp_kofi_message")[4]) or ""), scale = 0.35, colour = G.C.UI.TEXT_LIGHT, col = true } },
										},
									},
									{ n = G.UIT.R, config = { minh = 0.08 } },
									{
										n = G.UIT.R,
										config = { id = "ko-fi_button", align = "cm", padding = 0.1, r = 0.1, hover = true, colour = HEX("72A5F2"), button = "open_kofi", shadow = true },
										nodes = {
											{
												n = G.UIT.R,
												config = { align = "cm", padding = 0, no_fill = true, maxw = 3 },
												nodes = {
													{ n = G.UIT.T, config = { text = localize("b_mp_kofi_button"), scale = 0.35, colour = G.C.UI.TEXT_LIGHT } },
												},
											},
										},
									},
								},
							},
							{
								n = G.UIT.C,
								config = { align = "tr", padding = 0.08 },
								nodes = {
									MP.UI.create_UIBox_round_scores_row_nemesis(),
									create_UIBox_round_scores_row("seed", G.C.WHITE),
									UIBox_button({ id = "copy_seed_button", button = "copy_seed", label = { localize("b_copy") }, colour = G.C.BLUE, scale = 0.3, minw = 2.5, maxw = 2.5, minh = 0.4 }),
									{ n = G.UIT.R, config = { align = "cm", minh = 0.45, minw = 0.1 }, nodes = {} },
									UIBox_button({ id = "from_game_won", button = "continue_in_singleplayer", label = { localize("b_continue_singleplayer") }, minw = 4, maxw = 4, minh = 0.8, focus_args = { nav = "wide", snap_to = true } }),
									UIBox_button({ button = "mp_pvp_leave_from_game", label = { localize("b_leave_lobby") }, minw = 4, maxw = 4, minh = 0.8, focus_args = { nav = "wide" } }),
								},
							},
						},
					},
				},
			},
		},
	}
end

-- Builds the PvP win / game-over screen inside the shared MPAPI.end_screen shell. The
-- async opponent-jokers / nemesis-deck fetches are kicked off here (the body renders
-- them once they arrive). PvP hooks this via the create_UIBox_win/game_over overrides
-- below rather than calling the overlay directly, so it keeps its own paused handling.
function MP.UI.create_UIBox_mp_game_end(has_won)
	MP.end_game_jokers = CardArea(
		0,
		0,
		5 * G.CARD_W,
		G.CARD_H,
		{ card_limit = G.GAME.starting_params.joker_slots, type = "joker", highlight_limit = 1, fixed_limit = true }
	)
	if not MP.end_game_jokers_received then
		MP.ACTIONS.get_end_game_jokers()
	else
		G.FUNCS.load_end_game_jokers()
	end
	MP.end_game_jokers_text = localize("k_enemy_jokers")

	MP.ACTIONS.request_nemesis_stats()

	MP.nemesis_deck = CardArea(-100, -100, G.CARD_W, G.CARD_H, { type = "deck" })
	MP.nemesis_cards = {}
	if not MP.nemesis_deck_received then
		MP.ACTIONS.get_nemesis_deck()
	else
		G.FUNCS.load_nemesis_deck()
	end

	G.SETTINGS.paused = false

	return MPAPI.end_screen_uibox({
		won = has_won,
		id = has_won and "you_win_UI" or nil,
		body = MP.UI.end_game_body,
	})
end

function G.UIDEF.view_nemesis_deck()
	local playing_cards_ref = G.playing_cards
	G.playing_cards = MP.nemesis_cards
	local t = G.UIDEF.view_deck()
	G.playing_cards = playing_cards_ref
	return t
end

function G.UIDEF.create_UIBox_view_nemesis_deck()
	return create_UIBox_generic_options({
		back_func = "overlay_endgame_menu",
		contents = {
			create_tabs({
				tabs = {
					{
						label = localize("k_nemesis_deck"),
						chosen = true,
						tab_definition_function = G.UIDEF.view_nemesis_deck,
					},
					{
						label = localize("k_your_deck"),
						tab_definition_function = G.UIDEF.view_deck,
					},
				},
				tab_h = 8,
				snap_to_nav = true,
			}),
		},
	})
end

-- Contains function overrides (monkey-patches) for UI-related functionality
-- Overrides UI creation functions like create_UIBox_game_over, create_UIBox_win, etc.

local create_UIBox_game_over_ref = create_UIBox_game_over
function create_UIBox_game_over()
	if not MP.LOBBY.code then return create_UIBox_game_over_ref() end
	return MP.UI.create_UIBox_mp_game_end(false)
end

local create_UIBox_win_ref = create_UIBox_win
function create_UIBox_win()
	if not MP.LOBBY.code then return create_UIBox_win_ref() end
	return MP.UI.create_UIBox_mp_game_end(true)
end

local exit_overlay_menu_ref = G.FUNCS.exit_overlay_menu
---@diagnostic disable-next-line: duplicate-set-field
function G.FUNCS:exit_overlay_menu()
	-- Saves username if user presses ESC instead of Enter
	if G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("username_input_box") ~= nil then
		MP.UTILS.save_username(MP.LOBBY.username)
	end

	exit_overlay_menu_ref(self)
end

local mods_button_ref = G.FUNCS.mods_button
function G.FUNCS.mods_button(arg_736_0)
	if G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("username_input_box") ~= nil then
		MP.UTILS.save_username(MP.LOBBY.username)
	end

	mods_button_ref(arg_736_0)
end

function G.UIDEF.multiplayer_deck()
	return G.UIDEF.challenge_description(
		get_challenge_int_from_id(MP.current_ruleset().challenge_deck),
		nil,
		false
	)
end
