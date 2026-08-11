-- Player-status provider for MPAPI's lobby card grid (see
-- BalatroMultiplayerAPI/api/player_status_providers.lua): a player with 0 or
-- fewer lives is out of the run (dead, or forfeited -- pvp_forfeit routes
-- through the same referee elimination bookkeeping as a real loss, see
-- pvp_api/run_actions.lua) and renders debuffed.
--
-- On the host, PVP.REF.players[id].lives (referee.lua) is authoritative for
-- every player. A non-host client has no local PVP.REF at all -- it falls
-- back to PVP._player_lives_cache (pvp_api/actions/outcomes.lua), a
-- best-effort cache of whichever pvp_player_lives deltas actually reached
-- this client. A player never seen in either source is assumed alive
-- (returns false, not debuffed) rather than guessed at.
MPAPI.register_player_status_provider(PVP.id, function(lobby, player_data)
	local id = player_data.id

	if PVP.REF and PVP.REF.players and PVP.REF.players[id] then
		return (PVP.REF.players[id].lives or 1) <= 0
	end

	local cached = PVP._player_lives_cache and PVP._player_lives_cache[id]
	if cached ~= nil then
		return cached <= 0
	end

	return false
end)
