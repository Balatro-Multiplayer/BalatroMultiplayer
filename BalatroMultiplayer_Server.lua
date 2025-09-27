local function init_server(player_count)
    steamworks:create_lobby("public", player_count, lobby_created_callback)
    steamworks:register_callback("p2p_session_request", p2p_session_request_callback)
    steamworks:register_callback("lobby_chat_update", lobby_chat_update_callback)
end
