-- Manhunt (Hunter/Runner) and Teams (A/B) lobby options -- the lobby's first real
-- options screen (previously a no-op placeholder, see ui/lobby/code.lua). Only
-- ever shows one of the two picker rows: PVP.LOBBY.config.manhunt/team_based are
-- mutually exclusive, set once from the chosen gamemode at lobby creation.
--
-- Literal English strings (not localize() keys) match the existing "Practice"
-- ruleset-picker overlay's own style (ui/pvp_main_menu.lua) rather than inventing
-- localization keys ahead of the Phase G polish pass.
function PVP.build_manhunt_teams_options()
	local rows = {}

	if PVP.LOBBY.config.manhunt then
		rows[#rows + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.1 },
			nodes = {
				MPAPI.disableable_option_cycle({
					id = "mp_pvp_manhunt_role",
					label = "Role",
					options = { "Hunter", "Runner" },
					current_option = (PVP.LOBBY.team_id == "RUNNER") and 2 or 1,
					opt_callback = "mp_pvp_change_manhunt_role",
					w = 4,
					scale = 0.6,
					enabled = function()
						return PVP.LOBBY.team_id == "RUNNER" or not PVP.is_runner_taken()
					end,
				}).node,
			},
		}

		local lobby = MPAPI.get_current_lobby()
		if lobby and lobby.is_host then
			rows[#rows + 1] = {
				n = G.UIT.R,
				config = { align = "cm", padding = 0.1 },
				nodes = {
					create_option_cycle({
						id = "mp_pvp_manhunt_hunter_lives",
						label = "Hunter Lives",
						options = { "7", "8", "9", "10", "11", "12", "13", "14", "15", "16" },
						current_option = (PVP.LOBBY.config.manhunt_hunter_lives or 7) - 6,
						opt_callback = "mp_pvp_change_manhunt_hunter_lives",
						w = 4,
						scale = 0.6,
					}),
				},
			}
		end
	elseif PVP.LOBBY.config.team_based then
		rows[#rows + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.1 },
			nodes = {
				create_option_cycle({
					id = "mp_pvp_team_pick",
					label = "My Team",
					options = { "Team A", "Team B" },
					current_option = (PVP.LOBBY.team_id == "B") and 2 or 1,
					opt_callback = "mp_pvp_change_team",
					w = 4,
					scale = 0.6,
				}),
			},
		}
	end

	return create_UIBox_generic_options({ contents = rows })
end

G.FUNCS.mp_pvp_change_manhunt_role = function(e)
	PVP.pvp_set_team((e.to_key == 2) and "RUNNER" or "HUNTER")
end

G.FUNCS.mp_pvp_change_team = function(e)
	PVP.pvp_set_team((e.to_key == 2) and "B" or "A")
end

G.FUNCS.mp_pvp_change_manhunt_hunter_lives = function(e)
	PVP.LOBBY.config.manhunt_hunter_lives = e.to_key + 6
	local lobby = MPAPI.get_current_lobby()
	if lobby and lobby.is_host then
		lobby:set_metadata(PVP.pvp_lobby_metadata(PVP._pvp_gamemode, PVP._pvp_kind))
	end
end
