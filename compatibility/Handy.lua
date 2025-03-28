if Handy then
	-- Disable all dangerous controls
	if type(Handy.is_dangerous_actions_active) == "function" then
		-- Updated version
		function Handy.is_dangerous_actions_active()
			return false
		end
	elseif Handy.dangerous_actions then
		-- Older versions, just in case
		function Handy.dangerous_actions.can_execute()
			return false
		end
		function Handy.dangerous_actions.can_execute_tag()
			return false
		end
		function Handy.dangerous_actions.update_state_panel()
			return false
		end
	end

	-- Disable game speed and Nopeus interaction
	if type(Handy.get_module_override) == "function" then
		-- Updater version
		local func_ref = Handy.get_module_override
		function Handy.get_module_override(module)
			if module == Handy.cc.speed_multiplier or module == Handy.cc.nopeus_interaction then
				return { enabled = false }
			else
				return func_ref()
			end
		end
	else
		-- Older versions, just in case
		if Handy.speed_multiplier then
			function Handy.speed_multiplier.can_execute()
				return false
			end
			function Handy.speed_multiplier.get_actions()
				return {
					multiply = false,
					divide = false,
				}
			end
		end
		if Handy.nopeus_interaction then
			function Handy.nopeus_interaction.can_execute()
				return false
			end
			function Handy.nopeus_interaction.get_actions()
				return {
					increase = false,
					decrease = false,
				}
			end
		end
	end

	-- Notify about successfully patched mod in button label and settings page
	if Handy.UI then
		if type(Handy.UI.get_options_button) == "function" then
			function Handy.UI.get_options_button()
				return UIBox_button({
					label = { "Handy [MP Patched]" },
					button = "handy_open_options",
					minw = 5,
					colour = G.C.CHIPS,
				})
			end
		end
		if type(Handy.UI.get_config_tab_overall) == "function" then
			local func_ref = Handy.UI.get_config_tab_overall
			function Handy.UI.get_config_tab_overall()
				local result = func_ref()
				table.insert(result, { n = G.UIT.R, config = { minh = 0.2 } })
				table.insert(result, {
					n = G.UIT.R,
					config = { padding = 0.1, align = "cm" },
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = "Patched by Multiplayer mod: Speed Multiplayer, Nopeus interaction and Dangerous controls disabled.",
								scale = 0.3,
								colour = G.C.MULT,
								align = "cm",
							},
						},
					},
				})
				return result
			end
		end
	end
end
