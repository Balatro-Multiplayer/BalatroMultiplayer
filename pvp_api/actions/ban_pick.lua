-- Deck ban-pick draft (engine lives in MPAPI.BanPick).

-- Host -> all: the full canonical ban-pick state, rebroadcast after every change.
MPAPI.ActionType({
	key = "pvp_ban_pick_state",
	prefix_config = { key = false },
	parameters = { { key = "state", type = "table", required = true } },
	on_receive = function(_at, _from, params)
		local lobby = MPAPI.get_current_lobby()
		if lobby then
			MPAPI.BanPick.on_state(lobby, params.state)
		end
	end,
})

-- Guest -> host: a request to ban a deck; only the host applies it (authority).
MPAPI.ActionType({
	key = "pvp_ban_pick_ban",
	prefix_config = { key = false },
	parameters = { { key = "item_key", type = "string", required = true } },
	on_receive = function(_at, from, params)
		local lobby = MPAPI.get_current_lobby()
		if not lobby or not lobby.is_host then
			return
		end
		if MPAPI.BanPick.apply_ban(lobby, from, params.item_key) then
			MPAPI.BanPick.broadcast_state(lobby)
		end
	end,
})
