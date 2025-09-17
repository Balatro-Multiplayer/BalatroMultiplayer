function G.FUNCS.start_sp_for_real(e)
	-- TODO maybe remove overlay shit and unpause?
	G.FUNCS.setup_run(e)
end

function G.UIDEF.sp_ruleset_selection_options()
	MP.LOBBY.fetched_weekly = "smallworld" -- temp
	MP.SP.ruleset = nil
	MP.LoadReworks()

	local default_ruleset_area = UIBox({
		definition = G.UIDEF.ruleset_info("vanilla"),
		config = { align = "cm" },
	})

	local ruleset_buttons_data = {
		{
			name = "k_standard",
			buttons = {
				{ button_id = "vanilla_ruleset_button", button_localize_key = "k_vanilla" },
				{ button_id = "ranked_ruleset_button", button_localize_key = "k_ranked" },
				{ button_id = "badlatro_ruleset_button", button_localize_key = "k_badlatro" },
				{ button_id = "sandbox_ruleset_button", button_localize_key = "k_sandbox" },
				{ button_id = "smallworld_ruleset_button", button_localize_key = "k_smallworld" },
				{ button_id = "majorleague_ruleset_button", button_localize_key = "k_majorleague" },
				{ button_id = "minorleague_ruleset_button", button_localize_key = "k_minorleague" },
			},
		},
	}

	return MP.UI.Main_Lobby_Options(
		"ruleset_area",
		default_ruleset_area,
		"change_ruleset_selection_singleplayer",
		ruleset_buttons_data
	)
end

function G.UIDEF.ruleset_info_singleplayer(ruleset_name)
	local ruleset = MP.Rulesets["ruleset_mp_" .. ruleset_name]

	local ruleset_info_banned_rework_tabs = UIBox({
		definition = G.UIDEF.ruleset_tabs(ruleset),
		config = { align = "cm" },
	})

	local ruleset_disabled = ruleset.is_disabled()

	return {
		n = G.UIT.ROOT,
		config = { align = "tm", minh = 8, maxh = 8, minw = 11, maxw = 11, colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "tm", padding = 0.2, r = 0.1, colour = G.C.BLACK },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.O, config = { object = ruleset_info_banned_rework_tabs } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							MP.UI.Disableable_Button({
								id = "play_sp_button",
								button = "start_sp_for_real",
								align = "cm",
								padding = 0.05,
								r = 0.1,
								minw = 8,
								minh = 0.8,
								colour = G.C.BLUE,
								hover = true,
								shadow = true,
								label = { "Let's go" },
								scale = 0.5,
								enabled_ref_table = { val = not ruleset_disabled },
								enabled_ref_value = "val",
								disabled_text = { ruleset_disabled },
							}),
						},
					},
				},
			},
		},
	}
end

function G.FUNCS.change_ruleset_selection_singleplayer(e)
	-- if e.config.id == "weekly_ruleset_button" then
	-- 	if G.FUNCS.weekly_interrupt(e) then return end
	-- end
	MP.UI.Change_Main_Lobby_Options(
		e,
		"ruleset_area",
		G.UIDEF.ruleset_info_singleplayer,
		"vanilla_ruleset_button",
		function(ruleset_name)
			MP.SP.ruleset = "ruleset_mp_" .. ruleset_name
			MP.LoadReworks(ruleset_name)
		end
	)
end
