local A = MP._pvp_action_helpers.A
local self_id = MP._pvp_action_helpers.self_id

-- Authoritative outcomes (host -> all).
A("pvp_end_pvp", function(_at, _from, params)
	local sid = self_id()
	local lost = params.loser_id ~= nil and params.loser_id ~= "" and params.loser_id == sid
	MP.dispatch_action("endPvP", { lost = lost, pvpTimerLost = params.pvp_timer_lost and true or false })
end)

A("pvp_player_lives", function(_at, _from, params)
	local sid = self_id()
	local lives = tonumber(params.lives)
	if params.player_id == "*all*" then
		MP.GAME.lives = lives
		if MP.GAME.enemy then
			MP.GAME.enemy.lives = lives
		end
		MP.dispatch_action("playerInfo", { lives = lives })
	elseif params.player_id == sid then
		MP.dispatch_action("playerInfo", { lives = lives })
	elseif params.player_id == MP.current_target_id() then
		if MP.GAME.enemy then
			MP.GAME.enemy.lives = lives
			if MP.UI and MP.UI.juice_up_pvp_hud then
				pcall(MP.UI.juice_up_pvp_hud)
			end
		end
	end
end)

A("pvp_win", function(_at, _from, params)
	local sid = self_id()
	if params.winner_id == "*draw*" then
		MP.dispatch_action("winGame")
	elseif params.winner_id == sid then
		MP.dispatch_action("winGame")
	else
		MP.dispatch_action("loseGame")
	end
	-- Host reports the matchmaking result (ELO + leaderboard) once per match.
	local lobby = MPAPI.get_current_lobby()
	if lobby and lobby.is_host and MP.report_match_result then
		MP.report_match_result(params.winner_id)
	end
end)

-- Opponent-forfeit win (broadcast from the gamemode's on_player_forfeit).
A("pvp_player_won", function(_at, _from, params)
	local sid = self_id()
	if params.player_id == sid then
		MP.dispatch_action("winGame")
	else
		MP.dispatch_action("loseGame")
	end
end)
