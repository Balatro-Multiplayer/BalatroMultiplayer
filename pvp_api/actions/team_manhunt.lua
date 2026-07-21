-- Team/role assignment, shared by Manhunt's Hunter/Runner picker and Teams' A/B
-- picker. Lobby-phase-only broadcast: each client tells everyone else its own
-- team_id; every receiver (host and guests alike) populates PVP.LOBBY.roster
-- (everyone's current assignment) and, for its own sender, PVP.LOBBY.team_id. The
-- host stamps ref_player().team_id from this roster once the match actually
-- starts (PVP.referee_reset, pvp_api/referee.lua) -- exclusivity/defaults there are
-- authoritative; this roster is a best-effort UI mirror, not the source of truth.
local A = PVP._pvp_action_helpers.A
local self_id = PVP._pvp_action_helpers.self_id

function PVP.pvp_set_team(team_id)
	local lobby = MPAPI.get_current_lobby()
	if lobby then
		lobby:action(MPAPI.ActionTypes["pvp_set_team"]):broadcast({ team_id = team_id })
	end
end

A("pvp_set_team", function(_at, from, params)
	PVP.LOBBY.roster = PVP.LOBBY.roster or {}
	PVP.LOBBY.roster[from] = params.team_id
	if from == self_id() then
		PVP.LOBBY.team_id = params.team_id
	end
end)

-- Host -> all, sent once at match start (PVP.referee_reset): the FINAL, real
-- team_id for every player, including anyone who never opened the picker and got
-- a server-computed default. Authoritative, unlike the best-effort pvp_set_team
-- mirror above (which only ever reflects players who actively picked a role).
MPAPI.ActionType({
	key = "pvp_team_roster",
	prefix_config = { key = false },
	parameters = { { key = "roster", type = "table", required = true } },
	on_receive = function(_at, _from, params)
		PVP.LOBBY.roster = params.roster or {}
		local sid = self_id()
		if sid then
			PVP.LOBBY.team_id = PVP.LOBBY.roster[sid]
		end
	end,
})

-- Exactly one Runner allowed per Manhunt lobby: true once some OTHER player has
-- already claimed the Runner slot (best-effort UI check; PVP.referee_reset is the
-- actual authority at match start, see its header comment).
function PVP.is_runner_taken()
	local lobby = MPAPI.get_current_lobby()
	if not lobby or not PVP.LOBBY.roster then
		return false
	end
	for _, p in ipairs(lobby:get_players()) do
		if p.id ~= lobby.player_id and PVP.LOBBY.roster[p.id] == "RUNNER" then
			return true
		end
	end
	return false
end

-- Teams' shared-pool life sync (host -> all). Feeds the Teams lives HUD
-- (PVP.GAME.team_lives); individual pl.lives/pvp_player_lives keep flowing
-- separately for the existing per-player lives-reading code (see referee.lua's
-- resolve_teams_round/team_lose_life, which broadcast both).
MPAPI.ActionType({
	key = "pvp_team_lives",
	prefix_config = { key = false },
	parameters = {
		{ key = "team_id", type = "string", required = true },
		{ key = "lives", type = "number", required = true },
	},
	on_receive = function(_at, _from, params)
		PVP.GAME.team_lives = PVP.GAME.team_lives or {}
		PVP.GAME.team_lives[params.team_id] = tonumber(params.lives)
	end,
})

-- Manhunt's Hieroglyph/Petroglyph replacements (objects/vouchers/manhunt_vouchers.lua)
-- call this when the RUNNER redeems one: every Hunter gains +1 life as
-- compensation for the Runner buying themselves more time to evade.
function PVP.pvp_redeem_ante_voucher()
	local lobby = MPAPI.get_current_lobby()
	if lobby then
		lobby:action(MPAPI.ActionTypes["pvp_redeem_ante_voucher"]):broadcast({})
	end
end

A("pvp_redeem_ante_voucher", function(_at, from, _params)
	PVP.referee_on_redeem_ante_voucher(from)
end)
