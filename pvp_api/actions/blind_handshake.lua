local A = MP._pvp_action_helpers.A

-- Blind handshake (host-authoritative).
A("pvp_ready_blind", function(_at, from, _params)
	MP.referee_on_ready_blind(from)
end)

A("pvp_unready_blind", function(_at, from, _params)
	MP.referee_on_unready_blind(from)
end)

A("pvp_start_blind", function(_at, _from, params)
	local lobby = MPAPI.get_current_lobby()
	if not lobby then
		return
	end
	-- action_start_blind compares firstPlayer to (is_host and "host" or "guest");
	-- translate the authoritative first-player id into this client's frame.
	local me = lobby.is_host and "host" or "guest"
	local other = lobby.is_host and "guest" or "host"
	local fp = (params.first_player == lobby.player_id) and me or other
	MP.dispatch_action("startBlind", { firstPlayer = fp })
end)
