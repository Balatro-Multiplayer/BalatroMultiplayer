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
	local sid = self_id()
	local i_won
	if params.winner_team_id then
		-- Manhunt/Teams: the referee declares a TEAM the winner (winner_id is left
		-- empty, see referee.lua) -- resolve against my own roster assignment
		-- instead of comparing player ids.
		i_won = PVP.LOBBY.roster and PVP.LOBBY.roster[sid] == params.winner_team_id
	elseif params.winner_id == "*draw*" then
		i_won = true
	else
		i_won = params.winner_id == sid
	end
	PVP.dispatch_action(i_won and "winGame" or "loseGame")
	-- Host reports the matchmaking result (ELO + leaderboard) once per match.
	local lobby = MPAPI.get_current_lobby()
	if lobby and lobby.is_host and PVP.report_match_result then
		PVP.report_match_result(params.winner_team_id or params.winner_id)
	end
end)

-- Opponent-forfeit win (broadcast from the gamemode's on_player_forfeit).
A("pvp_player_won", function(_at, _from, params)
	local sid = self_id()
	if params.player_id == sid then
		PVP.dispatch_action("winGame")
	else
		PVP.dispatch_action("loseGame")
	end
end)
