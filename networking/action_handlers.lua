Client = {}

function Client.send(msg)
	if not (msg == "action:keepAliveAck") then
		sendTraceMessage(string.format("Client sent message: %s", msg), "MULTIPLAYER")
	end
	love.thread.getChannel("uiToNetwork"):push(msg)
end

-- Server to Client
function MP.ACTIONS.set_username(username)
	MP.LOBBY.username = username or "Guest"
	if MP.LOBBY.connected then
		Client.send(
			string.format(
				"action:username,username:%s,modHash:%s",
				MP.LOBBY.username .. "~" .. MP.LOBBY.blind_col,
				MP.MOD_STRING
			)
		)
	end
end

function MP.ACTIONS.set_blind_col(num)
	MP.LOBBY.blind_col = num or 1
end

local function action_connected()
	MP.LOBBY.connected = true
	MP.UI.update_connection_status()
	Client.send(
		string.format(
			"action:username,username:%s,modHash:%s",
			MP.LOBBY.username .. "~" .. MP.LOBBY.blind_col,
			MP.MOD_STRING
		)
	)
end

local function action_joinedLobby(code, type)
	MP.LOBBY.code = code
	MP.LOBBY.type = type
	MP.LOBBY.ready_to_start = false
	MP.ACTIONS.sync_client()
	MP.ACTIONS.lobby_info()
	MP.UI.update_connection_status()
end

local function action_lobbyInfo(host, hostHash, hostCached, guest, guestHash, guestCached, guestReady, is_host)
	MP.LOBBY.players = {}
	MP.LOBBY.is_host = is_host == "true"
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
		cached = hostCached == "true",
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
			cached = guestCached == "true",
			config = guestConfig,
		}
	else
		MP.LOBBY.guest = {}
	end

	-- Backwards compatibility for old server, assume guest is ready
	-- TODO: Remove this once new server gets released
	guestReady = guestReady or "true"

	-- TODO: This should check for player count instead
	-- once we enable more than 2 players
	MP.LOBBY.ready_to_start = guest ~= nil and guestReady == "true"

	if MP.LOBBY.is_host then
		MP.ACTIONS.lobby_options()
	end

	if G.STAGE == G.STAGES.MAIN_MENU then
		MP.ACTIONS.update_player_usernames()
	end
end

local function action_error(message)
	sendWarnMessage(message, "MULTIPLAYER")

	MP.UTILS.overlay_message(message)
end

local function action_keep_alive()
	Client.send("action:keepAliveAck")
end

local function action_disconnected()
	MP.LOBBY.connected = false
	if MP.LOBBY.code then
		MP.LOBBY.code = nil
	end
	MP.UI.update_connection_status()
end

---@param deck string
---@param seed string
---@param stake_str string
local function action_start_game(seed, stake_str)
	MP.reset_game_states()
	local stake = tonumber(stake_str)
	MP.ACTIONS.set_ante(0)
	if not MP.LOBBY.config.different_seeds and MP.LOBBY.config.custom_seed ~= "random" then
		seed = MP.LOBBY.config.custom_seed
	end
	G.FUNCS.lobby_start_run(nil, { seed = seed, stake = stake })
	MP.LOBBY.ready_to_start = false
end

local function action_start_blind()
	MP.GAME.ready_blind = false
	MP.GAME.timer_started = false
	MP.GAME.timer = MP.LOBBY.config.timer_base_seconds
	if MP.GAME.next_blind_context then
		G.FUNCS.select_blind(MP.GAME.next_blind_context)
	else
		sendErrorMessage("No next blind context", "MULTIPLAYER")
	end
end

---@param score_str string
---@param hands_left_str string
---@param skips_str string
local function action_enemy_info(score_str, hands_left_str, skips_str, lives_str)
	local score = MP.INSANE_INT.from_string(score_str)

	local hands_left = tonumber(hands_left_str)
	local skips = tonumber(skips_str)
	local lives = tonumber(lives_str)

	if MP.GAME.enemy.skips ~= skips then
		for i = 1, skips - MP.GAME.enemy.skips do
			MP.GAME.enemy.spent_in_shop[#MP.GAME.enemy.spent_in_shop + 1] = 0
		end
	end

	if score == nil or hands_left == nil then
		sendDebugMessage("Invalid score or hands_left", "MULTIPLAYER")
		return
	end

	if MP.INSANE_INT.greater_than(score, MP.GAME.enemy.highest_score) then
		MP.GAME.enemy.highest_score = score
	end

	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "ease",
		delay = 3,
		ref_table = MP.GAME.enemy.score,
		ref_value = "e_count",
		ease_to = score.e_count,
		func = function(t)
			return math.floor(t)
		end,
	}))

	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "ease",
		delay = 3,
		ref_table = MP.GAME.enemy.score,
		ref_value = "coeffiocient",
		ease_to = score.coeffiocient,
		func = function(t)
			return math.floor(t)
		end,
	}))

	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "ease",
		delay = 3,
		ref_table = MP.GAME.enemy.score,
		ref_value = "exponent",
		ease_to = score.exponent,
		func = function(t)
			return math.floor(t)
		end,
	}))

	MP.GAME.enemy.hands = hands_left
	MP.GAME.enemy.skips = skips
	MP.GAME.enemy.lives = lives
	if MP.is_pvp_boss() then
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count"):juice_up()
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned"):juice_up()
	end
end

local function action_stop_game()
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		G.FUNCS.go_to_menu()
		MP.UI.update_connection_status()
		MP.reset_game_states()
	end
end

local function action_end_pvp()
	MP.GAME.end_pvp = true
	MP.GAME.timer = MP.LOBBY.config.timer_base_seconds
	MP.GAME.timer_started = false
end

---@param lives number
local function action_player_info(lives)
	if MP.GAME.lives ~= lives then
		if MP.GAME.lives ~= 0 and MP.LOBBY.config.gold_on_life_loss then
			MP.GAME.comeback_bonus_given = false
			MP.GAME.comeback_bonus = MP.GAME.comeback_bonus + 1
		end
		ease_lives(lives - MP.GAME.lives)
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
	win_game()
	MP.GAME.won = true
end

local function action_lose_game()
	MP.end_game_jokers_payload = ""
	MP.nemesis_deck_string = ""
	MP.end_game_jokers_received = false
	MP.nemesis_deck_received = false
	G.STATE_COMPLETE = false
	G.STATE = G.STATES.GAME_OVER
end

local function action_lobby_options(options)
	local different_decks_before = MP.LOBBY.config.different_decks
	for k, v in pairs(options) do
		if k == "ruleset" then
			if not MP.Rulesets[v] then
				G.FUNCS.lobby_leave(nil)
				MP.UTILS.overlay_message(localize({ type = "variable", key = "k_failed_to_join_lobby", vars = { localize("k_ruleset_not_found") } }))
				return
			end
			local disabled = MP.Rulesets[v].is_disabled()
			if disabled then
				G.FUNCS.lobby_leave(nil)
				MP.UTILS.overlay_message(localize({ type = "variable", key = "k_failed_to_join_lobby", vars = { disabled } }))
				return
			end
			MP.LOBBY.config.ruleset = v
			goto continue
		end
		if k == "gamemode" then
			MP.LOBBY.config.gamemode = v
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
		then
			parsed_v = tonumber(v)
		end

		MP.LOBBY.config[k] = parsed_v
		if G.OVERLAY_MENU then
			local config_uie = G.OVERLAY_MENU:get_UIE_by_ID(k .. "_toggle")
			if config_uie then
				G.FUNCS.toggle(config_uie)
			end
		end
		::continue::
	end
	if different_decks_before ~= MP.LOBBY.config.different_decks then
		G.FUNCS.exit_overlay_menu() -- throw out guest from any menu.
	end
	MP.ACTIONS.update_player_usernames() -- render new DECK button state
end

local function action_send_phantom(key)
	local menu = G.OVERLAY_MENU -- we are spoofing a menu here, which disables duplicate protection
	G.OVERLAY_MENU = G.OVERLAY_MENU or true
	local new_card = create_card("Joker", MP.shared, false, nil, nil, nil, key)
	new_card:set_edition("e_mp_phantom")
	new_card:add_to_deck()
	MP.shared:emplace(new_card)
	G.OVERLAY_MENU = menu
end

local function action_remove_phantom(key)
	local card = MP.UTILS.get_phantom_joker(key)
	if card then
		card:remove_from_deck()
		card:start_dissolve({ G.C.RED }, nil, 1.6)
		MP.shared:remove_card(card)
	end
end

-- card:remove is called in an event so we have to hook the function instead of doing normal things
local cardremove = Card.remove
function Card:remove()
	local menu = G.OVERLAY_MENU
	if self.edition and self.edition.type == "mp_phantom" then
		G.OVERLAY_MENU = G.OVERLAY_MENU or true
	end
	cardremove(self)
	G.OVERLAY_MENU = menu
end

-- and smods find card STILL needs to be patched here
local smodsfindcard = SMODS.find_card
function SMODS.find_card(key, count_debuffed)
	local ret = smodsfindcard(key, count_debuffed)
	local new_ret = {}
	for i, v in ipairs(ret) do
		if not v.edition or v.edition.type ~= "mp_phantom" then
			new_ret[#new_ret + 1] = v
		end
	end
	return new_ret
end

-- don't poll edition
local origedpoll = poll_edition
function poll_edition(_key, _mod, _no_neg, _guaranteed, _options)
	if G.OVERLAY_MENU then
		return nil
	end
	return origedpoll(_key, _mod, _no_neg, _guaranteed, _options)
end

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
		value = split[2]
	end

	loc_name = localize({ type = "name_text", key = value, set = "Blind" })
	if loc_name ~= "ERROR" then
		value = loc_name
	else
		value = (G.P_BLINDS[value] and G.P_BLINDS[value].name) or value
	end

	loc_location = G.localization.misc.dictionary[location]

	if loc_location == nil then
		if location ~= nil then
			loc_location = location
		else
			loc_location = "Unknown"
		end
	end

	MP.GAME.enemy.location = loc_location .. value
end

local function action_version()
	MP.ACTIONS.version()
end

local action_asteroid = action_asteroid
	or function()
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
			if v.visible then
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

local function action_sold_joker()
	-- HACK: this action is being sent when any card is being sold, since Taxes is now reworked
	MP.GAME.enemy.sells = MP.GAME.enemy.sells + 1
	MP.GAME.enemy.sells_per_ante[G.GAME.round_resets.ante] = (
		(MP.GAME.enemy.sells_per_ante[G.GAME.round_resets.ante] or 0) + 1
	)
end

local function action_lets_go_gambling_nemesis()
	local card = MP.UTILS.get_phantom_joker("j_mp_lets_go_gambling")
	if card then
		card:juice_up()
	end
	ease_dollars(card and card.ability and card.ability.extra and card.ability.extra.nemesis_dollars or 5)
end

local function action_eat_pizza(discards)
	MP.GAME.pizza_discards = MP.GAME.pizza_discards + discards
	G.GAME.round_resets.discards = G.GAME.round_resets.discards + discards
	ease_discard(discards)
end

local function action_spent_last_shop(amount)
	MP.GAME.enemy.spent_in_shop[#MP.GAME.enemy.spent_in_shop + 1] = tonumber(amount)
end

local function action_magnet()
	local card = nil
	for _, v in pairs(G.jokers.cards) do
		if not card or v.sell_cost > card.sell_cost then
			card = v
		end
	end

	if card then
		local candidates = {}
		for _, v in pairs(G.jokers.cards) do
			if v.sell_cost == card.sell_cost then
				table.insert(candidates, v)
			end
		end

		-- Scale the pseudo from 0 - 1 to the number of candidates
		local random_index = math.floor(pseudorandom("j_mp_magnet") * #candidates) + 1
		local chosen_card = candidates[random_index]
		sendTraceMessage(
			string.format("Sending magnet joker: %s", MP.UTILS.joker_to_string(chosen_card)),
			"MULTIPLAYER"
		)

		local card_save = chosen_card:save()
		local card_encoded = MP.UTILS.str_pack_and_encode(card_save)
		MP.ACTIONS.magnet_response(card_encoded)
	end
end

local function action_magnet_response(key)
	local card_save, success, err

	card_save, err = MP.UTILS.str_decode_and_unpack(key)
	if not card_save then
		sendDebugMessage(string.format("Failed to unpack magnet joker: %s", err), "MULTIPLAYER")
		return
	end

	local card =
		Card(G.jokers.T.x + G.jokers.T.w / 2, G.jokers.T.y, G.CARD_W, G.CARD_H, G.P_CENTERS.j_joker, G.P_CENTERS.c_base)
	-- Avoid crashing if the load function ends up indexing a nil value
	success, err = pcall(card.load, card, card_save)
	if not success then
		sendDebugMessage(string.format("Failed to load magnet joker: %s", err), "MULTIPLAYER")
		return
	end

	-- BALATRO BUG (version 1.0.1o): `card.VT.h` is mistakenly set to nil after calling `card:load()`
	-- Without this call to `card:hard_set_VT()`, the game will crash later when the card is drawn
	card:hard_set_VT()

	-- Enforce "add to deck" effects (e.g. increase hand size effects)
	card.added_to_deck = nil

	card:add_to_deck()
	G.jokers:emplace(card)
	sendTraceMessage(string.format("Received magnet joker: %s", MP.UTILS.joker_to_string(card)), "MULTIPLAYER")
end

function G.FUNCS.load_end_game_jokers()
	local card_area_save, success, err

	if not MP.end_game_jokers and not MP.end_game_jokers_payload then
		return
	end

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
			0,
			0,
			5 * G.CARD_W,
			G.CARD_H,
			{ card_limit = G.GAME.starting_params.joker_slots, type = "joker", highlight_limit = 1 }
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

local function action_receive_end_game_jokers(keys)
	MP.end_game_jokers_payload = keys
	MP.end_game_jokers_received = true
	G.FUNCS.load_end_game_jokers()
end

local function action_get_end_game_jokers()
	if not G.jokers or not G.jokers.cards then
		Client.send("action:receiveEndGameJokers,keys:")
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

	Client.send(string.format("action:receiveEndGameJokers,keys:%s", jokers_encoded))
end

local function action_get_nemesis_deck()
	local deck_str = ""
	for _, card in ipairs(G.playing_cards) do
		deck_str = deck_str .. ";" .. MP.UTILS.card_to_string(card)
	end
	Client.send(string.format("action:receiveNemesisDeck,cards:%s", deck_str))
end

local function action_send_game_stats()
	if not MP.GAME.stats then
		Client.send("action:nemesisEndGameStats")
		return
	end

	local stats_str = string.format(
		"reroll_count:%d,reroll_cost_total:%d",
		MP.GAME.stats.reroll_count,
		MP.GAME.stats.reroll_cost_total
	)

	-- Extract voucher keys where value is true and join them with a dash
	local voucher_keys = ""
	if G.GAME.used_vouchers then
		local keys = {}
		for k, v in pairs(G.GAME.used_vouchers) do
			if v == true then
				table.insert(keys, k)
			end
		end
		voucher_keys = table.concat(keys, "-")
	end

	-- Add voucher keys to stats string
	if voucher_keys ~= "" then
		stats_str = stats_str .. string.format(",vouchers:%s", voucher_keys)
	end

	Client.send(string.format("action:nemesisEndGameStats,%s", stats_str))
end

function G.FUNCS.load_nemesis_deck()
	if not MP.nemesis_deck or not MP.nemesis_cards or not MP.LOBBY.code then
		return
	end

	local card_strings = MP.UTILS.string_split(MP.nemesis_deck_string, ";")

	for k, _ in pairs(MP.nemesis_cards) do
		MP.nemesis_cards[k] = nil
	end

	for _, card_str in pairs(card_strings) do
		if card_str == "" then
			goto continue
		end

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
		if edition ~= "none" then
			card:set_edition({ [edition] = true }, true, true)
		end
		if seal ~= "none" then
			card:set_seal(seal, true, true)
		end

		-- Remove the card from G.playing_cards and insert into MP.nemesis_cards
		table.remove(G.playing_cards, #G.playing_cards)
		table.insert(MP.nemesis_cards, card)

		::continue::
	end
end

local function action_receive_nemesis_deck(deck_str)
	MP.nemesis_deck_string = deck_str
	MP.nemesis_deck_received = true
	G.FUNCS.load_nemesis_deck()
end

local function action_start_ante_timer(time)
	if type(time) == "string" then
		time = tonumber(time)
	end
	MP.GAME.timer = time
	MP.GAME.timer_started = true
	G.E_MANAGER:add_event(MP.timer_event)
end

local function action_pause_ante_timer(time)
	if type(time) == "string" then
		time = tonumber(time)
	end
	MP.GAME.timer = time
	MP.GAME.timer_started = false
end

-- #region Client to Server
function MP.ACTIONS.create_lobby(gamemode)
	Client.send(string.format("action:createLobby,gameMode:%s", gamemode))
end

function MP.ACTIONS.join_lobby(code)
	Client.send(string.format("action:joinLobby,code:%s", code))
end

function MP.ACTIONS.ready_lobby()
	Client.send("action:readyLobby")
end

function MP.ACTIONS.unready_lobby()
	Client.send("action:unreadyLobby")
end

function MP.ACTIONS.lobby_info()
	Client.send("action:lobbyInfo")
end

function MP.ACTIONS.leave_lobby()
	Client.send("action:leaveLobby")
end

function MP.ACTIONS.start_game()
	Client.send("action:startGame")
end

function MP.ACTIONS.ready_blind(e)
	MP.GAME.next_blind_context = e
	Client.send("action:readyBlind")
end

function MP.ACTIONS.unready_blind()
	Client.send("action:unreadyBlind")
end

function MP.ACTIONS.stop_game()
	Client.send("action:stopGame")
end

function MP.ACTIONS.fail_round(hands_used)
	if MP.LOBBY.config.no_gold_on_round_loss then
		G.GAME.blind.dollars = 0
	end
	if hands_used == 0 then
		return
	end
	Client.send("action:failRound")
end

function MP.ACTIONS.version()
	Client.send(string.format("action:version,version:%s", MULTIPLAYER_VERSION))
end

function MP.ACTIONS.set_location(location)
	if MP.GAME.location == location then
		return
	end
	MP.GAME.location = location
	Client.send(string.format("action:setLocation,location:%s", location))
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
	if MP.INSANE_INT.greater_than(insane_int_score, MP.GAME.highest_score) then
		MP.GAME.highest_score = insane_int_score
	end
	Client.send(string.format("action:playHand,score:" .. fixed_score .. ",handsLeft:%d", hands_left))
end

function MP.ACTIONS.lobby_options()
	local msg = "action:lobbyOptions"
	for k, v in pairs(MP.LOBBY.config) do
		msg = msg .. string.format(",%s:%s", k, tostring(v))
	end
	Client.send(msg)
end

function MP.ACTIONS.set_ante(ante)
	Client.send(string.format("action:setAnte,ante:%d", ante))
end

function MP.ACTIONS.new_round()
	Client.send("action:newRound")
end

function MP.ACTIONS.set_furthest_blind(furthest_blind)
	Client.send(string.format("action:setFurthestBlind,furthestBlind:%d", furthest_blind))
end

function MP.ACTIONS.skip(skips)
	Client.send("action:skip,skips:" .. tostring(skips))
end

function MP.ACTIONS.send_phantom(key)
	Client.send("action:sendPhantom,key:" .. key)
end

function MP.ACTIONS.remove_phantom(key)
	Client.send("action:removePhantom,key:" .. key)
end

function MP.ACTIONS.asteroid()
	Client.send("action:asteroid")
end

function MP.ACTIONS.sold_joker()
	Client.send("action:soldJoker")
end

function MP.ACTIONS.lets_go_gambling_nemesis()
	Client.send("action:letsGoGamblingNemesis")
end

function MP.ACTIONS.eat_pizza(discards)
	Client.send("action:eatPizza,whole:" .. tostring(discards))
end

function MP.ACTIONS.spent_last_shop(amount)
	Client.send("action:spentLastShop,amount:" .. tostring(amount))
end

function MP.ACTIONS.magnet()
	Client.send("action:magnet")
end

function MP.ACTIONS.magnet_response(key)
	Client.send("action:magnetResponse,key:" .. key)
end

function MP.ACTIONS.get_end_game_jokers()
	Client.send("action:getEndGameJokers")
end

function MP.ACTIONS.get_nemesis_deck()
	Client.send("action:getNemesisDeck")
end

function MP.ACTIONS.send_game_stats()
	Client.send("action:sendGameStats")
	action_send_game_stats()
end

function MP.ACTIONS.request_nemesis_stats()
	Client.send("action:endGameStatsRequested")
end

function MP.ACTIONS.start_ante_timer()
	Client.send("action:startAnteTimer,time:" .. tostring(MP.GAME.timer))
	action_start_ante_timer(MP.GAME.timer)
end

function MP.ACTIONS.pause_ante_timer()
	Client.send("action:pauseAnteTimer,time:" .. tostring(MP.GAME.timer))
	action_pause_ante_timer(MP.GAME.timer) -- TODO
end

function MP.ACTIONS.fail_timer()
	Client.send("action:failTimer")
end

function MP.ACTIONS.sync_client()
	Client.send("action:syncClient,isCached:" .. tostring(_RELEASE_MODE))
end

-- #endregion Client to Server

-- Utils
function MP.ACTIONS.connect()
	Client.send("connect")
end

function MP.ACTIONS.update_player_usernames()
	if MP.LOBBY.code then
		if G.MAIN_MENU_UI then
			G.MAIN_MENU_UI:remove()
		end
		set_main_menu_UI()
	end
end

local function string_to_table(str)
	local tbl = {}
	for part in string.gmatch(str, "([^,]+)") do
		local key, value = string.match(part, "([^:]+):(.+)")
		if key and value then
			tbl[key] = value
		end
	end
	return tbl
end

local last_game_seed = nil

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	game_update_ref(self, dt)

	repeat
		local msg = love.thread.getChannel("networkToUi"):pop()
		if msg then
			local parsedAction = string_to_table(msg)

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

			if parsedAction.action == "connected" then
				action_connected()
			elseif parsedAction.action == "version" then
				action_version()
			elseif parsedAction.action == "disconnected" then
				action_disconnected()
			elseif parsedAction.action == "joinedLobby" then
				action_joinedLobby(parsedAction.code, parsedAction.type)
			elseif parsedAction.action == "lobbyInfo" then
				action_lobbyInfo(
					parsedAction.host,
					parsedAction.hostHash,
					parsedAction.hostCached,
					parsedAction.guest,
					parsedAction.guestHash,
					parsedAction.guestCached,
					parsedAction.guestReady,
					parsedAction.isHost
				)
			elseif parsedAction.action == "startGame" then
				action_start_game(parsedAction.seed, parsedAction.stake)
			elseif parsedAction.action == "startBlind" then
				action_start_blind()
			elseif parsedAction.action == "enemyInfo" then
				action_enemy_info(parsedAction.score, parsedAction.handsLeft, parsedAction.skips, parsedAction.lives)
			elseif parsedAction.action == "stopGame" then
				action_stop_game()
			elseif parsedAction.action == "endPvP" then
				action_end_pvp()
			elseif parsedAction.action == "playerInfo" then
				action_player_info(parsedAction.lives)
			elseif parsedAction.action == "winGame" then
				action_win_game()
			elseif parsedAction.action == "loseGame" then
				action_lose_game()
			elseif parsedAction.action == "lobbyOptions" then
				action_lobby_options(parsedAction)
			elseif parsedAction.action == "enemyLocation" then
				enemyLocation(parsedAction)
			elseif parsedAction.action == "sendPhantom" then
				action_send_phantom(parsedAction.key)
			elseif parsedAction.action == "removePhantom" then
				action_remove_phantom(parsedAction.key)
			elseif parsedAction.action == "speedrun" then
				action_speedrun()
			elseif parsedAction.action == "asteroid" then
				action_asteroid()
			elseif parsedAction.action == "soldJoker" then
				action_sold_joker()
			elseif parsedAction.action == "letsGoGamblingNemesis" then
				action_lets_go_gambling_nemesis()
			elseif parsedAction.action == "eatPizza" then
				action_eat_pizza(parsedAction.whole) -- rename to "discards" when possible
			elseif parsedAction.action == "spentLastShop" then
				action_spent_last_shop(parsedAction.amount)
			elseif parsedAction.action == "magnet" then
				action_magnet()
			elseif parsedAction.action == "magnetResponse" then
				action_magnet_response(parsedAction.key)
			elseif parsedAction.action == "getEndGameJokers" then
				action_get_end_game_jokers()
			elseif parsedAction.action == "receiveEndGameJokers" then
				action_receive_end_game_jokers(parsedAction.keys)
			elseif parsedAction.action == "getNemesisDeck" then
				action_get_nemesis_deck()
			elseif parsedAction.action == "receiveNemesisDeck" then
				action_receive_nemesis_deck(parsedAction.cards)
			elseif parsedAction.action == "endGameStatsRequested" then
				action_send_game_stats()
			elseif parsedAction.action == "nemesisEndGameStats" then
				-- Handle receiving game stats (is only logged now, now shown in the ui)
			elseif parsedAction.action == "startAnteTimer" then
				action_start_ante_timer(parsedAction.time)
			elseif parsedAction.action == "pauseAnteTimer" then
				action_pause_ante_timer(parsedAction.time)
			elseif parsedAction.action == "error" then
				action_error(parsedAction.message)
			elseif parsedAction.action == "keepAlive" then
				action_keep_alive()
			end
		end
	until not msg
end
