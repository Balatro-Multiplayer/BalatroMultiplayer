local A = PVP._pvp_action_helpers.A
local self_id = PVP._pvp_action_helpers.self_id

-- Authoritative outcomes (host -> all).
A("pvp_end_pvp", function(_at, _from, params)
	local sid = self_id()
	local lost = params.loser_id ~= nil and params.loser_id ~= "" and params.loser_id == sid
	PVP.dispatch_action("endPvP", { lost = lost, pvpTimerLost = params.pvp_timer_lost and true or false })
end)

A("pvp_player_lives", function(_at, _from, params)
	local sid = self_id()
	local lives = tonumber(params.lives)

	-- Best-effort local cache for ui/game/player_status_provider.lua: a
	-- non-host client has no local PVP.REF (host-only, in-memory -- see
	-- referee.lua), so this is the only per-player lives signal it can ever
	-- see. Only whichever players' deltas actually reach this client (self +
	-- current 1v1 target reliably; Royale/Manhunt's rotating pairings mean a
	-- past opponent's cached value can go stale until they're paired again)
	-- -- still strictly better than no signal at all. The host itself never
	-- needs this cache; its provider reads PVP.REF directly.
	if params.player_id and params.player_id ~= "*all*" then
		PVP._player_lives_cache = PVP._player_lives_cache or {}
		PVP._player_lives_cache[params.player_id] = lives
	end

	if params.player_id == "*all*" then
		PVP.GAME.lives = lives
		if PVP.GAME.enemy then
			PVP.GAME.enemy.lives = lives
		end
		PVP.dispatch_action("playerInfo", { lives = lives })
	elseif params.player_id == sid then
		PVP.dispatch_action("playerInfo", { lives = lives })
	elseif params.player_id == PVP.current_target_id() then
		if PVP.GAME.enemy then
			PVP.GAME.enemy.lives = lives
			if PVP.UI and PVP.UI.juice_up_pvp_hud then
				pcall(PVP.UI.juice_up_pvp_hud)
			end
		end
	end
end)

A("pvp_win", function(_at, _from, params)
	local lobby = MPAPI.get_current_lobby()
	-- A draw (a unanimous vote, or referee.lua's check_alive_win seeing everyone
	-- eliminated at once) has no winner to resolve against -- both routes here
	-- converge on the same drawGame dispatch/MMR-skip, see pvp_api/run_actions.lua's
	-- PVP.register_draw_vote for why this reuses pvp_win instead of a separate action.
	local refereed = MPAPI.has_server_referee(lobby)
	if params.draw then
		PVP.dispatch_action("drawGame")
		if refereed then
			PVP.report_server_result(lobby, nil, { draw = true })
		end
		return
	end

	local sid = self_id()
	local i_won
	if params.winner_team_id then
		-- Manhunt/Teams: the referee declares a TEAM the winner (winner_id is left
		-- empty, see referee.lua) -- resolve against my own roster assignment
		-- instead of comparing player ids.
		i_won = PVP.LOBBY.roster and PVP.LOBBY.roster[sid] == params.winner_team_id
	else
		i_won = params.winner_id == sid
	end
	PVP.dispatch_action(i_won and "winGame" or "loseGame")
	-- A server-refereed lobby: everyone reports (the server rates it). An
	-- offline lobby has nothing to report to.
	if refereed then
		PVP.report_server_result(lobby, params.winner_team_id or params.winner_id, { team = params.winner_team_id ~= nil })
	end
end)

-- Opponent-forfeit win (broadcast from the gamemode's on_player_forfeit).
-- A server-refereed lobby: whoever is still in reports it (the forfeiter has
-- left, so the server settles the run as partial).
A("pvp_player_won", function(_at, _from, params)
	local sid = self_id()
	if params.player_id == sid then
		PVP.dispatch_action("winGame")
	else
		PVP.dispatch_action("loseGame")
	end
	local lobby = MPAPI.get_current_lobby()
	if MPAPI.has_server_referee(lobby) then
		PVP.report_server_result(lobby, params.player_id)
	end
end)
