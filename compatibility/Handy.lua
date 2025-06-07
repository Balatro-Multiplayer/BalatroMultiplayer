if Handy then
	-- Patch fake events check and execute
	if not (Handy.meta and Handy.meta["1.4.1b_patched_select_blind_and_skip"]) then
		local fake_events_check_ref = Handy.fake_events.check
		function Handy.fake_events.check(arg)
			if type(arg.func) == "function" and arg.node then
				arg.func(arg.node)
				return arg.node.config.button ~= nil, arg.node.config.button
			end
			return fake_events_check_ref(arg)
		end
		local fake_events_execute_ref = Handy.fake_events.execute
		function Handy.fake_events.execute(arg)
			if type(arg.func) == "function" and arg.node then
				arg.func(arg.node)
			else
				fake_events_execute_ref(arg)
			end
		end
	end

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

	-- Disable game speed, Animation skip and Nopeus interaction
	if type(Handy.get_module_override) == "function" then
		-- Updater version
		local func_ref = Handy.get_module_override
		function Handy.get_module_override(module)
			if
				module
				and (
					module == Handy.cc.speed_multiplier
					or module == Handy.cc.nopeus_interaction
					or module == Handy.cc.animation_skip
				)
			then
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

	-- Patch "Select blind" keybinds to prevent softlocks
	if Handy.regular_keybinds then
		if not (Handy.meta and Handy.meta["1.4.1b_patched_select_blind_and_skip"]) then
			function Handy.regular_keybinds.can_select_blind(key)
				if
					not (
						Handy.controller.is_module_key(Handy.config.current.regular_keybinds.select_blind, key)
						and G.GAME.blind_on_deck
						and G.GAME.round_resets.blind_choices[G.GAME.blind_on_deck]
					)
				then
					return false
				end

				local success, button = pcall(function()
					return G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]:get_UIE_by_ID("select_blind_button")
				end)
				if not success or not button then
					return false
				end
				if button.config and button.config.func then
					return Handy.fake_events.check({
						func = G.FUNCS[button.config.func],
						node = button,
					})
				else
					return true
				end
			end
			function Handy.regular_keybinds.select_blind()
				local success, button = pcall(function()
					return G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]:get_UIE_by_ID("select_blind_button")
				end)

				if success and button and button.config and button.config.button then
					Handy.fake_events.execute({
						func = G.FUNCS[button.config.button],
						node = button,
					})
				end
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
								text = "Patched by Multiplayer mod: Speed Multiplayer, Animation skip, Nopeus interaction and Dangerous controls are disabled.",
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
