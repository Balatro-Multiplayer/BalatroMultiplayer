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
		Client.send(string.format("action:username,username:%s,modHash:%s", MP.LOBBY.username, MP.MOD_STRING))
	end
end

local function action_connected()
	MP.LOBBY.connected = true
	MP.UI.update_connection_status()
	Client.send(string.format("action:username,username:%s,modHash:%s", MP.LOBBY.username, MP.MOD_STRING))
end

local function action_joinedLobby(code, type)
	MP.LOBBY.code = code
	MP.LOBBY.type = type
	MP.ACTIONS.lobby_info()
	MP.UI.update_connection_status()
end

local function action_lobbyInfo(host, hostHash, guest, guestHash, is_host)
	MP.LOBBY.players = {}
	MP.LOBBY.is_host = is_host == "true"
	MP.LOBBY.host = { username = host, hash_str = hostHash, hash = hash(hostHash) }
	if guest ~= nil then
		MP.LOBBY.guest = { username = guest, hash_str = guestHash, hash = hash(guestHash) }
	else
		MP.LOBBY.guest = {}
	end
	-- TODO: This should check for player count instead
	-- once we enable more than 2 players
	MP.LOBBY.ready_to_start = MP.LOBBY.is_host and guest ~= nil

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
end

local function action_start_blind()
	MP.GAME.ready_blind = false
	MP.GAME.timer_started = false
	MP.GAME.timer = 120
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
	local score = tonumber(score_str)
	local hands_left = tonumber(hands_left_str)
	local skips = tonumber(skips_str)
	local lives = tonumber(lives_str)

	if score == nil or hands_left == nil then
		sendDebugMessage("Invalid score or hands_left", "MULTIPLAYER")
		return
	end

	if MP.GAME.enemy.highest_score < score then
		MP.GAME.enemy.highest_score = score
	end

	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "ease",
		delay = 3,
		ref_table = MP.GAME.enemy,
		ref_value = "score",
		ease_to = score,
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
	MP.GAME.timer = 120
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
	end
	MP.GAME.lives = lives
end

local function action_win_game()
	win_game()
	MP.GAME.won = true
end

local function action_lose_game()
	G.STATE_COMPLETE = false
	G.STATE = G.STATES.GAME_OVER
end

local function action_lobby_options(options)
	local different_decks_before = MP.LOBBY.config.different_decks
	for k, v in pairs(options) do
		if k == "ruleset" then
			MP.LOBBY.config.ruleset = v
			goto continue
		end
		local parsed_v = v
		if v == "true" then
			parsed_v = true
		elseif v == "false" then
			parsed_v = false
		end
		if k == "starting_lives" then
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
	local new_card = create_card("Joker", MP.shared, false, nil, nil, nil, key)
	new_card:set_edition("e_mp_phantom")
	new_card:add_to_deck()
	MP.shared:emplace(new_card)
end

local function action_remove_phantom(key)
	local card = MP.UTILS.get_phantom_joker(key)
	if card then
		card:remove_from_deck()
		card:start_dissolve({ G.C.RED }, nil, 1.6)
		MP.shared:remove_card(card)
	end
end

local function action_speedrun()
	local function speedrun(card)
		card:juice_up()
		if #G.consumeables.cards < G.consumeables.config.card_limit then
			local card = create_card("Spectral", G.consumeables, nil, nil, nil, nil, nil, "speedrun")
			card:add_to_deck()
			G.consumeables:emplace(card)
		end
	end
	MP.UTILS.run_for_each_joker("j_mp_speedrun", speedrun)
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

local function action_sold_joker()
	local function juice_taxes(card)
		if card then
			card.ability.extra.mult = card.ability.extra.mult_gain + card.ability.extra.mult
			card:juice_up()
		end
	end
	MP.UTILS.run_for_each_joker("j_mp_taxes", juice_taxes)
end

local function action_lets_go_gambling_nemesis()
	local card = MP.UTILS.get_phantom_joker("j_mp_lets_go_gambling")
	if card then
		card:juice_up()
	end
	ease_dollars(card and card.ability and card.ability.extra and card.ability.extra.nemesis_dollars or 5)
end

local function action_eat_pizza(whole)
	local function eat_whole(card)
		card:remove_from_deck()
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.2,
			func = function()
				attention_text({
					text = localize("k_eaten_ex"),
					scale = 0.6,
					hold = 1.4,
					major = card,
					backdrop_colour = G.C.FILTER,
					align = "bm",
					offset = {
						x = 0,
						y = 0,
					},
				})
				card:start_dissolve({ G.C.RED }, nil, 1.6)
				return true
			end,
		}))
	end

	whole = whole == "true"
	local card = MP.UTILS.get_joker("j_mp_pizza") or MP.UTILS.get_phantom_joker("j_mp_pizza")
	if card then
		if whole then
			eat_whole(card)
			return
		end
		card:juice_up()
		card.ability.extra.discards = card.ability.extra.discards - card.ability.extra.discards_loss
		if card.ability.extra.discards <= 0 then
			eat_whole(card)
			return
		end
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.2,
			func = function()
				attention_text({
					text = localize({
						type = "variable",
						key = "a_remaining",
						vars = { card.ability.extra.discards },
					}),
					scale = 0.6,
					hold = 1.4,
					major = card,
					backdrop_colour = G.C.RED,
					align = "bm",
					offset = {
						x = 0,
						y = 0,
					},
				})
				return true
			end,
		}))
	end
end

local function action_spent_last_shop(amount)
	MP.GAME.enemy.spent_last_shop = tonumber(amount)
end

local function action_magnet()
	local card = nil
	for _, v in pairs(G.jokers.cards) do
		if not card or v.sell_cost > card.sell_cost then
			card = v
		end
	end
	if card then
		MP.ACTIONS.magnet_response(card.config.center.key)
	end
end

local function action_magnet_response(key)
	local card = create_card("Joker", G.jokers, false, nil, nil, nil, key)
	card:add_to_deck()
	G.jokers:emplace(card)
end

local function action_receive_end_game_jokers(keys)
	if not MP.end_game_jokers then
		return
	end
	local split_keys = {}
	for key in string.gmatch(keys, "([^;]+)") do
		table.insert(split_keys, key)
	end
	for _, key in pairs(split_keys) do
		local card = create_card("Joker", MP.end_game_jokers, false, nil, nil, nil, key)
		card:set_edition()
		card:add_to_deck()
		MP.end_game_jokers:emplace(card)
	end
end

local function action_get_end_game_jokers()
	if not G.jokers or not G.jokers.cards then
		Client.send("action:receiveEndGameJokers,keys:")
		return
	end
	local jokers = G.jokers.cards
	local keys = ""
	for _, card in pairs(jokers) do
		keys = keys .. card.config.center.key .. ";"
	end
	Client.send(string.format("action:receiveEndGameJokers,keys:%s", keys))
end

local function action_start_ante_timer(time)
	if type(time) == "string" then
		time = tonumber(time)
	end
	MP.GAME.timer = time
	MP.GAME.timer_started = true
	G.E_MANAGER:add_event(MP.timer_event)
end

-- #region Client to Server
function MP.ACTIONS.create_lobby(gamemode)
	MP.LOBBY.config.ruleset = gamemode
	Client.send(string.format("action:createLobby,gameMode:%s", gamemode))
end

function MP.ACTIONS.join_lobby(code)
	Client.send(string.format("action:joinLobby,code:%s", code))
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
		MP.GAME.blind.dollars = 0
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
	if score > MP.GAME.highest_score then
		MP.GAME.highest_score = score
	end
	local fixed_score = tostring(to_big(score))
	-- Credit to sidmeierscivilizationv on discord for this fix for Talisman
	if string.match(fixed_score, "[eE]") == nil and string.match(fixed_score, "[.]") then
		-- Remove decimal from non-exponential numbers
		fixed_score = string.sub(string.gsub(fixed_score, "%.", ","), 1, -3)
	end
	fixed_score = string.gsub(fixed_score, ",", "") -- Remove commas
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

function MP.ACTIONS.eat_pizza(whole)
	Client.send("action:eatPizza,whole:" .. tostring(whole and true))
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

function MP.ACTIONS.start_ante_timer()
	Client.send("action:startAnteTimer,time:" .. tostring(MP.GAME.timer))
	action_start_ante_timer(MP.GAME.timer)
end

function MP.ACTIONS.fail_timer()
	Client.send("action:failTimer")
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
				action_eat_pizza(parsedAction.whole)
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
			elseif parsedAction.action == "startAnteTimer" then
				action_start_ante_timer(parsedAction.time)
			elseif parsedAction.action == "error" then
				action_error(parsedAction.message)
			elseif parsedAction.action == "keepAlive" then
				action_keep_alive()
			end
		end
	until not msg
end
