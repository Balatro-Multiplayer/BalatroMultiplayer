-- Custom editor wall: states, counts, idol cycling, Chaos Clock control, Mystery Mix.
local function toggle(S, key)
	G.FUNCS.mp_toggle_mutator(S.fake_button({ def = MP.MUTATORS[key] }))
end

return {
	{
		wait = 2,
		run = function(S)
			MP.MODIFIERS = {}
			MP.CUSTOM.draft = MP.CUSTOM.new_draft()
			MP.CUSTOM.draft.base = "Sandbox"
			toggle(S, "glass_cannon") -- on
			toggle(S, "score_instability")
			toggle(S, "score_instability") -- back off
			toggle(S, "sandbox_retired") -- on
			toggle(S, "idol")
			toggle(S, "idol") -- Collector
			G.FUNCS.mp_change_chaos_clock({ to_key = 3 }) -- Normal
			G.FUNCS.overlay_menu({ definition = G.UIDEF.ruleset_selection_tabs("practice", "Custom") })
		end,
	},
	{
		wait = 1.5,
		run = function(S)
			S.check(MP.has_modifier("glass_cannon"), "glass_cannon on")
			S.check(not MP.has_modifier("score_instability"), "second click turns a cell off")
			S.check(MP.CHAOS_CLOCK.preset_key() == "normal", "clock set to Normal")
			S.check(MP.MUTATORS.chaos_clock == nil, "clock is not a wall cell")
			local cells = MP.UI.chaos_clock_pool()
			S.check(cells > 0, "clock pool has Off cells, got " .. cells)
			S.check(MP.has_modifier("idol_collector"), "idol cycled to Collector")
			S.check(MP.CUSTOM.base_has_layer("sandbox"), "Sandbox base implies sandbox layer")
			local mp_jokers = MP.MUTATORS.multiplayer_jokers.implied_by
			S.check(MP.CUSTOM.base_implies(mp_jokers), "Sandbox base implies MP Jokers")
			S.check(not MP.CUSTOM.base_implies(mp_jokers, "Vanilla"), "Vanilla base doesn't imply MP Jokers")
			S.check(MP.UI.active_mutator_count() == 3, "active count 3, got " .. MP.UI.active_mutator_count())
			S.check(
				MP.CUSTOM.play_summary.text == "Sandbox / 3 changes / Normal Chaos",
				"play summary 'Sandbox / 3 changes / Normal Chaos', got '"
					.. tostring(MP.CUSTOM.play_summary.text)
					.. "'"
			)
			S.log("modifiers=" .. MP.modifiers_serialize())
			S.shot("wall")
		end,
	},
	{
		wait = 0.5,
		run = function(S)
			toggle(S, "no_uncommons")
			toggle(S, "no_uncommons")
			S.check(not MP.has_modifier("no_uncommons"), "no_uncommons on -> off")
			toggle(S, "multiplayer_jokers")
			S.check(MP.current_ruleset().multiplayer_content == true, "MP Jokers cell turns multiplayer_content on")
			toggle(S, "multiplayer_jokers")
			S.check(not MP.has_modifier("multiplayer_jokers"), "MP Jokers on -> off")
			-- Secret idol: shift-click can't be faked through love.keyboard, so set it directly.
			MP.add_modifier("idol_none")
			MP.remove_modifier("idol_collector")
			toggle(S, "idol")
			S.check(
				not MP.has_modifier("idol_none") and MP.has_modifier("idol_zealot") == false,
				"plain click from secret returns to Random"
			)
			-- Glass Cannon is a clock cell: On takes it out of the pool.
			local before = MP.UI.chaos_clock_pool()
			toggle(S, "glass_cannon")
			S.check(MP.UI.chaos_clock_pool() == before + 1, "turning a clock cell Off adds it to the pool")
			toggle(S, "glass_cannon")
			G.FUNCS.mp_clear_mutators(S.fake_button({}))
			S.check(MP.CHAOS_CLOCK.preset_key() == nil, "Clear turns the clock Off")
		end,
	},
	{
		wait = 0.5,
		run = function(S)
			MP.add_modifier("multiplayer_jokers")
			G.FUNCS.mp_mystery_mix(S.fake_button({}))
			S.check(MP.has_modifier("multiplayer_jokers"), "Mystery Mix keeps the JOKERS column as set")
			S.check(not MP.has_modifier("sandbox_retired"), "Mystery Mix doesn't roll JOKERS cells")
		end,
	},
	{
		wait = 1,
		run = function(S)
			S.check(MP.MUTATORS_HIDDEN == true, "Mystery Mix hides the wall")
			S.check(MP.UI.mutator_readout.count == "?", "readout shows ?")
			S.check(MP.CUSTOM.play_summary.text == "Sandbox / Mystery Mix", "Mystery Mix hides the clock preset")
			S.shot("blind")
		end,
	},
	{
		-- captureScreenshot lands at the end of the frame, so close the overlay a step later.
		wait = 0.5,
		run = function(S)
			MP.MUTATORS_HIDDEN = false
			MP.MODIFIERS = {}
			G.FUNCS.exit_overlay_menu()
		end,
	},
}
