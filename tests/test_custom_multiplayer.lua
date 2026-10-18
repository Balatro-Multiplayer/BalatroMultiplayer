-- Extend the native-content harness with the real editor, navigation callbacks
-- and lobby readout. The harness also loads the actual network dispatcher.
-- Run from the repository root: luajit tests/test_custom_multiplayer.lua
dofile("tests/test_multiplayer_content.lua")
dofile("ui/main_menu/play_button/custom_ruleset_editor.lua")
dofile("ui/main_menu/play_button/gamemode_selection.lua")
dofile("ui/lobby/rules_readout.lua")

local checks = 0
local function check(value, message)
	checks = checks + 1
	assert(value, message)
end

local overlay
G.FUNCS.overlay_menu = function(args)
	overlay = args.definition
end
G.FUNCS.exit_overlay_menu = function() end
create_UIBox_generic_options = function(args)
	return args
end
create_tabs = function(args)
	return args
end
UIBox_button = function(args)
	return { config = args, nodes = { { config = args } } }
end
create_option_cycle = function(args)
	return { config = args }
end
create_toggle = create_option_cycle
adjust_alpha = function(colour)
	return colour
end
localize = function(key)
	if key == "ml_mp_modifier_timer_opt" then return { "Default", "No Animations", "Pressure", "Pressure+" } end
	return key
end
local function find(node, key, value)
	if node.config and node.config[key] == value then return node end
	for _, child in ipairs(node.nodes or {}) do
		local hit = find(child, key, value)
		if hit then return hit end
	end
end

MP.LOBBY.code = nil
MP.LOBBY.config = {}
MP.CUSTOM.draft = { base = "Vanilla" }
MP.MODIFIERS =
	{ "glass_cannon", "clock_normal", "no_multiplayer_jokers", "glass_legacy", "pressure_timer", "pressure_timer_plus" }
local selected = MP.modifiers_serialize()
MP.MUTATORS_HIDDEN = true
local editor = MP.UI.build_custom_ruleset_editor("mp")
check(find(editor, "id", "mp_custom_play_btn"), "multiplayer editor has no launch button")
check(find(editor, "id", "mp_randomize_mutators_btn"), "multiplayer editor lost Randomize")
check(not find(editor, "id", "mp_mystery_mix_btn"), "Mystery Mix is exposed in multiplayer")
check(not MP.MUTATORS_HIDDEN, "multiplayer retained local hidden state")
check(find(MP.UI.build_custom_ruleset_editor("practice"), "id", "mp_mystery_mix_btn"), "practice lost Mystery Mix")
MP.UI.build_custom_ruleset_editor("mp")

G.FUNCS.mp_custom_play()
check(MP.LOBBY.config.ruleset == "ruleset_mp_vanilla", "launch lost the selected base")
check(MP.CUSTOM.selecting_gamemode, "custom launch did not remember its return path")
check(overlay.back_func == "mp_gamemode_back", "gamemode screen bypasses the preserving Back callback")
check(MP.modifiers_serialize() == selected, "gamemode selection lost ordered modifiers")
G.UIDEF.ruleset_selection_tabs = function(mode, tab)
	return { mode = mode, tab = tab }
end
G.FUNCS.mp_gamemode_back()
check(overlay.mode == "mp" and overlay.tab == "Custom", "Back did not reopen the custom editor")
check(MP.CUSTOM.draft.base == "Vanilla" and MP.modifiers_serialize() == selected, "Back changed the setup")

-- Use real start_lobby, stubbing only the transport and core reset boundary.
MP.reset_lobby_config = function()
	local config = MP.LOBBY.config
	MP.LOBBY.config = { ruleset = config.ruleset, gamemode = config.gamemode, timer = true }
end
SMODS.Mods.Multiplayer = { config = {} }
MP.Gamemodes.gamemode_mp_showdown = {}
MP.Gamemodes.gamemode_mp_attrition = {}
-- Production loads gamemodes before these generated forced-mode callbacks.
dofile("ui/main_menu/play_button/play_button_callbacks.lua")
MP.LOBBY.config.gamemode = "gamemode_mp_showdown"
local created
MP.ACTIONS.create_lobby = function(mode)
	created = mode
end
G.FUNCS.start_lobby()
check(created == "showdown", "custom launch ignored chosen gamemode")
check(MP.LOBBY.config.modifier_layers == selected, "lobby reset lost ordered modifiers")
check(MP.LOBBY.config.multiplayer_jokers == false, "lobby reset lost explicit content Off")

MP.LOBBY.code = "TEST"
MP.LOBBY.is_host = true
local host_lines = table.concat(MP.UI.lobby_rules_lines(), "\n")
check(host_lines:find("Chaos Clock: Normal", 1, true), "summary lost the clock preset")
check(host_lines:find("Glass: Legacy", 1, true), "summary lost the glass variant")
check(host_lines:find("Timer: Pressure+", 1, true), "summary lost compound timer variant")
check(not host_lines:find("pressure_timer_plus", 1, true), "summary duplicated the compound variant")
check(host_lines:find("MP Jokers: Off", 1, true), "summary lost explicit MP Jokers Off")
check(host_lines:find("Glass Cannon", 1, true), "summary lost registry labels")
local sent
Client.send = function(message)
	sent = message
end
MP.ACTIONS.lobby_options()
MP.MODIFIERS = {}
MP.LOBBY.config = {}
MP.LOBBY.is_host = false
-- A joining guest gets the same complete options payload through the real
-- dispatcher, not a second editor draft. The relay itself is not simulated.
love.thread.getChannel("networkToUi"):push(require("json").encode(sent))
Game:update(0)
MP.CUSTOM.draft = { base = "Sandbox" }
MP.MUTATORS_HIDDEN = true
check(MP.modifiers_serialize() == selected, "guest lost ordered modifiers")
check(table.concat(MP.UI.lobby_rules_lines(), "\n") == host_lines, "guest summary differs or reads local draft state")

local removed, recalculated = 0, 0
UIBox = function(args)
	args.remove = function()
		removed = removed + 1
	end
	return args
end
G.FUNCS.mp_view_lobby_rules()
local readout = find({ nodes = overlay.contents }, "func", "mp_lobby_rules_sync")
check(readout ~= nil, "View Rules did not build a live readout")
local e = {
	config = readout.config,
	UIBox = {
		recalculate = function()
			recalculated = recalculated + 1
		end,
	},
}
G.FUNCS.mp_lobby_rules_sync(e)
check(removed == 0, "unchanged readout rebuilt unnecessarily")
MP.set_multiplayer_jokers(true)
G.FUNCS.mp_lobby_rules_sync(e)
check(removed == 1 and recalculated == 1, "readout did not refresh after a lobby option changed")
check(e.config.ref_table.signature:find("MP Jokers: On", 1, true), "readout retained stale Off")

-- A full wall fits into at most three columns of twelve rows.
for name, def in pairs(MP.MUTATORS) do
	if not def.variants then MP.add_modifier(name) end
end
G.FUNCS.mp_view_lobby_rules()
readout = find({ nodes = overlay.contents }, "func", "mp_lobby_rules_sync")
check(#readout.config.object.definition.nodes <= 3, "full wall readout can overflow horizontally")
for _, column in ipairs(readout.config.object.definition.nodes) do
	check(#column.nodes <= 12, "readout can overflow vertically")
end

-- The forced-gamemode route still bypasses the picker.
MP.CUSTOM.draft.base = "Experimental"
MP.CUSTOM.editor_mode = "mp"
MP.LOBBY.code = nil
MP.LOBBY.config = {}
MP.MODIFIERS = { "clock_mayhem" }
G.FUNCS.mp_custom_play()
check(created == "attrition", "custom Experimental lost its forced gamemode")
check(MP.LOBBY.config.modifier_layers == "clock_mayhem", "forced route lost custom modifiers")
MP.CUSTOM.selecting_gamemode = false
G.FUNCS.mp_gamemode_back()
check(#MP.MODIFIERS == 0 and overlay.tab == nil, "ordinary gamemode Back no longer resets setup")

print(("Custom multiplayer: %d checks, 0 failed"):format(checks))
