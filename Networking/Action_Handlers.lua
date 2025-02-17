Client = {}

function Client.send(msg)
	if not (msg == "action:keepAliveAck") then
		sendTraceMessage(string.format("Client sent message: %s", msg), "MULTIPLAYER")
	end
	love.thread.getChannel("uiToNetwork"):push(msg)
end

-- Server to Client
function G.MULTIPLAYER.set_username(username)
	G.LOBBY.username = username or "Guest"
	if G.LOBBY.connected then
		Client.send(string.format("action:username,username:%s,modHash:%s", G.LOBBY.username, G.MULTIPLAYER.MOD_STRING))
	end
end

local function action_connected()
	G.LOBBY.connected = true
	G.MULTIPLAYER.update_connection_status()
	Client.send(string.format("action:username,username:%s,modHash:%s", G.LOBBY.username, G.MULTIPLAYER.MOD_STRING))
end

local function action_joinedLobby(code, type)
	G.LOBBY.code = code
	G.LOBBY.type = type
	reset_gamemode_modifiers()
	G.MULTIPLAYER.lobby_info()
	G.MULTIPLAYER.update_connection_status()
end

local function action_lobbyInfo(host, hostHash, guest, guestHash, is_host)
	G.LOBBY.players = {}
	G.LOBBY.is_host = is_host == "true"
	G.LOBBY.host = { username = host, hash_str = hostHash, hash = hash(hostHash) }
	if guest ~= nil then
		G.LOBBY.guest = { username = guest, hash_str = guestHash, hash = hash(guestHash) }
	else
		G.LOBBY.guest = {}
	end
	-- TODO: This should check for player count instead
	-- once we enable more than 2 players
	G.LOBBY.ready_to_start = G.LOBBY.is_host and guest ~= nil

	if G.LOBBY.is_host then
		G.MULTIPLAYER.lobby_options()
	end

	if G.STAGE == G.STAGES.MAIN_MENU then
		G.MULTIPLAYER.update_player_usernames()
	end
end

local function action_error(message)
	sendWarnMessage(message, "MULTIPLAYER")

	G.MULTIPLAYER.UTILS.overlay_message(message)
end

local function action_keep_alive()
	Client.send("action:keepAliveAck")
end

local function action_disconnected()
	G.LOBBY.connected = false
	if G.LOBBY.code then
		G.LOBBY.code = nil
	end
	G.MULTIPLAYER.update_connection_status()
end

---@param deck string
---@param seed string
---@param stake_str string
local function action_start_game(deck, seed, stake_str)
	reset_game_states()
	local stake = tonumber(stake_str)
	G.MULTIPLAYER.set_ante(0)
	if not G.LOBBY.config.different_seeds and G.LOBBY.config.custom_seed ~= "random" then
		seed = G.LOBBY.config.custom_seed
	end
	G.FUNCS.lobby_start_run(nil, { deck = deck, seed = seed, stake = stake })
end

local function action_start_blind()
	G.MULTIPLAYER_GAME.ready_blind = false
	if G.MULTIPLAYER_GAME.next_blind_context then
		G.FUNCS.select_blind(G.MULTIPLAYER_GAME.next_blind_context)
	else
		sendErrorMessage("No next blind context", "MULTIPLAYER")
	end
end

---@param score_str string
---@param hands_left_str string
---@param skips_str string
local function action_enemy_info(score_str, hands_left_str, skips_str)
	local score = tonumber(score_str)
	local hands_left = tonumber(hands_left_str)
	local skips = tonumber(skips_str)

	if score == nil or hands_left == nil then
		sendDebugMessage("Invalid score or hands_left", "MULTIPLAYER")
		return
	end

	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "ease",
		delay = 3,
		ref_table = G.MULTIPLAYER_GAME.enemy,
		ref_value = "score",
		ease_to = score,
		func = function(t)
			return math.floor(t)
		end,
	}))

	G.MULTIPLAYER_GAME.enemy.hands = hands_left
	G.MULTIPLAYER_GAME.enemy.skips = skips

	if is_pvp_boss() then
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count"):juice_up()
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned"):juice_up()
	end
end

local function action_stop_game()
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		G.FUNCS.go_to_menu()
		G.MULTIPLAYER.update_connection_status()
		reset_game_states()
	end
end

local function action_end_pvp()
	G.MULTIPLAYER_GAME.end_pvp = true
end

---@param lives number
local function action_player_info(lives)
	if G.MULTIPLAYER_GAME.lives ~= lives then
		if G.MULTIPLAYER_GAME.lives ~= 0 and G.LOBBY.config.gold_on_life_loss then
			G.MULTIPLAYER_GAME.comeback_bonus_given = false
			G.MULTIPLAYER_GAME.comeback_bonus = G.MULTIPLAYER_GAME.comeback_bonus + 1
		end
		ease_lives(lives - G.MULTIPLAYER_GAME.lives)
	end
	G.MULTIPLAYER_GAME.lives = lives
end

local function action_win_game()
	win_game()
	G.GAME.won = true
end

local function action_lose_game()
	G.STATE_COMPLETE = false
	G.STATE = G.STATES.GAME_OVER
end

local function action_lobby_options(options)
	local different_decks_before = G.LOBBY.config.different_decks
	for k, v in pairs(options) do
		if k == "gamemode" then
			G.LOBBY.config.gamemode = v
			goto continue
		end
		local parsed_v = v
		if v == "true" then
			parsed_v = true
		elseif v == "false" then
			parsed_v = false
		end
		if k == "starting_lives" or k == "showdown_starting_antes" then
			parsed_v = tonumber(v)
		end
		G.LOBBY.config[k] = parsed_v
		if G.OVERLAY_MENU then
			local config_uie = G.OVERLAY_MENU:get_UIE_by_ID(k .. "_toggle")
			if config_uie then
				G.FUNCS.toggle(config_uie)
			end
		end
		::continue::
	end
	if different_decks_before ~= G.LOBBY.config.different_decks then
		G.FUNCS.exit_overlay_menu() -- throw out guest from any menu.
	end
	G.MULTIPLAYER.update_player_usernames() -- render new DECK button state
end

local function action_send_phantom(key)
	local new_card = create_card("Joker", G.jokers, false, nil, nil, nil, key)
	new_card:set_edition("e_mp_phantom")
	new_card:add_to_deck()
	G.jokers:emplace(new_card)
end

local function action_remove_phantom(key)
	local card = G.MULTIPLAYER.UTILS.get_joker(key)
	if card then
		card:remove_from_deck()
		card:start_dissolve({ G.C.RED }, nil, 1.6)
		G.jokers:remove_card(card)
	end
end

local function action_speedrun()
	local card = G.MULTIPLAYER.UTILS.get_joker("j_mp_speedrun")
	if card then
		card:juice_up()
		G.GAME.chips = to_big(G.GAME.chips) * to_big(3)
	end
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

	G.MULTIPLAYER_GAME.enemy.location = loc_location .. value
end

local function action_version()
	G.MULTIPLAYER.version()
end

local function action_asteroid()
	local hand_type = "High Card"
	local max_level = 0
	for k, v in pairs(G.GAME.hands) do
		if to_big(v.level) > to_big(max_level) then
			hand_type = k
			max_level = v.level
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

-- #region Client to Server
function G.MULTIPLAYER.create_lobby(gamemode)
	G.LOBBY.config.gamemode = gamemode
	Client.send(string.format("action:createLobby,gameMode:%s", gamemode))
end

function G.MULTIPLAYER.join_lobby(code)
	Client.send(string.format("action:joinLobby,code:%s", code))
end

function G.MULTIPLAYER.lobby_info()
	Client.send("action:lobbyInfo")
end

function G.MULTIPLAYER.leave_lobby()
	Client.send("action:leaveLobby")
end

function G.MULTIPLAYER.start_game()
	Client.send("action:startGame")
end

function G.MULTIPLAYER.ready_blind(e)
	G.MULTIPLAYER_GAME.next_blind_context = e
	Client.send("action:readyBlind")
end

function G.MULTIPLAYER.unready_blind()
	Client.send("action:unreadyBlind")
end

function G.MULTIPLAYER.stop_game()
	Client.send("action:stopGame")
end

function G.MULTIPLAYER.fail_round(hands_used)
	if G.LOBBY.config.no_gold_on_round_loss then
		G.GAME.blind.dollars = 0
	end
	if hands_used == 0 then
		return
	end
	Client.send("action:failRound")
end

function G.MULTIPLAYER.version()
	Client.send(string.format("action:version,version:%s", MULTIPLAYER_VERSION))
end

function G.MULTIPLAYER.set_location(location)
	if G.MULTIPLAYER_GAME.location == location then
		return
	end
	G.MULTIPLAYER_GAME.location = location
	Client.send(string.format("action:setLocation,location:%s", location))
end

---@param score number
---@param hands_left number
function G.MULTIPLAYER.play_hand(score, hands_left, speedrun_check)
	speedrun_check = speedrun_check or false
	local fixed_score = tostring(to_big(score))
	-- Credit to sidmeierscivilizationv on discord for this fix for Talisman
	if string.match(fixed_score, "[eE]") == nil and string.match(fixed_score, "[.]") then
		-- Remove decimal from non-exponential numbers
		fixed_score = string.sub(string.gsub(fixed_score, "%.", ","), 1, -3)
	end
	fixed_score = string.gsub(fixed_score, ",", "") -- Remove commas
	Client.send(
		string.format(
			"action:playHand,score:" .. fixed_score .. ",handsLeft:%d,hasSpeedrun:" .. tostring(speedrun_check),
			hands_left
		)
	)
end

function G.MULTIPLAYER.lobby_options()
	local msg = "action:lobbyOptions"
	for k, v in pairs(G.LOBBY.config) do
		msg = msg .. string.format(",%s:%s", k, tostring(v))
	end
	Client.send(msg)
end

function G.MULTIPLAYER.set_ante(ante)
	Client.send(string.format("action:setAnte,ante:%d", ante))
end

function G.MULTIPLAYER.new_round()
	Client.send("action:newRound")
end

function G.MULTIPLAYER.skip(skips)
	Client.send("action:skip,skips:" .. tostring(skips))
end

function G.MULTIPLAYER.send_phantom(key)
	Client.send("action:sendPhantom,key:" .. key)
end

function G.MULTIPLAYER.remove_phantom(key)
	Client.send("action:removePhantom,key:" .. key)
end

function G.MULTIPLAYER.asteroid()
	Client.send("action:asteroid")
end
-- #endregion Client to Server

-- Utils
function G.MULTIPLAYER.connect()
	Client.send("connect")
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
					log = log .. string.format(" (%s: %s) ", k, v)
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
					parsedAction.guest,
					parsedAction.guestHash,
					parsedAction.isHost
				)
			elseif parsedAction.action == "startGame" then
				action_start_game(parsedAction.deck, parsedAction.seed, parsedAction.stake)
			elseif parsedAction.action == "startBlind" then
				action_start_blind()
			elseif parsedAction.action == "enemyInfo" then
				action_enemy_info(parsedAction.score, parsedAction.handsLeft, parsedAction.skips)
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
			elseif parsedAction.action == "error" then
				action_error(parsedAction.message)
			elseif parsedAction.action == "keepAlive" then
				action_keep_alive()
			end
		end
	until not msg
end
