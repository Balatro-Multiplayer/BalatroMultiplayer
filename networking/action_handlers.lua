-- ─── DON'T PATCH THIS FILE ───────────────────────────────────────────────────
-- This file owns the core network action dispatch. The contents move; the
-- string literals in here are NOT an API. HANDLERS is a file-local on
-- purpose — there is no global, no MP.HANDLERS, no _G shim coming to save you.
--
-- If you want to handle a network action from a mod, use one of:
--
--   MP.register_mod_action(name, cb)  -- PREFERRED. Pair with the
--                                     -- "moddedAction" envelope on the server:
--                                     --   {action = "moddedAction",
--                                     --    modId = …, modAction = name, …}
--                                     -- Keeps your action names namespaced to
--                                     -- your modId; no collisions with core
--                                     -- or other mods.
--
--   MP.register_action(name, cb)      -- Escape hatch for legacy server code
--                                     -- that emits flat top-level action
--                                     -- names. Refuses to register over an
--                                     -- existing handler (including core) —
--                                     -- first registration wins, collisions
--                                     -- warn and are dropped. Use the mod API
--                                     -- above if you can.
-- ─────────────────────────────────────────────────────────────────────────────

local json = require("json")

Client = {}

function Client.send(msg)
	msg = json.encode(msg)
	if msg ~= '{"action":"keepAliveAck"}' then
		sendTraceMessage(string.format("Client sent message: %s", msg), "MULTIPLAYER")
	end
	love.thread.getChannel("uiToNetwork"):push(msg)
end

-- Server to Client
function MP.ACTIONS.set_username(username)
	MP.LOBBY.username = username or "Guest"
	if MP.LOBBY.connected then
		Client.send({
			action = "username",
			username = MP.LOBBY.username .. "~" .. MP.LOBBY.blind_col,
			modHash = MP.MOD_STRING,
		})
	end
end

function MP.ACTIONS.set_blind_col(num)
	MP.LOBBY.blind_col = num or 1
end

-- Reconnection state (persists across connections)
local reconnectToken = nil
local lastLobbyCode = nil

local function action_connected()
	MP.LOBBY.connected = true
	MP.UI.update_connection_status()
	Client.send({
		action = "username",
		username = MP.LOBBY.username .. "~" .. MP.LOBBY.blind_col,
		modHash = MP.MOD_STRING,
	})

	-- If we have reconnect info, attempt to rejoin the lobby
	if reconnectToken and lastLobbyCode then
		Client.send({
			action = "rejoinLobby",
			code = lastLobbyCode,
			reconnectToken = reconnectToken,
		})
	end
end

local function action_joinedLobby(p)
	local code, type, token = p.code, p.type, p.reconnectToken
	MP.LOBBY.code = code
	MP.LOBBY.type = type
	MP.LOBBY.ready_to_start = false
	-- Store reconnect info for potential future reconnection
	if token then reconnectToken = token end
	lastLobbyCode = code
	MP.ACTIONS.sync_client()
	MP.ACTIONS.lobby_info()
	MP.UI.update_connection_status()
end

local function action_rejoinedLobby(p)
	local code, type, token = p.code, p.type, p.reconnectToken
	MP.LOBBY.code = code
	MP.LOBBY.type = type
	-- Update reconnect token
	reconnectToken = token
	lastLobbyCode = code
	MP.self_reconnect_countdown = nil
	MP.GAME.timer_started = false
	MP.GAME.nemesis_timer_started = false
	MP.ACTIONS.sync_client()
	MP.ACTIONS.lobby_info()
	MP.UI.update_connection_status()
	sendWarnMessage("Reconnected to lobby!", "MULTIPLAYER")
	G.FUNCS.exit_overlay_menu()
	MP.UI.UTILS.overlay_message("Reconnected to lobby!")
end

-- Countdown state for disconnect overlays
MP.enemy_disconnect_countdown = nil
MP.self_reconnect_countdown = nil

-- Shared timeout handler for both countdowns
local function handle_reconnect_timeout(message)
	G.FUNCS.exit_overlay_menu()
	MP.LOBBY.connected = false
	if MP.LOBBY.code then MP.LOBBY.code = nil end
	reconnectToken = nil
	lastLobbyCode = nil
	MP.UI.update_connection_status()
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		MP.reset_game_states()
		G.FUNCS.go_to_menu()
	end
	MP.UI.UTILS.overlay_message(message)
end

-- Hook into Game.update to tick countdown displays
local _disconnect_gupdate = Game.update
function Game:update(dt)
	if MP.enemy_disconnect_countdown then
		local remaining = math.max(0, math.ceil(MP.enemy_disconnect_countdown.end_time - love.timer.getTime()))
		MP.enemy_disconnect_countdown.display = remaining .. "s remaining"
		-- No client-side timeout needed: the server sends stopGame
		-- when the grace period expires, which handles the cleanup
	end
	if MP.self_reconnect_countdown then
		local remaining = math.max(0, math.ceil(MP.self_reconnect_countdown.end_time - love.timer.getTime()))
		MP.self_reconnect_countdown.display = remaining .. "s remaining"
		if remaining <= 0 then
			MP.self_reconnect_countdown = nil
			handle_reconnect_timeout("Reconnection failed.\nReturning to main menu.")
		end
	end
	return _disconnect_gupdate(self, dt)
end

local function action_enemyDisconnected(p)
	local timeout = p.timeout or 60
	sendWarnMessage("Opponent disconnected, waiting for reconnection...", "MULTIPLAYER")

	MP.GAME.timer_started = false
	MP.GAME.nemesis_timer_started = false

	MP.enemy_disconnect_countdown = {
		end_time = love.timer.getTime() + timeout,
		display = timeout .. "s remaining",
	}

	MP.UI.UTILS.overlay_message_countdown(
		"Opponent disconnected,\nwaiting for reconnection...",
		MP.enemy_disconnect_countdown,
		true
	)
end

local function action_enemyReconnected()
	MP.enemy_disconnect_countdown = nil
	sendWarnMessage("Opponent reconnected!", "MULTIPLAYER")
	G.FUNCS.exit_overlay_menu()
	MP.UI.UTILS.overlay_message("Opponent reconnected!")
end

local function action_lobbyInfo(p)
	local host, hostHash, hostCached = p.host, p.hostHash, p.hostCached
	local guest, guestHash, guestCached, guestReady = p.guest, p.guestHash, p.guestCached, p.guestReady
	local is_host = p.isHost
	MP.LOBBY.players = {}
	MP.LOBBY.is_host = is_host
	local function parseName(name)
		local username, col_str = string.match(name, "([^~]+)~(%d+)")
		username = username or "Guest"
		local col = tonumber(col_str) or 1
		col = math.max(1, math.min(col, 25))
		return username, col
	end
	local hostName, hostCol = parseName(host)
	local hostConfig, hostMods = MP.UTILS.parse_Hash(hostHash)
	MP.LOBBY.host = {
		username = hostName,
		blind_col = hostCol,
		hash_str = hostMods,
		hash = hash(hostMods),
		cached = hostCached,
		config = hostConfig,
	}

	if guest ~= nil then
		local guestName, guestCol = parseName(guest)
		local guestConfig, guestMods = MP.UTILS.parse_Hash(guestHash)
		MP.LOBBY.guest = {
			username = guestName,
			blind_col = guestCol,
			hash_str = guestMods,
			hash = hash(guestMods),
			cached = guestCached,
			config = guestConfig,
		}
	else
		MP.LOBBY.guest = {}
	end

	-- TODO: This should check for player count instead
	-- once we enable more than 2 players
	MP.LOBBY.ready_to_start = guest ~= nil and guestReady

	if MP.LOBBY.is_host then MP.ACTIONS.lobby_options() end

	if G.STAGE == G.STAGES.MAIN_MENU then MP.ACTIONS.update_player_usernames() end

	-- Re-arm the mismatch modal when all mismatches clear (opponent left or was replaced).
	if #MP.UTILS.version_mismatches() == 0 then MP._version_mismatch_shown = false end
end

local function action_error(p)
	local message = p.message
	sendWarnMessage(message, "MULTIPLAYER")

	MP.UI.UTILS.overlay_message(message)
end

local function action_keep_alive()
	Client.send({
		action = "keepAliveAck",
	})
end

local function action_disconnected()
	MP.LOBBY.connected = false
	MP.self_reconnect_countdown = nil
	if MP.LOBBY.code then MP.LOBBY.code = nil end
	-- Clear reconnect state since all reconnection attempts failed
	reconnectToken = nil
	lastLobbyCode = nil
	MP.UI.update_connection_status()
end

local function action_reconnecting()
	-- Only show if we were in a lobby and don't already have a countdown running
	if reconnectToken and lastLobbyCode and not MP.self_reconnect_countdown then
		MP.LOBBY.connected = false
		MP.GAME.timer_started = false
		MP.GAME.nemesis_timer_started = false
		MP.UI.update_connection_status()
		sendWarnMessage("Connection lost, attempting to reconnect...", "MULTIPLAYER")

		MP.self_reconnect_countdown = {
			end_time = love.timer.getTime() + 60,
			display = "60s remaining",
		}

		MP.UI.UTILS.overlay_message_countdown(
			"Connection lost,\nattempting to reconnect...",
			MP.self_reconnect_countdown,
			true
		)
	end
end

-- ── Run start (relocated from the removed legacy ui/lobby/lobby.lua) ──────────────
-- G.FUNCS.lobby_start_run is the actual multiplayer run-starter. It is called by
-- action_start_game below and by the API bridge gamemode's (required, but never invoked)
-- start_run in pvp_api/gamemodes.lua. The `mp_start` contract it passes to
-- G.FUNCS.start_run is interpreted by the start_run wrapper relocated to overrides/game.lua.
local function get_random_back_pool()
	local names, seen = {}, {}
	local cocktail_keys = MP.get_cocktail_decks(false)
	for i = 1, #cocktail_keys do
		local key = cocktail_keys[i]
		if G.P_CENTERS[key] and not seen[key] then
			seen[key] = true
			names[#names + 1] = G.P_CENTERS[key].name
		end
	end
	if G.P_CENTERS["b_mp_cocktail"] and not seen["b_mp_cocktail"] then
		names[#names + 1] = G.P_CENTERS["b_mp_cocktail"].name
	end
	return names
end

local function scoped_random(seed, salt, max)
	if seed then
		math.randomseed(pseudohash(seed .. "_mp_random_" .. salt))
	end
	return math.random(1, max)
end

local function roll_random_back_name(seed, salt)
	local names = get_random_back_pool()
	if #names == 0 then return "Red Deck" end
	return names[scoped_random(seed, "deck_" .. (salt or ""), #names)]
end

local function roll_random_stake(seed, salt)
	local cap = MP.DECK.MAX_STAKE > 0 and MP.DECK.MAX_STAKE or 8
	return scoped_random(seed, "stake_" .. (salt or ""), cap)
end

function G.FUNCS.copy_host_deck()
	MP.LOBBY.deck.back = MP.LOBBY.config.back
	MP.LOBBY.deck.cocktail = MP.LOBBY.config.cocktail
	MP.LOBBY.deck.sleeve = MP.LOBBY.config.sleeve
	MP.LOBBY.deck.stake = MP.LOBBY.config.stake
	MP.LOBBY.deck.challenge = MP.LOBBY.config.challenge
end

---@type fun(e: table | nil, args: { deck: string, stake: number | nil, seed: string | nil })
function G.FUNCS.lobby_start_run(e, args)
	if MP.LOBBY.config.different_decks == false then G.FUNCS.copy_host_deck() end

	if MP.LOBBY.config.different_decks and MP.LOBBY.config.random_loadout then
		MP.LOBBY.deck.back = roll_random_back_name(args.seed, MP.LOBBY.username)
		MP.LOBBY.deck.challenge = ""
		MP.LOBBY.deck.stake = roll_random_stake(args.seed, MP.LOBBY.username)
	end

	local challenge = nil
	if MP.LOBBY.deck.back == "Challenge Deck" then
		challenge = G.CHALLENGES[get_challenge_int_from_id(MP.LOBBY.deck.challenge)]
	else
		G.GAME.viewed_back = G.P_CENTERS[MP.UTILS.get_deck_key_from_name(MP.LOBBY.deck.back)]
	end

	G.FUNCS.start_run(e, {
		mp_start = true,
		challenge = challenge,
		stake = tonumber(MP.LOBBY.deck.stake),
		seed = args.seed,
	})
end

local function action_start_game(p)
	local seed = p.seed
	sendDebugMessage(string.format("Game starting — %s", os.date("%Y-%m-%dT%H:%M:%S%z")), "MULTIPLAYER")
	-- Clear any stale practice/ghost state so it can't leak into real MP
	MP.SP.practice = false
	MP.GHOST.clear()

	MP.reset_game_states()
	-- Stamp the run start (drives the pause menu's seed-change window) and clear any
	-- pending seed-change votes from a previous run/reseed.
	MP._run_started_at = love.timer.getTime()
	if MP.lobby and MP.lobby.seed_votes then
		MP.lobby.seed_votes:reset()
	end
	local stake = tonumber(p.stake)
	MP.ACTIONS.set_ante(0)
	if not MP.LOBBY.config.different_seeds and MP.LOBBY.config.custom_seed ~= "random" then
		seed = MP.LOBBY.config.custom_seed
	end

	-- Open a new replay-log block for this game with everything needed to
	-- reconstruct it deterministically later. Uses the resolved seed.
	MP.RLOG.begin_run({
		seed = seed,
		stake = stake,
		deck = MP.LOBBY.config.back,
		sleeve = MP.LOBBY.config.sleeve,
		challenge = MP.LOBBY.config.challenge,
		ruleset = MP.LOBBY.config.ruleset,
		gamemode = MP.LOBBY.config.gamemode,
		modifier_layers = MP.LOBBY.config.modifier_layers,
		lobby_config = MP.LOBBY.config,
		the_order_enabled = MP.should_use_the_order(),
		different_seeds = MP.LOBBY.config.different_seeds,
		mod_version = MP and MP.version,
		mod_hash = MP.MOD_STRING,
		smods_version = MP.SMODS_VERSION,
		lovely_version = MP.REQUIRED_LOVELY_VERSION,
		lobby_code = MP.LOBBY.code,
		is_host = MP.LOBBY.is_host,
		player = MP.LOBBY.username,
		opponent = (MP.LOBBY.is_host and MP.LOBBY.guest and MP.LOBBY.guest.username)
			or (MP.LOBBY.host and MP.LOBBY.host.username),
		start_ts = os.date("%Y-%m-%dT%H:%M:%S%z"),
	})

	G.FUNCS.lobby_start_run(nil, { seed = seed, stake = stake })
	MP.LOBBY.ready_to_start = false
end

local function begin_pvp_blind()
	if MP.GAME.next_blind_context then
		G.FUNCS.select_blind(MP.GAME.next_blind_context)
	else
		sendErrorMessage("No next blind context", "MULTIPLAYER")
	end
end

local function action_start_blind(p)
	local first_player = p.firstPlayer
	-- Reset the stored opponent score each blind so the first frame after we
	-- play (which lifts the "???" mask) shows 0, not last blind's stale score.
	MP.GAME.enemy.score = MP.INSANE_INT.empty()
	MP.GAME.enemy.real_score = MP.INSANE_INT.empty()
	MP.GAME.enemy.score_text = "0"
	-- Re-mask the opponent's hands until the first enemyInfo of the new blind.
	MP.GAME.enemy.info_received = false
	-- Royale's "first sync wins" MP.current_target_id() strategy re-latches fresh
	-- each blind (a no-op for 1v1/Nemesis, which don't use this field).
	MP.GAME.royale_target_id = nil
	MP.GAME.ready_blind = false
	MP.GAME.pvp_reached = false
	MP.GAME.timer_started = false
	MP.GAME.nemesis_timer_started = false
	MP.GAME.timer_consumed = false
	MP.GAME.timer = MP.UTILS.pvp_timer_base()
	MP.GAME.pvp_reached_first = (MP.LOBBY.is_host and "host" or "guest") == first_player
	MP.UI.start_pvp_countdown(begin_pvp_blind)
end

-- (action_enemy_info was removed: the opponent score/hands/skips/lives DISPLAY is now synced
-- by the nemesis blind's calculate/receive — see objects/blinds/nemesis.lua.)

local function action_stop_game()
	MP.enemy_disconnect_countdown = nil
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		G.FUNCS.go_to_menu()
		MP.UI.update_connection_status()
		MP.reset_game_states()
	end
	MP.RLOG.end_run({ result = "stop" })
	MP.UTILS.emit_log_checksum()
end

local function action_end_pvp(p)
	local lost, pvpTimerLost = p.lost, p.pvpTimerLost
	if lost and pvpTimerLost then
		if G.GAME.current_round.hands_left > 0 then
            stop_use()
			SMODS.calculate_context({ mp_pvp_loss = true, mp_hands_left = G.GAME.current_round.hands_left })
		end
	end
	MP.GAME.end_pvp = true
	MP.GAME.timer = MP.UTILS.timer_base()
	MP.GAME.timer_consumed = false
	MP.GAME.timer_started = false
	MP.GAME.nemesis_timer_started = false
	MP.GAME.ready_blind = false
	MP.GAME.pvp_reached = false
    MP.GAME.pvp_reached_first = false
	MP.GAME.score = nil
end

local function action_player_info(p)
	local lives = p.lives
	if MP.GAME.lives ~= lives then
		if MP.GAME.lives ~= 0 and MP.LOBBY.config.gold_on_life_loss then
			MP.GAME.comeback_bonus_given = false
			MP.GAME.comeback_bonus = MP.GAME.comeback_bonus + 1
		end
		MP.UI.ease_lives(lives - MP.GAME.lives, true)
		if MP.LOBBY.config.no_gold_on_round_loss and (G.GAME.blind and G.GAME.blind.dollars) then
			G.GAME.blind.dollars = 0
		end
	end
	MP.GAME.lives = lives
end

local function action_win_game()
	MP.end_game_jokers_payload = ""
	MP.nemesis_deck_string = ""
	MP.end_game_jokers_received = false
	MP.nemesis_deck_received = false
	MP.GAME.won = true
	MP.STATS.record_match(true)
	MP.RLOG.end_run({ result = "win" })
	MP.UTILS.log_mem_debug_messages()
	MP.UTILS.emit_log_checksum()
	win_game()
end

local function action_lose_game()
	MP.end_game_jokers_payload = ""
	MP.nemesis_deck_string = ""
	MP.end_game_jokers_received = false
	MP.nemesis_deck_received = false
	MP.STATS.record_match(false)
	G.STATE_COMPLETE = false
	G.STATE = G.STATES.GAME_OVER
	MP.RLOG.end_run({ result = "loss" })
	MP.UTILS.log_mem_debug_messages()
	MP.UTILS.emit_log_checksum()
end

local function action_lobby_options(options)
	local different_decks_before = MP.LOBBY.config.different_decks
	for k, v in pairs(options) do
		if k == "ruleset" then
			if not MP.Rulesets[v] then
				G.FUNCS.mp_pvp_leave_lobby()
				MP.UI.UTILS.overlay_message(localize({
					type = "variable",
					key = "k_failed_to_join_lobby",
					vars = { localize("k_ruleset_not_found") },
				}))
				return
			end
			local disabled = MP.Rulesets[v].is_disabled()
			if disabled then
				G.FUNCS.mp_pvp_leave_lobby()
				MP.UI.UTILS.overlay_message(
					localize({ type = "variable", key = "k_failed_to_join_lobby", vars = { disabled } })
				)
				return
			end
			MP.LOBBY.config.ruleset = v
			goto continue
		end
		if k == "gamemode" then
			MP.LOBBY.config.gamemode = v
			goto continue
		end
		if k == "modifier_layers" then
			MP.LOBBY.config.modifier_layers = v
			MP.modifiers_parse(v)
			goto continue
		end

		local parsed_v = v
		if v == "true" then
			parsed_v = true
		elseif v == "false" then
			parsed_v = false
		end

		if
			k == "starting_lives"
			or k == "pvp_start_round"
			or k == "timer_base_seconds"
			or k == "timer_increment_seconds"
			or k == "showdown_starting_antes"
			or k == "pvp_countdown_seconds"
			or k == "timer_forgiveness"
		then
			parsed_v = tonumber(v)
		end

		MP.LOBBY.config[k] = parsed_v
		if MP.UI.update_lobby_option_toggle then MP.UI.update_lobby_option_toggle(k) end
		::continue::
	end
	if different_decks_before ~= MP.LOBBY.config.different_decks then
		G.FUNCS.exit_overlay_menu() -- throw out guest from any menu.
	end
	MP.ACTIONS.update_player_usernames() -- render new DECK button state
end

-- (The phantom masking patches — Card:remove / SMODS.find_card / poll_edition — moved to the
-- synced-object framework; installed via MPAPI.configure_phantom in objects/editions/phantom.lua.)

local function action_speedrun()
	SMODS.calculate_context({ mp_speedrun = true })
end

local function enemyLocation(options)
	local location = options.location
	local value = ""

	if string.find(location, "-") then
		local split = {}
		for str in string.gmatch(location, "([^-]+)") do
			table.insert(split, str)
		end
		location = split[1]
		value = split[2] or ""
	end

	local loc_location = G.localization.misc.dictionary[location]

	if loc_location == nil then
		if location ~= nil then
			loc_location = location
		else
			loc_location = "Unknown"
		end
	end

	MP.GAME.enemy.location = loc_location
	MP.GAME.enemy.location_blind = value
	MP.GAME.enemy.location_type = location
	MP.GAME.enemy.location_full = location .. "-" .. value
	MP.UI.update_enemy_location_render()
end

local function action_version()
	MP.ACTIONS.version()
end

function G.FUNCS.load_end_game_jokers()
	local card_area_save, success, err

	if not MP.end_game_jokers or not MP.end_game_jokers_payload then return end

	card_area_save, err = MP.UTILS.str_decode_and_unpack(MP.end_game_jokers_payload)
	if not card_area_save then
		sendDebugMessage(string.format("Failed to unpack enemy jokers: %s", err), "MULTIPLAYER")
		return
	end

	-- Avoid crashing if the load function ends up indexing a nil value
	success, err = pcall(MP.end_game_jokers.load, MP.end_game_jokers, card_area_save)
	if not success then
		sendDebugMessage(string.format("Failed to load enemy jokers: %s", err), "MULTIPLAYER")
		-- Reset the card area if loading fails to avoid inconsistent state
		MP.end_game_jokers:remove()
		MP.end_game_jokers:init(
			---@diagnostic disable-next-line: param-type-mismatch
			0,
			0,
			5 * G.CARD_W,
			G.CARD_H,
			{ card_limit = G.GAME.starting_params.joker_slots, type = "joker", highlight_limit = 1, fixed_limit = true }
		)
		return
	end

	-- Log the jokers
	if MP.end_game_jokers.cards then
		local jokers_str = ""
		for _, card in pairs(MP.end_game_jokers.cards) do
			jokers_str = jokers_str .. ";" .. MP.UTILS.joker_to_string(card)
		end
		sendTraceMessage(string.format("Received end game jokers: %s", jokers_str), "MULTIPLAYER")
	end
end

local function action_receive_end_game_jokers(p)
	MP.end_game_jokers_payload = p.keys
	MP.end_game_jokers_received = true
	G.FUNCS.load_end_game_jokers()
end

local function action_get_end_game_jokers()
	if not G.jokers or not G.jokers.cards then
		Client.send({
			action = "receiveEndGameJokers",
			keys = {},
		})
		return
	end

	-- Log the jokers
	local jokers_str = ""
	for _, card in pairs(G.jokers.cards) do
		jokers_str = jokers_str .. ";" .. MP.UTILS.joker_to_string(card)
	end
	sendTraceMessage(string.format("Sending end game jokers: %s", jokers_str), "MULTIPLAYER")

	local jokers_save = G.jokers:save()
	local jokers_encoded = MP.UTILS.str_pack_and_encode(jokers_save)

	Client.send({
		action = "receiveEndGameJokers",
		keys = jokers_encoded,
	})
end

local function action_get_nemesis_deck()
	local deck_str = ""
	for _, card in ipairs(G.playing_cards) do
		deck_str = deck_str .. ";" .. MP.UTILS.card_to_string(card)
	end
	Client.send({
		action = "receiveNemesisDeck",
		cards = deck_str,
	})
end

local function action_send_game_stats()
	if not MP.GAME.stats then
		Client.send({
			action = "nemesisEndGameStats",
		})
		return
	end

	local stats = {
		action = "nemesisEndGameStats",
		reroll_count = MP.GAME.stats.reroll_count,
		reroll_cost_total = MP.GAME.stats.reroll_cost_total,
	}

	-- Extract voucher keys where value is true and join them with a dash
	local voucher_keys = ""
	if G.GAME.used_vouchers then
		local keys = {}
		for k, v in pairs(G.GAME.used_vouchers) do
			if v == true then table.insert(keys, k) end
		end
		voucher_keys = table.concat(keys, "-")
	end

	-- Add voucher keys to stats string
	if voucher_keys ~= "" then stats.vouchers = voucher_keys end

	Client.send(stats)
end

function G.FUNCS.load_nemesis_deck()
	if not MP.nemesis_deck_string or not MP.nemesis_deck or not MP.nemesis_cards or not MP.LOBBY.code then return end

	local card_strings = MP.UTILS.string_split(MP.nemesis_deck_string, ";")

	for k, _ in pairs(MP.nemesis_cards) do
		MP.nemesis_cards[k] = nil
	end

	for _, card_str in pairs(card_strings) do
		if card_str == "" then goto continue end

		local card_params = MP.UTILS.string_split(card_str, "-")

		local suit = card_params[1]
		local rank = card_params[2]
		local enhancement = card_params[3]
		local edition = card_params[4]
		local seal = card_params[5]

		-- Validate the card parameters
		-- If invalid suit or rank, skip the card
		-- If invalid enhancement, edition, or seal, fallback to "none"
		local front_key = tostring(suit) .. "_" .. tostring(rank)
		if not G.P_CARDS[front_key] then
			sendDebugMessage(string.format("Invalid playing card key: %s", front_key), "MULTIPLAYER")
			goto continue
		end
		if not enhancement or (enhancement ~= "none" and not G.P_CENTERS[enhancement]) then
			sendDebugMessage(string.format("Invalid enhancement: %s", enhancement), "MULTIPLAYER")
			enhancement = "none"
		end
		if not edition or (edition ~= "none" and not G.P_CENTERS["e_" .. edition]) then
			sendDebugMessage(string.format("Invalid edition: %s", edition), "MULTIPLAYER")
			edition = "none"
		end
		if not seal or (seal ~= "none" and not G.P_SEALS[seal]) then
			sendDebugMessage(string.format("Invalid seal: %s", seal), "MULTIPLAYER")
			seal = "none"
		end

		-- Create the card
		local card = create_playing_card({
			front = G.P_CARDS[front_key],
			center = enhancement ~= "none" and G.P_CENTERS[enhancement] or nil,
		}, MP.nemesis_deck, true, true, nil, false)
		if edition ~= "none" then card:set_edition({ [edition] = true }, true, true) end
		if seal ~= "none" then card:set_seal(seal, true, true) end

		-- Remove the card from G.playing_cards and insert into MP.nemesis_cards
		table.remove(G.playing_cards, #G.playing_cards)
		table.insert(MP.nemesis_cards, card)

		::continue::
	end
end

local function action_receive_nemesis_deck(p)
	MP.nemesis_deck_string = p.cards
	MP.nemesis_deck_received = true
	G.FUNCS.load_nemesis_deck()
end

-- Dual-call: dispatched from network (fromNemesis defaults to true) or self-triggered
-- by MP.ACTIONS.start_ante_timer (passes fromNemesis = false explicitly).
local function action_start_ante_timer(p)
	if p.isPvP and (MP.GAME.end_pvp or not MP.is_pvp_boss() or G.GAME.current_round.hands_left <= 0) then return end

	local time = p.time
	local from_nemesis = p.fromNemesis
	if from_nemesis == nil then from_nemesis = true end

	local option = MP.config.timersfx or 1
	local timersfx = (option == 1) or (option == 2 and G.timer_ante ~= G.GAME.round_resets.ante)
	G.timer_ante = G.GAME.round_resets.ante

	if timersfx then
		for i = 1, 3 do
			local wait_time = (0.15 * (i - 1))
			G.E_MANAGER:add_event(Event({
				blocking = false,
				blockable = false,
				trigger = "after",
				delay = G.SETTINGS.GAMESPEED * wait_time,
				func = function()
					play_sound("timpani", 0.55 + 0.25 * i, 0.7)
					play_sound("generic1", 0.75 + 0.25 * i, 0.7)
					return true
				end,
			}))
		end
	end
	-- Default timer is server-synced; pressure/no-anim/pvp timers run locally.
	if not MP.timer_is_local() then
		if type(time) == "string" then time = tonumber(time) end
		if time then MP.GAME.timer = time end
	end
	if from_nemesis then
		MP.GAME.nemesis_timer_started = true
	else
		MP.GAME.timer_started = true
	end
end

local function action_pause_ante_timer(p)
	local time = p.time
	local from_nemesis = p.fromNemesis
	if from_nemesis == nil then from_nemesis = true end

	-- Default timer is server-synced; pressure/no-anim/pvp timers run locally.
	if not MP.timer_is_local() then
		if type(time) == "string" then time = tonumber(time) end
		if time then MP.GAME.timer = time end
	end
	if from_nemesis then
		MP.GAME.nemesis_timer_started = false
	else
		MP.GAME.timer_started = false
	end
end

local function action_modded_action(p)
	local registry = MP.MOD_ACTIONS[p.modId]
	if registry and registry[p.modAction] then registry[p.modAction](p) end
end

-- #region Client to Server
function MP.ACTIONS.create_lobby(gamemode)
	Client.send({
		action = "createLobby",
		gameMode = gamemode,
	})
end

function MP.ACTIONS.join_lobby(code)
	Client.send({
		action = "joinLobby",
		code = code,
	})
end

function MP.ACTIONS.ready_lobby()
	Client.send({
		action = "readyLobby",
	})
end

function MP.ACTIONS.unready_lobby()
	Client.send({
		action = "unreadyLobby",
	})
end

function MP.ACTIONS.lobby_info()
	Client.send({
		action = "lobbyInfo",
	})
end

function MP.ACTIONS.leave_lobby()
	-- Clear reconnect state on voluntary leave
	reconnectToken = nil
	lastLobbyCode = nil
	Client.send({
		action = "leaveLobby",
	})
	MP.UTILS.emit_log_checksum()
end

function MP.ACTIONS.start_game()
	Client.send({
		action = "startGame",
	})
end

function MP.ACTIONS.ready_blind(e)
	MP.GAME.next_blind_context = e
	Client.send({
		action = "readyBlind",
	})
end

function MP.ACTIONS.unready_blind()
	Client.send({
		action = "unreadyBlind",
	})
end

function MP.ACTIONS.stop_game()
	Client.send({
		action = "stopGame",
	})
end

function MP.ACTIONS.fail_round(hands_used)
	if MP.LOBBY.config.no_gold_on_round_loss then G.GAME.blind.dollars = 0 end
	if hands_used == 0 then return end
	Client.send({
		action = "failRound",
	})
end

function MP.ACTIONS.version()
	Client.send({
		action = "version",
		version = MULTIPLAYER_VERSION,
	})
end

function MP.ACTIONS.set_location(location, blind)
	local location_type = location
	local location_blind = blind
	if string.find(location, "-") then
		local split = {}
		for str in string.gmatch(location, "([^-]+)") do
			table.insert(split, str)
		end
		location_type = split[1]
		location_blind = split[2] or ""
	else
		location_blind = MP.UTILS.get_blind_to_display(blind) or ""
	end
	location = location_type .. "-" .. location_blind

	if MP.GAME.location == location then return end
	MP.GAME.location = location
	MP.GAME.location_type = location_type
	MP.GAME.location_blind = location_blind
	MP.GAME.location_full = location
	Client.send({
		action = "setLocation",
		location = location,
	})
end

function MP.ACTIONS.update_location(keep_blind)
	if MP.GAME.location_type then
		MP.ACTIONS.set_location(MP.GAME.location_type, keep_blind and MP.GAME.location_blind or nil)
	end
end

---@param score number
---@param hands_left number
function MP.ACTIONS.play_hand(score, hands_left)
	local fixed_score = tostring(to_big(score))
	-- Credit to sidmeierscivilizationv on discord for this fix for Talisman
	if string.match(fixed_score, "[eE]") == nil and string.match(fixed_score, "[.]") then
		-- Remove decimal from non-exponential numbers
		fixed_score = string.sub(string.gsub(fixed_score, "%.", ","), 1, -3)
	end
	fixed_score = string.gsub(fixed_score, ",", "") -- Remove commas

	local insane_int_score = MP.INSANE_INT.from_string(fixed_score)
	MP.GAME.score = insane_int_score
	if MP.INSANE_INT.greater_than(insane_int_score, MP.GAME.highest_score) then
		MP.GAME.highest_score = insane_int_score
	end

	-- Stop PvP timers according to score
	if MP.is_pvp_boss() and MP.is_layer_active("pvp_timer") then
		if MP.INSANE_INT.greater_than(insane_int_score, MP.GAME.enemy.score) then
			MP.GAME.nemesis_timer_started = false
        elseif MP.INSANE_INT.equal(insane_int_score, MP.GAME.enemy.score) and MP.GAME.pvp_reached_first then
            MP.GAME.nemesis_timer_started = false
		else
			MP.GAME.timer_started = false
		end
	end

	Client.send({
		action = "playHand",
		score = fixed_score,
		handsLeft = hands_left,
	})
end

function MP.ACTIONS.lobby_options()
	---@type table<string, any>
	local msg = {
		action = "lobbyOptions",
	}
	for k, v in pairs(MP.LOBBY.config) do
		msg[tostring(k)] = v
	end
	Client.send(msg)
end

function MP.ACTIONS.set_ante(ante)
	Client.send({
		action = "setAnte",
		ante = ante,
	})
end

function MP.ACTIONS.new_round()
	MP.GAME.duplicate_end = false
	MP.GAME.round_ended = false
	Client.send({
		action = "newRound",
	})
end

function MP.ACTIONS.set_furthest_blind(furthest_blind)
	Client.send({
		action = "setFurthestBlind",
		furthestBlind = furthest_blind,
	})
end

function MP.ACTIONS.skip(skips)
	Client.send({
		action = "skip",
		skips = skips,
	})
end

function MP.ACTIONS.get_end_game_jokers()
	Client.send({
		action = "getEndGameJokers",
	})
end

function MP.ACTIONS.get_nemesis_deck()
	Client.send({
		action = "getNemesisDeck",
	})
end

function MP.ACTIONS.send_game_stats()
	Client.send({
		action = "sendGameStats",
	})
	action_send_game_stats()
end

function MP.ACTIONS.request_nemesis_stats()
	Client.send({
		action = "endGameStatsRequested",
	})
end

function MP.ACTIONS.start_ante_timer()
	local is_pvp = MP.is_pvp_boss() and MP.is_layer_active("pvp_timer")
	Client.send({
		action = "startAnteTimer",
		time = MP.GAME.timer,
		isPvP = is_pvp or nil,
	})
	action_start_ante_timer({ time = MP.GAME.timer, fromNemesis = false })
end

function MP.ACTIONS.pause_ante_timer()
	Client.send({
		action = "pauseAnteTimer",
		time = MP.GAME.timer,
	})
	action_pause_ante_timer({ time = MP.GAME.timer, fromNemesis = false })
end

function MP.ACTIONS.fail_timer()
	Client.send({
		action = "failTimer",
	})
end
function MP.ACTIONS.fail_pvp_timer()
	Client.send({
		action = "failPvPTimer",
	})
end

function MP.ACTIONS.sync_client()
	Client.send({
		action = "syncClient",
		isCached = _RELEASE_MODE,
	})
end

-- Live carbon-log stream: batches of "MP_RLOG: ..." lines pushed while the game
-- is in progress, keyed by game_id so the server can group them and drop them
-- once the final package below lands. See lib/replay_log.lua (MP.RLOG).
function MP.ACTIONS.stream_log_lines(game_id, lines)
	Client.send({
		action = "streamLogLines",
		gameId = game_id,
		lines = lines,
	})
end

-- End-of-game replay-log fingerprints. The server stores these (keyed by
-- lobby + seed + game) so a presented log can later be re-hashed and compared
-- without a line-by-line diff, and uses game_id to delete the live stream in
-- favour of this complete package. See lib/replay_log.lua (MP.RLOG).
function MP.ACTIONS.submit_log_hashes(carbon, human, seed, log, game_id)
	Client.send({
		action = "submitLogHashes",
		carbon = carbon,
		human = human,
		seed = seed,
		log = log,
		gameId = game_id,
	})
end

function MP.ACTIONS.modded(modId, modAction, params, target)
	local msg = {
		action = "moddedAction",
		modId = modId,
		modAction = modAction,
	}
	if params then
		for k, v in pairs(params) do
			msg[k] = v
		end
	end
	if target then msg.target = target end
	Client.send(msg)
end

-- #endregion Client to Server

-- Utils
function MP.ACTIONS.connect()
	Client.send({
		action = "connect",
	})
end

function MP.ACTIONS.update_player_usernames()
	if MP.LOBBY.code then
		if G.MAIN_MENU_UI then G.MAIN_MENU_UI:remove() end
		set_main_menu_UI()
	end
end

local function string_to_table(str)
	local tbl = {}
	for part in string.gmatch(str, "([^,]+)") do
		local key, value = string.match(part, "([^:]+):(.+)")
		if key and value then tbl[key] = value end
	end
	return tbl
end

local last_game_seed = nil

local function noop() end

local HANDLERS = {
	connected = action_connected,
	version = action_version,
	disconnected = action_disconnected,
	reconnecting = action_reconnecting,
	joinedLobby = action_joinedLobby,
	rejoinedLobby = action_rejoinedLobby,
	enemyDisconnected = action_enemyDisconnected,
	enemyReconnected = action_enemyReconnected,
	lobbyInfo = action_lobbyInfo,
	startGame = action_start_game,
	startBlind = action_start_blind,
	stopGame = action_stop_game,
	endPvP = action_end_pvp,
	playerInfo = action_player_info,
	winGame = action_win_game,
	loseGame = action_lose_game,
	lobbyOptions = action_lobby_options,
	enemyLocation = enemyLocation,
	speedrun = action_speedrun,
	getEndGameJokers = action_get_end_game_jokers,
	receiveEndGameJokers = action_receive_end_game_jokers,
	getNemesisDeck = action_get_nemesis_deck,
	receiveNemesisDeck = action_receive_nemesis_deck,
	endGameStatsRequested = action_send_game_stats,
	nemesisEndGameStats = noop, -- logged only, no handler
	startAnteTimer = action_start_ante_timer,
	pauseAnteTimer = action_pause_ante_timer,
	moddedAction = action_modded_action,
	error = action_error,
	keepAlive = action_keep_alive,
}

-- Peer dispatch: invoke a server->client action handler by its wire name. The
-- MPAPI ActionType layer (pvp_api/) calls this from on_receive to run the existing
-- client-side handlers when a peer action arrives, replacing the old socket pump.
function MP.dispatch_action(name, params)
	local handler = HANDLERS[name]
	if handler then
		handler(params or {})
	else
		sendWarnMessage("MP.dispatch_action: no handler for '" .. tostring(name) .. "'", "MULTIPLAYER")
	end
end

function MP.register_action(name, cb)
	if HANDLERS[name] then
		sendWarnMessage(
			"MP.register_action: '" .. name .. "' already has a handler; refusing to register. Use MP.register_mod_action if possible.",
			"MULTIPLAYER"
		)
		return
	end
	HANDLERS[name] = cb
end

local network_to_ui_channel = love.thread.getChannel("networkToUi")

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	game_update_ref(self, dt)

	repeat
		local msg = network_to_ui_channel:pop()
		if msg then
			-- horribly messy catch
			if string.sub(msg, 1, 1) == "a" then
				if msg ~= "action:keepAlive" then
					local networkToUiChannel = love.thread.getChannel("networkToUi")
					networkToUiChannel:push(json.encode({
						action = "error",
						message = "Attempting to connect to outdated server",
					}))
					networkToUiChannel:push('{"action":"disconnected"}')
				end
				return
			end

			local ok, parsedAction = pcall(json.decode, msg)
            if ok then
                if not ((parsedAction.action == "keepAlive") or (parsedAction.action == "keepAliveAck")) then
                    local log = string.format("Client got %s message: ", parsedAction.action)
                    for k, v in pairs(parsedAction) do
                        if parsedAction.action == "startGame" and k == "seed" then
                            last_game_seed = v
                        else
                            log = log .. string.format(" (%s: %s) ", k, v)
                        end
                    end
                    if
                        (parsedAction.action == "receiveEndGameJokers" or parsedAction.action == "stopGame")
                        and last_game_seed
                    then
                        log = log .. string.format(" (seed: %s) ", last_game_seed)
                    end
                    sendTraceMessage(log, "MULTIPLAYER")
                end
    
                local handler = HANDLERS[parsedAction.action]
                if handler then handler(parsedAction) end
            else
                sendWarnMessage(
                    "Invalid server response: " .. msg,
                    "MULTIPLAYER"
                )
            end
		end
	until not msg
end
