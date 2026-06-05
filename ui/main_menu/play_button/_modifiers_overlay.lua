G.FUNCS.mp_open_modifiers_overlay = function(e)
	local timer_cycle = MP.UI.build_timer_modifier_cycle()
	local pvp_timer_toggle = MP.UI.build_pvp_timer_toggle()

	local smallworld_toggle = create_toggle({
		id = "modifier_smallworld_toggle",
		label = localize("b_opts_modifier_smallworld"),
		ref_table = { val = MP.has_modifier("smallworld") },
		ref_value = "val",
		callback = function(new_val)
			if new_val then
				MP.add_modifier("smallworld")
			else
				MP.remove_modifier("smallworld")
			end
		end,
	})

	local function create_entry(option, loc_key)
		local message_table = localize(loc_key)
		local result_text = {}
		for _, line in ipairs(message_table) do
			table.insert(result_text, {
				n = G.UIT.R,
				config = { minw = 8.5, maxw = 8.5 },
				nodes = SMODS.localize_box(loc_parse_string(line), {
					default_col = G.C.UI.TEXT_LIGHT,
				}),
			})
		end

		return {
			n = G.UIT.R,
			config = {
				padding = 0.25,
				align = "cm",
				r = 0.25,
				colour = { 1, 1, 1, 0.1 },
			},
			nodes = {
				{
					n = G.UIT.C,
					config = { minw = 5, align = "cm" },
					nodes = {
						option,
					},
				},
				{
					n = G.UIT.C,
					config = { align = "cm" },
					nodes = result_text,
				},
			},
		}
	end

	local back_func = MP.is_practice_mode() and "mp_open_practice_options_overlay" or "create_lobby"

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			back_func = back_func,
			contents = {
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.25, colour = G.C.BLACK, r = 0.25 },
					nodes = {
						{
							n = G.UIT.R,
							nodes = {
								create_entry(timer_cycle, "k_experimental_modifiers_timers"),
								{ n = G.UIT.R, config = { minh = 0.25 } },
								create_entry(pvp_timer_toggle, "k_experimental_modifiers_pvp_timer"),
								{ n = G.UIT.R, config = { minh = 0.25 } },
								create_entry(smallworld_toggle, "k_experimental_modifiers_smallworld"),
							},
						},
						{ n = G.UIT.R },
						{
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								MP.UI.get_continue_button(e.config.ref_table.ruleset, e.config.ref_table.mode),
							},
						},
					},
				},
			},
		}),
	})
end
