-- Contains function overrides (monkey-patches) for G.FUNCS callbacks
-- Overrides button callback functions like can_play, can_open, select_blind, skip_blind, etc.

G.FUNCS.pvp_ready_button = function(e)
	if e.children[1].config.ref_table[e.children[1].config.ref_value] == localize("Select", "blind_states") then
		e.config.button = "mp_toggle_ready"
		e.config.one_press = false
		e.children[1].config.ref_table = MP.GAME
		e.children[1].config.ref_value = "ready_blind_text"
	end
	if e.config.button == "mp_toggle_ready" then e.config.colour = (MP.GAME.ready_blind and G.C.GREEN) or G.C.RED end
end

function G.FUNCS.mp_toggle_ready(e)
	sendTraceMessage("Toggling Ready", "MULTIPLAYER")
	MP.GAME.ready_blind = not MP.GAME.ready_blind
	MP.GAME.ready_blind_text = MP.GAME.ready_blind and localize("b_unready") or localize("b_ready")

	if MP.GAME.ready_blind then
		MP.ACTIONS.set_location("loc_ready")
		MP.ACTIONS.ready_blind(e)
	else
		MP.ACTIONS.set_location("loc_selecting")
		MP.ACTIONS.pause_ante_timer()
		MP.ACTIONS.unready_blind()
	end
end

local can_play_ref = G.FUNCS.can_play
G.FUNCS.can_play = function(e)
	if G.GAME.current_round.hands_left <= 0 then
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
		e.config.button = nil
	else
		can_play_ref(e)
	end
end

local can_open_ref = G.FUNCS.can_open
G.FUNCS.can_open = function(e)
	if MP.GAME.ready_blind then
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
		e.config.button = nil
		return
	end
	can_open_ref(e)
end

local select_blind_ref = G.FUNCS.select_blind
function G.FUNCS.select_blind(e)
	MP.GAME.end_pvp = false
	MP.GAME.prevent_eval = false
	select_blind_ref(e)
	if MP.LOBBY.code then
		MP.GAME.ante_key = tostring(math.random())
		MP.ACTIONS.play_hand(0, G.GAME.round_resets.hands)
		MP.ACTIONS.new_round()
		MP.ACTIONS.set_location("loc_playing-" .. (e.config.ref_table.key or e.config.ref_table.name))
		if MP.UI.hide_enemy_location then MP.UI.hide_enemy_location() end
	end
end

local skip_blind_ref = G.FUNCS.skip_blind
G.FUNCS.skip_blind = function(e)
	skip_blind_ref(e)
	if MP.LOBBY.code then
		if not MP.GAME.timer_started then MP.GAME.timer = MP.GAME.timer + MP.LOBBY.config.timer_increment_seconds end
		MP.ACTIONS.skip(G.GAME.skips)

		--Update the furthest blind
		local temp_furthest_blind = 0
		if G.GAME.round_resets.blind_states.Big == "Skipped" then
			temp_furthest_blind = G.GAME.round_resets.ante * 10 + 2
		elseif G.GAME.round_resets.blind_states.Small == "Skipped" then
			temp_furthest_blind = G.GAME.round_resets.ante * 10 + 1
		end

		MP.GAME.pincher_index = MP.GAME.pincher_index + 1

		MP.GAME.furthest_blind = (temp_furthest_blind > MP.GAME.furthest_blind) and temp_furthest_blind
			or MP.GAME.furthest_blind

		MP.ACTIONS.set_furthest_blind(MP.GAME.furthest_blind)
	end
end

function G.FUNCS.toggle_players_jokers()
	if not G.jokers or not MP.end_game_jokers then return end

	-- Avoid Jokers being removed from activating removal abilities (e.g. Negatives)
	if MP.end_game_jokers.cards then
		for _, card in pairs(MP.end_game_jokers.cards) do
			card.added_to_deck = false
		end
	end

	if MP.end_game_jokers_text == localize("k_enemy_jokers") then
		local your_jokers_save = copy_table(G.jokers:save())
		MP.end_game_jokers:load(your_jokers_save)
		MP.end_game_jokers_text = localize("k_your_jokers")
	else
		if MP.end_game_jokers_received then
			G.FUNCS.load_end_game_jokers()
		else
			if MP.end_game_jokers.cards then remove_all(MP.end_game_jokers.cards) end
			MP.end_game_jokers.cards = {}
		end
		MP.end_game_jokers_text = localize("k_enemy_jokers")
	end
end

function G.FUNCS.view_nemesis_deck()
	G.SETTINGS.paused = true
	if G.deck_preview then
		G.deck_preview:remove()
		G.deck_preview = nil
	end
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.create_UIBox_view_nemesis_deck(),
	})
end

function G.FUNCS.open_kofi(e)
	love.system.openURL("https://ko-fi.com/virtualized")
end

function G.FUNCS:continue_in_singleplayer(e)
	-- Leave multiplayer lobby and update UI
	MP.LOBBY.code = nil
	MP.ACTIONS.leave_lobby()
	MP.UI.update_connection_status()

	-- Allow saving, save the run, and set up for continuation
	G.F_NO_SAVING = false
	G.SETTINGS.current_setup = "Continue"
	G.FUNCS.wipe_on()
	save_run()
	G:delete_run()

	-- Load the saved game and start a new run in singleplayer
	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		no_delete = true,
		func = function()
			local profile = G.SETTINGS.profile
			local save_path = profile .. "/save.jkr"
			G.SAVED_GAME = get_compressed(save_path)
			if G.SAVED_GAME ~= nil then G.SAVED_GAME = STR_UNPACK(G.SAVED_GAME) end
			G:start_run({ savetext = G.SAVED_GAME })
			return true
		end,
	}))
	G.FUNCS.wipe_off()
end

function G.FUNCS.attention_text_realtime(args)
	args = args or {}
	args.text = args.text or "test"
	args.scale = args.scale or 1
	args.colour = copy_table(args.colour or G.C.WHITE)
	args.hold = (args.hold or 0)
	args.pos = args.pos or { x = 0, y = 0 }
	args.align = args.align or "cm"
	args.emboss = args.emboss or nil

	args.fade = 1

	if args.cover then
		args.cover_colour = copy_table(args.cover_colour or G.C.RED)
		args.cover_colour_l = copy_table(lighten(args.cover_colour, 0.2))
		args.cover_colour_d = copy_table(darken(args.cover_colour, 0.2))
	else
		args.cover_colour = copy_table(G.C.CLEAR)
	end

	args.uibox_config = {
		align = args.align or "cm",
		offset = args.offset or { x = 0, y = 0 },
		major = args.cover or args.major or nil,
	}

	G.E_MANAGER:add_event(Event({
		trigger = "after",
		timer = "REAL",
		delay = 0,
		blockable = false,
		blocking = false,
		func = function()
			args.AT = UIBox({
				T = { args.pos.x, args.pos.y, 0, 0 },
				definition = {
					n = G.UIT.ROOT,
					config = {
						align = args.cover_align or "cm",
						minw = (args.cover and args.cover.T.w or 0.001) + (args.cover_padding or 0),
						minh = (args.cover and args.cover.T.h or 0.001) + (args.cover_padding or 0),
						padding = 0.03,
						r = 0.1,
						emboss = args.emboss,
						colour = args.cover_colour,
					},
					nodes = {
						{
							n = G.UIT.O,
							config = {
								draw_layer = 1,
								object = DynaText({
									scale = args.scale,
									string = args.text,
									maxw = args.maxw,
									colours = { args.colour },
									float = true,
									shadow = true,
									silent = not args.noisy,
									args.scale,
									pop_in = 0,
									pop_in_rate = 6,
									rotate = args.rotate or nil,
								}),
							},
						},
					},
				},
				config = args.uibox_config,
			})
			args.AT.attention_text = true

			args.text = args.AT.UIRoot.children[1].config.object
			args.text:pulse(0.5) ---@diagnostic disable-line: undefined-field

			if args.cover then
				Particles(args.pos.x, args.pos.y, 0, 0, {
					timer_type = "TOTAL",
					timer = 0.01,
					pulse_max = 15,
					max = 0,
					scale = 0.3,
					vel_variation = 0.2,
					padding = 0.1,
					fill = true,
					lifespan = 0.5,
					speed = 2.5,
					attach = args.AT.UIRoot,
					colours = { args.cover_colour, args.cover_colour_l, args.cover_colour_d },
				})
			end
			if args.backdrop_colour then
				args.backdrop_colour = copy_table(args.backdrop_colour)
				Particles(args.pos.x, args.pos.y, 0, 0, {
					timer_type = "TOTAL",
					timer = 5,
					scale = 2.4 * (args.backdrop_scale or 1),
					lifespan = 5,
					speed = 0,
					attach = args.AT,
					colours = { args.backdrop_colour },
				})
			end
			return true
		end,
	}))

	G.E_MANAGER:add_event(Event({
		trigger = "after",
		timer = "REAL",
		delay = args.hold,
		blockable = false,
		blocking = false,
		func = function()
			if not args.start_time then
				args.start_time = G.TIMERS.TOTAL
				args.text:pop_out(3) ---@diagnostic disable-line: undefined-field
			else
				args.fade = math.max(0, 1 - 3 * (G.TIMERS.TOTAL - args.start_time))
				if args.cover_colour then args.cover_colour[4] = math.min(args.cover_colour[4], 2 * args.fade) end
				if args.cover_colour_l then args.cover_colour_l[4] = math.min(args.cover_colour_l[4], args.fade) end
				if args.cover_colour_d then args.cover_colour_d[4] = math.min(args.cover_colour_d[4], args.fade) end
				if args.backdrop_colour then args.backdrop_colour[4] = math.min(args.backdrop_colour[4], args.fade) end
				args.colour[4] = math.min(args.colour[4], args.fade)
				if args.fade <= 0 then
					args.AT:remove()
					return true
				end
			end
		end,
	}))
end

function G.FUNCS.overlay_endgame_menu()
	G.FUNCS.overlay_menu({
		definition = MP.GAME.won and create_UIBox_win() or create_UIBox_game_over(),
		config = { no_esc = true },
	})
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 2.5,
		blocking = false,
		func = function()
			if not G.OVERLAY_MENU then return true end
			local spot = G.OVERLAY_MENU:get_UIE_by_ID("jimbo_spot") ---@diagnostic disable-line: undefined-field
			local Jimbo = Card_Character({ x = 0, y = 5 })
			spot.config.object:remove()
			spot.config.object = Jimbo
			Jimbo.ui_object_updated = true
			local jimbo_words = MP.GAME.won and "wq_" .. math.random(1, 7) or "lq_" .. math.random(1, 10)
			Jimbo:add_speech_bubble(jimbo_words, nil, { quip = true })
			Jimbo:say_stuff(5)
			return true
		end,
	}))
end

function MP.UI.ease_lives(mod)
	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		func = function()
			if not G.hand_text_area then return end

			if MP.LOBBY.config.disable_live_and_timer_hud then
				return true -- Returning nothing hangs the game because it's a part of an event
			end

			local lives_UI = G.hand_text_area.ante
			if not lives_UI then return true end

			mod = mod or 0
			local text = "+"
			local col = G.C.IMPORTANT
			if mod < 0 then
				text = "-"
				col = G.C.RED
			end
			lives_UI.config.object:update()
			G.HUD:recalculate()
			attention_text({
				text = text .. tostring(math.abs(mod)),
				scale = 1,
				hold = 0.7,
				cover = lives_UI.parent,
				cover_colour = col,
				align = "cm",
			})
			play_sound("highlight2", 0.685, 0.2)
			play_sound("generic1")
			return true
		end,
	}))
end

function MP.UI.show_asteroid_hand_level_up()
	local hand_priority = {
		["Flush Five"] = 1,
		["Flush House"] = 2,
		["Five of a Kind"] = 3,
		["Straight Flush"] = 4,
		["Four of a Kind"] = 5,
		["Full House"] = 6,
		["Flush"] = 7,
		["Straight"] = 8,
		["Three of a Kind"] = 9,
		["Two Pair"] = 11,
		["Pair"] = 12,
		["High Card"] = 13,
	}
	local hand_type = "High Card"
	local max_level = 0

	for k, v in pairs(G.GAME.hands) do
		if SMODS.is_poker_hand_visible(k) then
			if
				to_big(v.level) > to_big(max_level)
				or (to_big(v.level) == to_big(max_level) and hand_priority[k] < hand_priority[hand_type])
			then
				hand_type = k
				max_level = v.level
			end
		end
	end
	update_hand_text({ sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, {
		handname = localize(hand_type, "poker_hands"),
		chips = G.GAME.hands[hand_type].chips,
		mult = G.GAME.hands[hand_type].mult,
		level = G.GAME.hands[hand_type].level,
	})
	level_up_hand(nil, hand_type, false, -1)
	update_hand_text(
		{ sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
		{ mult = 0, chips = 0, handname = "", level = "" }
	)
end

--[[
function MP.UI.create_UIBox_Misprint_Display()
	return {
		n = G.UIT.ROOT,
		config = { align = "cm", padding = 0.03, colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.05, colour = G.C.UI.TRANSPARENT_DARK, r = 0.1 },
				nodes = {
					{
						n = G.UIT.O,
						config = {
							id = "misprint_display",
							func = "misprint_display_set",
							object = DynaText({
								string = { { ref_table = MP.GAME, ref_value = "misprint_display" } },
								colours = { G.C.UI.TEXT_LIGHT },
								shadow = true,
								float = true,
								scale = 0.5,
							}),
						},
					},
				},
			},
		},
	}
end

function G.FUNCS.misprint_display_set(e)
	local misprint_raw = (G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.id or 11)
		.. (G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit:sub(1, 1) or "D")
	if misprint_raw == e.config.last_misprint then
		return
	end
	e.config.last_misprint = misprint_raw

	local value = tonumber(misprint_raw:sub(1, -2))
	local suit = misprint_raw:sub(-1)

	local suit_full = { H = "Hearts", D = "Diamonds", C = "Clubs", S = "Spades" }

	local value_key = tostring(value)
	if value == 14 then
		value_key = "Ace"
	elseif value == 11 then
		value_key = "Jack"
	elseif value == 12 then
		value_key = "Queen"
	elseif value == 13 then
		value_key = "King"
	end

	local localized_card = {}

	localize({
		type = "other",
		key = "playing_card",
		set = "Other",
		nodes = localized_card,
		vars = {
			localize(value_key, "ranks"),
			localize(suit_full[suit], "suits_plural"),
			colours = { G.C.UI.TEXT_LIGHT },
		},
	})

	-- Yes I know this is stupid
	MP.GAME.misprint_display = localized_card[1][2].config.text .. localized_card[1][3].config.text
	e.config.object.colours = { G.C.SUITS[suit_full[suit]]
--}
--end
--]]
