local A = MP._pvp_action_helpers.A

A("pvp_player_ready", function(_at, from, params)
	sendDebugMessage("[pvp] RECV pvp_player_ready from=" .. tostring(from) .. " ready=" .. tostring(params and params.ready), "MULTIPLAYER")
	-- Every client tallies (own arrives via loopback); the host gates Start on it.
	MP.set_player_ready(from, params and params.ready)
end)
