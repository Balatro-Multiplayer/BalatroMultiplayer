-- UI-only check: no server connection or lobby creation. Real host/guest
-- validation is separate (see tests/readme.md).
local selected

return {
	{
		wait = 2,
		run = function()
			G.FUNCS.create_lobby()
			MP.CUSTOM.draft = { base = "Vanilla" }
			MP.MODIFIERS = { "glass_cannon", "clock_normal", "multiplayer_jokers", "glass_legacy" }
			selected = MP.modifiers_serialize()
			G.FUNCS.overlay_menu({ definition = G.UIDEF.ruleset_selection_tabs("mp", "Custom") })
		end,
	},
	{
		wait = 1,
		run = function(S)
			S.check(G.OVERLAY_MENU:get_UIE_by_ID("mp_custom_play_btn") ~= nil, "multiplayer editor is available")
			S.check(G.OVERLAY_MENU:get_UIE_by_ID("mp_randomize_mutators_btn") ~= nil, "Randomize is available")
			S.check(G.OVERLAY_MENU:get_UIE_by_ID("mp_mystery_mix_btn") == nil, "Mystery Mix stays local-only")
			S.shot("editor")
		end,
	},
	{
		wait = 0.3,
		run = function()
			G.FUNCS.mp_custom_play()
		end,
	},
	{
		wait = 1,
		run = function(S)
			S.check(
				G.OVERLAY_MENU:get_UIE_by_ID("start_lobby_button") ~= nil,
				"custom launch reaches gamemode selection"
			)
			S.check(MP.modifiers_serialize() == selected, "gamemode selection preserves modifiers")
			G.FUNCS.mp_gamemode_back()
		end,
	},
	{
		wait = 1,
		run = function(S)
			S.check(G.OVERLAY_MENU:get_UIE_by_ID("mp_custom_play_btn") ~= nil, "Back returns to the editor")
			S.check(MP.CUSTOM.draft.base == "Vanilla" and MP.modifiers_serialize() == selected, "Back preserves setup")
			S.shot("back")
		end,
	},
	{
		wait = 0.3,
		run = function()
			G.FUNCS.mp_view_lobby_rules()
		end,
	},
	{
		wait = 1,
		run = function(S)
			local text = table.concat(MP.UI.lobby_rules_lines(), "\n")
			S.check(text:find("Chaos Clock: Normal", 1, true) ~= nil, "readout shows the clock preset")
			S.check(text:find("MP Jokers: On", 1, true) ~= nil, "readout shows the content override")
			S.shot("rules")
		end,
	},
	{
		wait = 0.3,
		run = function()
			-- Exercise the live UIBox replacement path, not just its data helper.
			MP.set_multiplayer_jokers(false)
		end,
	},
	{
		wait = 1,
		run = function(S)
			S.shot("rules_updated")
			S.check(not MP.multiplayer_jokers_enabled(), "content checkbox state updates")
		end,
	},
	{
		wait = 0.3,
		run = function()
			for name, def in pairs(MP.MUTATORS) do
				if not def.variants then MP.add_modifier(name) end
			end
		end,
	},
	{
		wait = 1,
		run = function(S)
			S.shot("full_rules")
		end,
	},
	{
		wait = 0.3,
		run = function()
			MP.MODIFIERS = {}
			MP.CUSTOM.selecting_gamemode = false
			G.FUNCS.exit_overlay_menu()
		end,
	},
}
