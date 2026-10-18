-- Native MP content: register the actual cards, compare pool slots across live
-- and local contexts, and exercise lobby/replay configuration at the boundary.
-- Run from the repo root: luajit tests/test_multiplayer_content.lua

G = { P_CENTERS = {}, P_CENTER_POOLS = {}, localization = { descriptions = { Ruleset = {} } }, FUNCS = {}, UIT = {} }
SMODS = {
	Mods = {},
	Atlas = function() end,
	GameObject = {
		extend = function(_, cls)
			return setmetatable(cls, {
				__call = function(c, init)
					for _, key in ipairs(c.required_params) do
						assert(init[key] ~= nil, init.key .. ": missing required " .. key)
					end
					init.key = "ruleset_mp_" .. init.key
					return setmetatable(init, { __index = c })
				end,
			})
		end,
	},
}
local function card_class(prefix)
	return setmetatable({
		register = function(self)
			G.P_CENTERS[self.key] = self
			return self
		end,
	}, {
		__call = function(cls, def)
			def.key = prefix .. def.key
			setmetatable(def, { __index = cls })
			return def:register()
		end,
	})
end
SMODS.Joker, SMODS.Consumable = card_class("j_mp_"), card_class("c_mp_")
MP = {
	LOBBY = { config = {} },
	ACTIONS = {},
	UI = {},
	UTILS = {},
	EXPERIMENTAL = {},
	GAME = { pincher_unlock = true },
	Gamemodes = {},
}
MP.DECK = {}
for _, category in ipairs({ "JOKERS", "CONSUMABLES", "VOUCHERS", "ENHANCEMENTS", "TAGS", "BLINDS" }) do
	MP.DECK["BANNED_" .. category] = {}
end
dofile("tests/_stubs.lua")
dofile("lib/practice_mode.lua")
dofile("lib/ghost_replay.lua")
dofile("lib/rng.lua")

local paths = {}
local files = assert(io.popen("ls layers/*.lua"))
for path in files:lines() do
	paths[#paths + 1] = path
end
files:close()
table.sort(paths)
for _, path in ipairs(paths) do
	dofile(path)
end
dofile("rulesets/_rulesets.lua")
for _, name in ipairs({
	"vanilla",
	"blitz",
	"traditional",
	"smallworld",
	"speedlatro",
	"ranked",
	"sandbox",
	"chaos",
	"badlatro",
	"experimental/experimental",
	"experimental/experimental_legacy",
	"legacy_ranked",
	"majorleague",
	"minorleague",
	"wsob",
}) do
	dofile("rulesets/" .. name .. ".lua")
end

local content = MP.Layers.multiplayer_jokers
local keys = {}
for _, key in ipairs(content.included_jokers) do
	keys[#keys + 1] = key
	dofile("objects/jokers/" .. key:gsub("^j_mp_", "") .. ".lua")
end
for _, key in ipairs(content.included_consumables) do
	keys[#keys + 1] = key
	dofile("objects/consumables/" .. key:gsub("^c_mp_", "") .. ".lua")
end
dofile("objects/jokers/sandbox/magnet_sandbox.lua")
table.sort(keys)

local checks = 0
local function check(cond, message)
	checks = checks + 1
	assert(cond, message)
end

local function context(short, mode, modifiers)
	MP.GHOST.clear()
	MP.SP.practice = mode == "practice"
	MP.SP.ruleset = mode ~= "live" and ("ruleset_mp_" .. short) or nil
	MP.LOBBY.code = mode == "live" and "TEST" or nil
	MP.LOBBY.config = { ruleset = mode == "live" and ("ruleset_mp_" .. short) or nil, multiplayer_jokers = false }
	MP.modifiers_parse(modifiers)
	G.GAME = { banned_keys = {}, modifiers = {}, round_resets = { ante = 1 }, pseudorandom = { seed = "PARITY" } }
	MP.ApplyBans()
end

-- Model vanilla's banned UNAVAILABLE slot and Lovely's subsequent mp_include
-- removal. Off must remove slots, rather than replace cards with bans.
local function pool()
	local slots = { "j_joker" }
	for _, key in ipairs(keys) do
		if not MP.should_exclude_from_pool(G.P_CENTERS[key]) then
			slots[#slots + 1] = G.GAME.banned_keys[key] and "UNAVAILABLE" or key
		end
	end
	return table.concat(slots, ",")
end

-- Reference pool for legacy MP-content-enabled runs: all original cards except
-- Conjoined in Sandbox. Slot order must match to preserve seeded shop selection.
local function legacy_pool(sandbox)
	local slots = { "j_joker" }
	for _, key in ipairs(keys) do
		if not (sandbox and key == "j_mp_conjoined_joker") then
			slots[#slots + 1] = G.GAME.banned_keys[key] and "UNAVAILABLE" or key
		end
	end
	return table.concat(slots, ",")
end

for _, key in ipairs(keys) do
	check(type(G.P_CENTERS[key].mp_include) == "function", key .. ": registration did not attach a gate")
end
check(#keys == 10, "expected nine jokers and Asteroid")
check(content.reworked_jokers == nil, "original content must not be described as reworks")

for _, short in ipairs({ "blitz", "sandbox", "experimental", "experimental_legacy", "badlatro" }) do
	context(short, "live")
	local expected = pool()
	check(expected ~= "j_joker", short .. ": native layer did not include content")
	check(expected == legacy_pool(MP.is_layer_active("sandbox")), short .. ": changed the original live pool slots")
	for _, mode in ipairs({ "solo", "practice" }) do
		context(short, mode)
		check(MP.get_active_ruleset() == "ruleset_mp_" .. short, mode .. ": wrong active ruleset")
		check(pool() == expected, short .. ": " .. mode .. " changed the live pool slots")
	end
end

for _, short in ipairs({ "vanilla", "legacy_ranked", "majorleague", "minorleague", "wsob" }) do
	context(short, "practice")
	check(pool() == "j_joker", short .. ": content appeared without the native layer")
end

context("vanilla", "solo", "multiplayer_jokers")
check(MP.multiplayer_jokers_enabled(), "Vanilla + On should enable content without a lobby")
for _, key in ipairs(keys) do
	check(not MP.should_exclude_from_pool(G.P_CENTERS[key]), "Vanilla + On excluded " .. key)
end
local explicit_on = pool()
context("vanilla", "live", "multiplayer_jokers")
check(pool() == explicit_on, "Vanilla + On differs between local and live contexts")

context("blitz", "practice", "no_multiplayer_jokers")
check(not MP.multiplayer_jokers_enabled(), "Off must suppress inherited content")
check(pool() == "j_joker", "Off left UNAVAILABLE slots in the pool")
check(not G.GAME.banned_keys.j_mp_taxes, "Off must not create bans")
for _, key in ipairs(keys) do
	check(MP.should_exclude_from_pool(G.P_CENTERS[key]), "Off failed to exclude " .. key)
end
context("experimental_legacy", "practice", "no_multiplayer_jokers")
check(pool() == "j_joker", "legacy rework membership bypassed Off")

context("sandbox", "practice", "sandbox_retired")
check(MP.should_exclude_from_pool(G.P_CENTERS.j_mp_conjoined_joker), "Conjoined's sandbox exclusion was lost")
check(not MP.should_exclude_from_pool(G.P_CENTERS.j_mp_magnet_sandbox), "Retired sandbox content should include Magnet")
MP.set_multiplayer_jokers(false)
check(MP.should_exclude_from_pool(G.P_CENTERS.j_mp_magnet_sandbox), "Off should also suppress Magnet")

local cycle = MP.MUTATORS.multiplayer_jokers
MP.set_variant(cycle, cycle.variants[1])
check(MP.multiplayer_jokers_enabled(), "Base should restore Sandbox's content")
check(not MP.has_modifier("no_multiplayer_jokers"), "Base retained Off")
MP.set_variant(cycle, cycle.variants[2])
MP.set_variant(cycle, cycle.variants[3])
check(not MP.has_modifier("multiplayer_jokers"), "On and Off must be mutually exclusive")

-- Drive the actual wall callback through Base -> On -> Off -> Base.
mix_colours = function(a)
	return a
end
play_sound = function() end
love = { keyboard = {
	isDown = function()
		return false
	end,
} }
dofile("ui/main_menu/play_button/_mutators_wall.lua")
context("blitz", "practice")
local button = { config = { ref_table = { def = cycle } }, juice_up = function() end }
G.FUNCS.mp_toggle_mutator(button)
check(MP.has_modifier("multiplayer_jokers") and MP.multiplayer_jokers_enabled(), "wall Base -> On failed")
G.FUNCS.mp_toggle_mutator(button)
check(MP.has_modifier("no_multiplayer_jokers") and not MP.multiplayer_jokers_enabled(), "wall On -> Off failed")
G.FUNCS.mp_toggle_mutator(button)
check(#MP.MODIFIERS == 0 and MP.multiplayer_jokers_enabled(), "wall Off -> Base failed")

-- Round-trip configuration through the actual lobby sender and dispatcher.
local messages, next_id = {}, 0
local json = {
	encode = function(value)
		next_id = next_id + 1
		local id = "message_" .. next_id
		messages[id] = value
		return id
	end,
	decode = function(id)
		return assert(messages[id])
	end,
}
package.loaded.json = json
local channels = {}
love = {
	thread = {
		getChannel = function(name)
			if not channels[name] then
				local queue = {}
				channels[name] = {
					push = function(_, value)
						queue[#queue + 1] = value
					end,
					pop = function()
						return table.remove(queue, 1)
					end,
				}
			end
			return channels[name]
		end,
	},
}
Game.update = function() end
sendTraceMessage = function() end
sendWarnMessage = function() end
dofile("networking/action_handlers.lua")
MP.ACTIONS.update_player_usernames = function() end

context("blitz", "live")
MP.set_multiplayer_jokers(false)
MP.ACTIONS.lobby_options()
local sent = json.decode(channels.uiToNetwork:pop())
check(sent.multiplayer_jokers == false, "wire boolean must reflect native Off")
check(MP.modifiers_wire_decode(sent.modifier_layers) == "no_multiplayer_jokers", "wire modifiers lost Off")
context("vanilla", "live")
channels.networkToUi:push(json.encode(sent))
Game:update(0)
check(pool() == "j_joker", "guest did not reconstruct the host's Off pool")

local function receive(options)
	options.action = "lobbyOptions"
	channels.networkToUi:push(json.encode(options))
	Game:update(0)
end
context("blitz", "live")
receive({ multiplayer_jokers = "false" })
check(not MP.multiplayer_jokers_enabled(), "legacy false did not override an inherited layer")
context("vanilla", "live")
receive({ multiplayer_jokers = "true" })
check(MP.multiplayer_jokers_enabled(), "legacy true did not enable the native layer")
receive({ modifier_layers = "pvp_timer,multiplayer_jokers,glass_vanilla", multiplayer_jokers = true })
check(MP.modifiers_serialize() == "pvp_timer,multiplayer_jokers,glass_vanilla", "import changed modifier ordering")
receive({ modifier_layers = "no_multiplayer_jokers,pvp_timer" })
check(not MP.LOBBY.config.multiplayer_jokers, "native-only update did not refresh the legacy view")

-- Every registered layer fits in one server-capped field, in either order.
-- This also catches new layers missing an explicit, stable wire ID.
local all_layers = {}
for name in pairs(MP.Layers) do
	all_layers[#all_layers + 1] = name
end
table.sort(all_layers)
MP.MODIFIERS = all_layers
local readable = MP.modifiers_serialize()
local packed = MP.modifiers_wire_encode()
check(#packed <= 64, "full layer registry exceeds the relay limit")
check(MP.modifiers_wire_decode(packed:sub(1, 64)) == readable, "relay cap changed the selection")
check(MP.modifiers_wire_decode("v1:00") == "", "empty compact selection failed")
check(MP.modifiers_wire_decode(readable) == readable, "legacy names no longer accepted")
check(not pcall(MP.modifiers_wire_decode, packed:sub(1, -2)), "truncated payload accepted")
check(not pcall(MP.modifiers_wire_decode, "v1:01!"), "unknown ID accepted")
check(not pcall(MP.modifiers_wire_decode, "v2:00"), "unknown version accepted")
MP.MODIFIERS = { "bigger_shop", "wraith_rework", "debuff_played_cards", "eeeee", "smallworld" }
local ordered = MP.modifiers_serialize()
MP.ACTIONS.lobby_options()
local compact_options = json.decode(channels.uiToNetwork:pop())
check(#compact_options.modifier_layers <= 64, "sender did not compact modifiers")
check(MP.LOBBY.config.modifier_layers == ordered, "sender compacted local state")
MP.MODIFIERS = {}
receive(compact_options)
check(MP.modifiers_serialize() == ordered, "guest lost modifier order through actual dispatch")
check(MP.LOBBY.config.modifier_layers == ordered, "guest retained compact wire state")
for _, selection in ipairs({
	"inflation,discard_tax,frugal,bigger_shop,smallworld,pricey_packs,sandbox_retired,sandbox_extra_credit,idol_collector,wraith_rework,polymorph_spam",
	"no_interest,gambling_opportunity,no_red_seals,smallworld,eeeee,debuff_played_cards,wraith_rework,bigger_shop",
}) do
	MP.modifiers_parse(selection)
	MP.ACTIONS.lobby_options()
	local options = json.decode(channels.uiToNetwork:pop())
	options.modifier_layers = options.modifier_layers:sub(1, 64)
	MP.MODIFIERS = {}
	receive(options)
	check(MP.modifiers_serialize() == selection, "recorded lobby selection did not survive relay cap")
end
MP.MODIFIERS = { "no_animation_timer", "pressure_timer" }
check(MP.modifiers_wire_encode() == "v1:0201", "stable wire IDs changed")
MP.GHOST.load({ ruleset = "ruleset_mp_vanilla", modifier_layers = "v1:0201" })
check(MP.modifiers_serialize() == "no_animation_timer,pressure_timer", "compact lobby logs broke ghost replay")
context("blitz", "live")

-- The existing checkbox now edits the same native choice as the wall.
MP.UI.Disableable_Toggle = function(args)
	return args
end
MP.UI.Disableable_Option_Cycle = function(args)
	return args
end
dofile("ui/lobby/_lobby_options/options_tab.lua")
local toggle = MP.UI.create_lobby_options_tab().nodes[2].nodes[1]
MP.LOBBY.config.multiplayer_jokers = true
toggle.callback()
check(MP.multiplayer_jokers_enabled(), "lobby checkbox did not enable the layer")
check(not MP.has_modifier("no_multiplayer_jokers"), "lobby checkbox retained Off")

-- Recorded modifiers and legacy booleans survive parsing and ghost loading.
local parser = dofile("lib/log_parser.lua")
local records = parser.process_log(table.concat({
	"MULTIPLAYER Client got lobbyOptions message: (ruleset: ruleset_mp_blitz) (modifier_layers: pvp_timer,no_multiplayer_jokers) (multiplayer_jokers: false)",
	"MULTIPLAYER Client got startGame message: (seed: PARITY)",
	"MULTIPLAYER Client got winGame message:",
}, "\n"))
local replay = parser.to_replay(assert(records[1], "parser did not produce a replay"))
check(replay.multiplayer_jokers == false, "parser lost recorded false")
check(replay.modifier_layers == "pvp_timer,no_multiplayer_jokers", "parser lost recorded modifiers")
context("vanilla", "practice", "multiplayer_jokers")
MP.GHOST.load(replay)
check(MP.GHOST.is_active(), "ghost failed to load")
check(MP.SP.ruleset == "ruleset_mp_blitz", "ghost did not restore its ruleset")
check(MP.has_modifier("pvp_timer"), "ghost lost another recorded modifier")
check(not MP.multiplayer_jokers_enabled(), "ghost lost recorded Off")
MP.GHOST.load({ ruleset = "ruleset_mp_vanilla", multiplayer_jokers = true })
check(MP.multiplayer_jokers_enabled(), "older replay's boolean did not enable content")
MP.GHOST.load({ ruleset = "ruleset_mp_blitz" })
check(MP.multiplayer_jokers_enabled(), "replay without content fields should use the ruleset default")
MP.GHOST.load({ ruleset = "ruleset_mp_vanilla", modifier_layers = "multiplayer_jokers" })
check(MP.multiplayer_jokers_enabled(), "native-only replay did not restore On")

G.SETTINGS = {}
G.UIDEF = {
	ruleset_selection_tabs = function()
		return {}
	end,
}
G.FUNCS.overlay_menu = function() end
dofile("ui/main_menu/play_button/play_button_callbacks.lua")
G.FUNCS.create_lobby()
check(MP.SP.ruleset == nil, "entering lobby setup retained the local ruleset")
check(MP.get_active_ruleset() == nil, "local ruleset leaked into lobby setup")

print(("Multiplayer content: %d checks, 0 failed"):format(checks))
