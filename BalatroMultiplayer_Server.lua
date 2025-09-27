-- BALATRO MULTIPLAYER (SERVER)
--[[
    Made with love by @lorenz-s
]]

local steamworks = G.STEAM.I
local lobby_id
local players_ingame = {}

local function send_to_all(msg, reliable)
    for k, v in pairs(players_ingame) do
        if v.id then steamworks:send_p2p_message(v.id, msg, reliable and "reliable" or "unreliable_no_delay") end
    end
end

local function send_to_all_except(except_id, msg, reliable)
    for k, v in pairs(players_ingame) do
        if v.id and v.id ~= except_id then steamworks:send_p2p_message(v.id, msg, reliable and "reliable" or "unreliable_no_delay") end
    end
end

local function send_to_one(id, msg, reliable)
    steamworks:send_p2p_message(id, msg, reliable and "reliable" or "unreliable_no_delay")
end

local function lobby_initialised_callback()
    G.FUNCS.start_game()
end

local function p2p_session_request_callback(request)
    for k, v in pairs(players_ingame) do
        if v.id and v.id == request.steam_id_remote then
            steamworks:accept_p2p_session_with_user(request.steam_id_remote)
            return
        end
    end
end

local function lobby_chat_update_callback(update)
    if update.steam_id_user_changed == G.SETTINGS.steam_id and update.chat_member_state_change == "entered" then
        players_ingame = {}
        local num_lobby_members = steamworks:get_num_lobby_members(update.steam_id_lobby)
        for i=1, num_lobby_members do
            local member_steam_id = steamworks:get_lobby_member_by_index(update.steam_id_lobby, i-1)
            players_ingame[#players_ingame+1] = {
                id = member_steam_id,
                name = steamworks:get_friend_persona_name(member_steam_id),
                state = "connected"
            }
        end

        local msg = {
            type = "player_list_update",
            players = {}
        }
        for k, v in pairs(players_ingame) do
            msg.players[#msg.players+1] = {
                id = v.id,
                name = v.name,
                state = v.state
            }
        end
        send_to_all(json.encode(msg), true)
    end
end

local function lobby_created_callback(result)
    if result.connect == "ok" and result.lobby_steam_id then
        lobby_id = result.lobby_steam_id
        steamworks:set_lobby_joinable(lobby_id, true)
        G.STATE_STACK:get_from_top().custom_data.lobby_id = lobby_id
        G.STATE_STACK:get_from_top().custom_data.initialised_callback = lobby_initialised_callback
        G.STEAM.request_lobby_list(nil, function(lobbies)
            for k, v in pairs(lobbies) do
                if v.id == lobby_id then
                    G.STATE_STACK:get_from_top().custom_data.lobby_name = v.name
                    break
                end
            end
        end)
    end
end

local function handle_message_from_client(steam_id, msg_decoded)
    if not players_ingame then return end

    if msg_decoded.type == "ready" then
        local all_ready = true
        for k, v in pairs(players_ingame) do
            if v.id == steam_id then
                v.state = "ready"
            end
        end
        for k, v in pairs(players_ingame) do
            if v.state ~= "ready" then
                all_ready = false
            end
        end

        if all_ready then
            local msg = {
                type = "start_game",
                blind = G.GAME.round_resets.blind,
                stake = G.GAME.stake,
                seed = G.GAME.starting_params.seed
            }
            send_to_all(json.encode(msg), true)
            G.FUNCS.start_run()
        else
            local msg = {
                type = "player_list_update",
                players = {}
            }
            for k, v in pairs(players_ingame) do
                msg.players[#msg.players+1] = {
                    id = v.id,
                    name = v.name,
                    state = v.state
                }
            end
            send_to_all(json.encode(msg), true)
        end
    elseif msg_decoded.type == "game_state" then
        if msg_decoded.state.game_end then
            local winner = msg_decoded.state.game_end.winner
            local msg = {
                type = "game_over",
                winner = winner
            }
            send_to_all(json.encode(msg), true)
            return
        end

        msg_decoded.sender_id = steam_id
        send_to_all_except(steam_id, json.encode(msg_decoded), false)
    elseif msg_decoded.type == "ante_up" then
        local msg = {
            type = "ante_up"
        }
        send_to_all_except(steam_id, json.encode(msg), true)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.FUNCS.ante_up()
                return true
            end
        }))
    elseif msg_decoded.type == "next_round" then
        local msg = {
            type = "next_round",
            blind = msg_decoded.blind,
            from_blind_select = msg_decoded.from_blind_select
        }
        send_to_all_except(steam_id, json.encode(msg), true)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.FUNCS.next_round(msg_decoded.blind, msg_decoded.from_blind_select)
                return true
            end
        }))
    end
end

local function init_server(player_count)
    steamworks:create_lobby("public", player_count, lobby_created_callback)
    steamworks:register_callback("p2p_session_request", p2p_session_request_callback)
    steamworks:register_callback("lobby_chat_update", lobby_chat_update_callback)
end

local function update(dt)
    local msg_size, steam_id = steamworks:is_p2p_packet_available(0)
    while msg_size > 0 do
        local msg = steamworks:read_p2p_message(msg_size, 0)
        local msg_decoded = json.decode(msg)
        handle_message_from_client(steam_id, msg_decoded)
        msg_size, steam_id = steamworks:is_p2p_packet_available(0)
    end
end

local function on_game_end()
    if lobby_id then
        steamworks:leave_lobby(lobby_id)
        lobby_id = nil
    end
    players_ingame = {}
end

return {
    init = init_server,
    update = update,
    on_game_end = on_game_end
}