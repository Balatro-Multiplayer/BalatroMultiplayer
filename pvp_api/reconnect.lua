-- Crash-relaunch reconnect: called once the lobby object itself has already
-- been recreated (MPAPI._internal.create_reconnected_lobby, driven by
-- BalatroMultiplayerAPI's ui/reconnect_prompt.lua) and there's no active
-- RLOG match run to hand off to instead (that's the OTHER branch of that
-- file's Reconnect handler -- this one only ever runs pre-match: waiting
-- room or mid-ban-pick-draft).
MPAPI.register_lobby_reconnect(PVP.id, function(lobby)
	-- Mirrors pvp_api/flow.lua / queue.lua's own PVP._pvp_kind assignment --
	-- every other entry path sets this from the button the player actually
	-- clicked (Create Private / Find Match / Ranked Queue); a reconnect has
	-- no such click to read, so it's derived from the lobby's own
	-- server-reported type instead. MPAPI.LobbyType has no CASUAL value of
	-- its own (only PUBLIC/PRIVATE/RANKED) -- PVP's own "casual" matchmaking
	-- queue is what a plain PUBLIC lobby type means here.
	if lobby.type == MPAPI.LobbyType.RANKED then
		PVP._pvp_kind = PVP.LobbyAccess.RANKED
	elseif lobby.type == MPAPI.LobbyType.PUBLIC then
		PVP._pvp_kind = PVP.LobbyAccess.CASUAL
	else
		PVP._pvp_kind = PVP.LobbyAccess.PRIVATE
	end

	PVP.setup_lobby_mirror(lobby)

	-- Resume a ban-pick draft that was already in progress, if any. Restore
	-- lobby._ban_pick from the host's own metadata mirror first (see
	-- MPAPI.BanPick.broadcast_state's comment) -- a reconnecting player's own
	-- lobby object never had this field populated any other way, since it's
	-- assembled fresh from context.reconnected_lobby (api/lobby/public.lua),
	-- which carries metadata but has no _ban_pick field of its own.
	local meta = lobby:get_metadata() or {}
	if not lobby._ban_pick and meta._mp_ban_pick_state then
		lobby._ban_pick = meta._mp_ban_pick_state
	end
	if lobby._ban_pick and not lobby._ban_pick.complete then
		local gm_def = meta.queue_mode and MPAPI.GameModes[meta.queue_mode]
		if gm_def and gm_def.ban_pick then
			MPAPI.BanPick.resume(
				lobby,
				PVP._ban_pick_config_for(gm_def),
				PVP._ban_pick_on_complete_for(gm_def, lobby, meta._mp_pending_seed, meta._mp_pending_stake)
			)
		end
	end
end)
