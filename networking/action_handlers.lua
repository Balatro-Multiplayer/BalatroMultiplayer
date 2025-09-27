local json = require "json"

-- #region Message Handlers

function action_player_list_update(data)
    MP.LOBBY.players = data.players or {}
    MP.LOBBY.host_id = data.host_id
    MP.LOBBY.is_host = (MP.LOBBY.host_id == G.SETTINGS.steam_id)

    local all_ready = true
    if #MP.LOBBY.players < (MP.max_players or 3) then
        all_ready = false
    end

    for _, player in ipairs(MP.LOBBY.players) do
        if player.state ~= "ready" then
            all_ready = false
            break
        end
    end
    MP.LOBBY.ready_to_start = all_ready

    if G.STAGE == G.STAGES.MAIN_MENU then
        MP.ACTIONS.update_player_usernames()
    end
end

function action_start_game(seed, stake_str)
	MP.reset_game_states()
	local stake = tonumber(stake_str)
	if not MP.LOBBY.config.different_seeds and MP.LOBBY.config.custom_seed ~= "random" then
		seed = MP.LOBBY.config.custom_seed
	end
	G.FUNCS.lobby_start_run(nil, { seed = seed, stake = stake })
	MP.LOBBY.ready_to_start = false
end

function action_game_state_update(data)
    local sender_id = data.sender_id
    if not sender_id or sender_id == G.SETTINGS.steam_id then return end

    if not MP.GAME.enemies[sender_id] then
        local name = "Opponent"
        for _, p in ipairs(MP.LOBBY.players) do if p.id == sender_id then name = p.name; break; end end
        MP.GAME.enemies[sender_id] = {
            username = name,
            score = MP.INSANE_INT.empty(),
            hands = 4,
            lives = MP.LOBBY.config.starting_lives,
        }
    end

    local enemy_state = MP.GAME.enemies[sender_id]
    local state_data = data.state
    if not state_data then return end

    local score = MP.INSANE_INT.from_string(tostring(state_data.score or '0'))
    enemy_state.hands = tonumber(state_data.hands) or enemy_state.hands
    enemy_state.lives = tonumber(state_data.lives) or enemy_state.lives

    G.E_MANAGER:add_event(Event({ trigger = "ease", delay = 0.1, ref_table = enemy_state.score, ref_value = "e_count", ease_to = score.e_count, func = function(t) return math.floor(t) end }))
    G.E_MANAGER:add_event(Event({ trigger = "ease", delay = 0.1, ref_table = enemy_state.score, ref_value = "coeffiocient", ease_to = score.coeffiocient, func = function(t) return math.floor(t) end }))
    G.E_MANAGER:add_event(Event({ trigger = "ease", delay = 0.1, ref_table = enemy_state.score, ref_value = "exponent", ease_to = score.exponent, func = function(t) return math.floor(t) end }))
end

function action_stop_game()
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		G.FUNCS.go_to_menu()
		MP.reset_game_states()
	end
end

function action_win_game()
	MP.GAME.won = true
	win_game()
end

function action_lose_game()
	G.STATE_COMPLETE = false
	G.STATE = G.STATES.GAME_OVER
end

-- #endregion

-- #region P2P Senders

function MP.P2P_send_to_host(msg, reliable)
    local steamworks = G.STEAM.I
    if MP.LOBBY.is_host then
        G.E_MANAGER:add_event(Event({
            func = function()
                handle_message_from_client(G.SETTINGS.steam_id, msg)
                return true
            end,
        }))
        return
    end
    if not steamworks or not MP.LOBBY.host_id then return end
    steamworks:send_p2p_message(MP.LOBBY.host_id, json.encode(msg), reliable and "reliable" or "unreliable_no_delay")
end

function MP.ACTIONS.send_game_state()
    local fixed_score = tostring(to_big(G.GAME.round_stats.score or 0))
    if string.match(fixed_score, "[eE]") == nil and string.match(fixed_score, "[.]") then
        fixed_score = string.sub(string.gsub(fixed_score, "%.", ","), 1, -3)
    end
    fixed_score = string.gsub(fixed_score, ",", "")

    MP.P2P_send_to_host({
        type = "game_state",
        state = { score = fixed_score, hands = G.GAME.hands, lives = MP.GAME.lives }
    }, false)
end

MP.ACTIONS.play_hand = MP.ACTIONS.send_game_state
MP.ACTIONS.ready_lobby = function() MP.P2P_send_to_host({ type = "ready" }, true) end
MP.ACTIONS.ante_up = function() MP.P2P_send_to_host({ type = "ante_up" }, true) end
MP.ACTIONS.next_round = function(blind, from_blind_select) MP.P2P_send_to_host({ type = "next_round", blind = blind, from_blind_select = from_blind_select }, true) end
MP.ACTIONS.stop_game = function() MP.P2P_send_to_host({ type = "stop_game" }, true) end
MP.ACTIONS.fail_round = function() MP.P2P_send_to_host({ type = "fail_round" }, true) end
MP.ACTIONS.game_over = function(winner_id) MP.P2P_send_to_host({ type = "game_over", winner = winner_id }, true) end

-- #endregion

function MP.ACTIONS.update_player_usernames()
	if G.MAIN_MENU_UI then G.MAIN_MENU_UI:remove() end
	set_main_menu_UI()
end

local game_update_ref = Game.update
function Game:update(dt)
	game_update_ref(self, dt)

	if MP.LOBBY.is_host and MP.SERVER and MP.SERVER.update then
		MP.SERVER.update(dt)
	end

	local steamworks = G.STEAM.I
	if not steamworks then return end

	local msg_size, steam_id = steamworks:is_p2p_packet_available(0)
	while msg_size > 0 do
		local msg = steamworks:read_p2p_message(msg_size, 0)
		local parsedAction, err = json.decode(msg)

		if parsedAction then
            if parsedAction.type ~= "player_list_update" and parsedAction.sender_id ~= MP.LOBBY.host_id and not MP.LOBBY.is_host then
                -- Ignore messages not from the host
            else
			    if parsedAction.type == "player_list_update" then action_player_list_update(parsedAction)
			    elseif parsedAction.type == "start_game" then action_start_game(parsedAction.seed, parsedAction.stake)
			    elseif parsedAction.type == "game_state" then action_game_state_update(parsedAction)
                elseif parsedAction.type == "next_round" then G.GAME.FUNCS.next_round(parsedAction.blind, parsedAction.from_blind_select)
                elseif parsedAction.type == "ante_up" then G.GAME.FUNCS.ante_up()
                elseif parsedAction.type == "stop_game" then action_stop_game()
                elseif parsedAction.type == "fail_round" then G.GAME.FUNCS.lose_round()
                elseif parsedAction.type == "game_over" then
                    if parsedAction.winner == G.SETTINGS.steam_id then action_win_game() else action_lose_game() end
			    end
            end
		end
		msg_size, steam_id = steamworks:is_p2p_packet_available(0)
	end
end