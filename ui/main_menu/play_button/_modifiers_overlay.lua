-- Modifier toggles render inline inside the ruleset info panel. The handlers
-- write MP.MODIFIERS directly (no network) — the host's lobby_options push at
-- start_lobby carries the serialized list to the guest.
local function timer_modifier_to_index()
	if MP.has_modifier("pressure_timer_plus") then return 4 end
	if MP.has_modifier("pressure_timer") then return 3 end
	if MP.has_modifier("no_animation_timer") then return 2 end
	return 1
end

-- Indices line up with localization ml_mp_modifier_timer_opt: 1=default, 2=no_anim, 3=pressure
G.FUNCS.change_modifier_timer = function(args)
	MP.remove_modifier("no_animation_timer")
	MP.remove_modifier("pressure_timer")
	MP.remove_modifier("pressure_timer_plus")
	if args.to_key == 2 then
		MP.add_modifier("no_animation_timer")
	elseif args.to_key == 3 then
		MP.add_modifier("pressure_timer")
	elseif args.to_key == 4 then
		MP.add_modifier("pressure_timer")
		MP.add_modifier("pressure_timer_plus")
	end
end

G.FUNCS.mp_open_modifiers_overlay = function(e)
	local timer_cycle = MP.UI.Disableable_Option_Cycle({
		id = "modifier_timer_option",
		enabled_ref_table = { val = true },
		enabled_ref_value = "val",
		label = localize("k_opts_modifier_timer"),
		scale = 0.8,
		options = localize("ml_mp_modifier_timer_opt"),
		current_option = timer_modifier_to_index(),
		opt_callback = "change_modifier_timer",
		minw = 4,
		w = 4,
	})

	-- local smallworld_toggle = create_toggle({
	--     id = "modifier_smallworld_toggle",
	--     label = localize("b_opts_modifier_smallworld"),
	--     ref_table = { val = MP.has_modifier("smallworld") },
	--     ref_value = "val",
	--     callback = function(new_val)
	--         if new_val then
	--             MP.add_modifier("smallworld")
	--         else
	--             MP.remove_modifier("smallworld")
	--         end
	--     end,
	-- })

	local pvp_timer_toggle = create_toggle({
		id = "modifier_pvp_timer_toggle",
		label = localize("b_opts_modifier_pvp_timer"),
		ref_table = { val = MP.has_modifier("pvp_timer") },
		ref_value = "val",
		callback = function(new_val)
			if new_val then
				MP.add_modifier("pvp_timer")
			else
				MP.remove_modifier("pvp_timer")
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

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			back_func = "create_lobby",
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
							},
						},
						{ n = G.UIT.R },
						MP.UI.get_continue_button(e.config.ref_table.ruleset, e.config.ref_table.mode),
					},
				},
			},
		}),
	})
end

G.UIDEF.mp_modifiers_button_row = function(ruleset, mode)
	return {
		n = G.UIT.R,
		config = { align = "cm" },
		nodes = {
			MP.UI.Disableable_Button({
				button = "mp_open_modifiers_overlay",
				align = "cm",
				padding = 0.05,
				r = 0.1,
				minw = 8,
				minh = 0.8,
				colour = G.C.ORANGE,
				hover = true,
				shadow = true,
				label = { "Modifiers" },
				scale = 0.5,
				enabled_ref_table = { val = true },
				enabled_ref_value = "val",
				ref_table = {
					ruleset = ruleset,
					mode = mode,
				},
			}),
		},
	}
end
