local A = MP._pvp_action_helpers.A
local relay = MP._pvp_action_helpers.relay
local self_id = MP._pvp_action_helpers.self_id

-- Score / state resolution (referee). The opponent-facing DISPLAY of
-- score/hands/skips/lives is synced separately via the nemesis blind's
-- calculate/receive (see objects/blinds/nemesis.lua); these handlers now only
-- feed the host-authoritative referee.
A("pvp_play_hand", function(_at, from, params)
	MP.referee_on_play_hand(from, params or {})
end)

A("pvp_skip", function(_at, from, params)
	MP.referee_on_skip(from, params or {})
end)

relay("pvp_location", "enemyLocation")

A("pvp_set_ante", function(_at, from, params)
	MP.referee_on_set_ante(from, params or {})
end)

-- Nemesis-pairing (rotating no-repeat duels): host -> all, the current ante's full
-- pairing map. Each client picks out its own entry; MP.current_target_id() reads it.
MPAPI.ActionType({
	key = "pvp_nemesis_pairing",
	prefix_config = { key = false },
	parameters = { { key = "pairing", type = "table", required = true } },
	on_receive = function(_at, _from, params)
		local sid = self_id()
		local partner = params.pairing and params.pairing[sid]
		MP.GAME.nemesis_partner_id = (partner and partner ~= "") and partner or nil
		if MP.CURRENT_LOBBY then MP.mirror_players(MP.CURRENT_LOBBY) end
	end,
})

A("pvp_set_furthest_blind", function(_at, from, params)
	MP.referee_on_set_furthest_blind(from, params or {})
end)

A("pvp_new_round", function(_at, from, _params)
	MP.referee_on_new_round(from)
end)
