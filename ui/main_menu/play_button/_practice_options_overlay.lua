-- Practice Options overlay: toggles, replay picker entry, and (when allowed by
-- the ruleset) the Modifiers entry. Consolidated here so the ruleset_info panel
-- in practice mode keeps to a tidy two-button action row.

G.FUNCS.mp_practice_options_back = function(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_tabs("practice"),
	})
end

G.FUNCS.mp_open_practice_options_overlay = function(e)
	local ruleset = MP.SP.ruleset and MP.Rulesets[MP.SP.ruleset] or nil

	local practice_toggles = {
		{ id = "unlimited_slots_toggle", label = "k_unlimited_slots", ref_value = "unlimited_slots" },
		{ id = "edition_cycling_toggle", label = "k_edition_cycling", ref_value = "edition_cycling" },
	}
	local toggle_nodes = {}
	for _, t in ipairs(practice_toggles) do
		toggle_nodes[#toggle_nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.05 },
			nodes = {
				create_toggle({
					id = t.id,
					label = localize(t.label),
					ref_table = MP.SP,
					ref_value = t.ref_value,
				}),
			},
		}
	end

	local ghost_label = localize("k_ghost_replays")
	if MP.GHOST.is_active() then ghost_label = ghost_label .. " (Active)" end
	local ghost_button = UIBox_button({
		id = "ghost_replay_button",
		button = "open_ghost_replay_picker",
		label = { ghost_label },
		minw = 4,
		minh = 0.6,
		scale = 0.4,
		colour = MP.GHOST.is_active() and G.C.GREEN or G.C.BLUE,
		hover = true,
		shadow = true,
	})

	local body_rows = {
		{
			n = G.UIT.R,
			config = { align = "cm", padding = 0.1 },
			nodes = toggle_nodes,
		},
	}

	local modifier_btn = ruleset and MP.UI.build_modifier_button(ruleset, "practice") or nil
	if modifier_btn then
		body_rows[#body_rows + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.15 },
			nodes = { modifier_btn },
		}
	end

	body_rows[#body_rows + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.15 },
		nodes = { ghost_button },
	}

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			back_func = "mp_practice_options_back",
			contents = {
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.25, colour = G.C.BLACK, r = 0.25, minw = 6 },
					nodes = body_rows,
				},
			},
		}),
	})
end
