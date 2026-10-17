--[[
  Mutator registry test.

  Loads every layer with stubbed globals and checks the custom editor's wall
  against the layers behind it:

    - every cell has a known category, a label and a description
    - no two cells claim the same (category, order) slot
    - every live cell's layer does something (bans, reworks, hooks, a flag, or
      vanilla game_modifiers)
    - every `flag` is read somewhere outside its own declaration
    - variant cells only point at registered layers
    - Chaos Clock specs (at / lasts / severity) valid and honourable, present on
      every switchable cell; the pool skips On cells

  Usage (repo root):  luajit tests/test_mutator_registry.lua
]]

local ROOT = "."

SMODS = {
	GameObject = {
		extend = function(_, t)
			return setmetatable(t, {
				__call = function(_, i)
					return i
				end,
			})
		end,
	},
	Mods = {},
}
G = { P_CENTER_POOLS = { Ruleset = {} }, localization = { descriptions = { Ruleset = {} } }, FUNCS = {} }
MP = {
	LOBBY = { config = {} },
	SP = {},
	DECK = {},
	UTILS = {},
	UI = {},
	EXPERIMENTAL = {},
	is_pvp_boss = function()
		return false
	end,
	should_use_the_order = function()
		return false
	end,
}
dofile(ROOT .. "/tests/_stubs.lua")

local function lua_files_in(dir)
	local files = {}
	local p = io.popen('ls "' .. dir .. '"/*.lua 2>/dev/null')
	for line in p:lines() do
		files[#files + 1] = line
	end
	p:close()
	table.sort(files, function(a, b)
		local a_under, b_under = a:match("/_[^/]*$") ~= nil, b:match("/_[^/]*$") ~= nil
		if a_under ~= b_under then return a_under end
		return a < b
	end)
	return files
end

dofile(ROOT .. "/lib/rng.lua")
for _, path in ipairs(lua_files_in(ROOT .. "/layers")) do
	dofile(path)
end

local CATEGORIES = { ECONOMY = true, MAYHEM = true, HAZARDS = true, CHAOS = true, JOKERS = true }

local failures, checks = {}, 0
local function check(cond, msg)
	checks = checks + 1
	if not cond then failures[#failures + 1] = msg end
end

local function has_effect(layer)
	if layer.on_apply_bans or layer.flag or layer.game_modifiers or layer.multiplayer_content then return true end
	for _, field in ipairs(MP._LAYER_ARRAY_FIELDS) do
		if layer[field] and #layer[field] > 0 then return true end
	end
	return false
end

local function repo_mentions(needle, excluding_line)
	local p = io.popen('grep -rn --include="*.lua" --include="*.toml" -F "' .. needle .. '" ' .. ROOT .. " 2>/dev/null")
	local hits = 0
	for line in p:lines() do
		if not line:find(excluding_line, 1, true) and not line:find("/tests/", 1, true) then hits = hits + 1 end
	end
	p:close()
	return hits
end

local slots = {}
local count = 0
for key, def in pairs(MP.MUTATORS) do
	count = count + 1
	check(CATEGORIES[def.category], key .. ": unknown category " .. tostring(def.category))
	check(type(def.label) == "string" and #def.label > 0, key .. ": missing label")
	check(type(def.desc) == "table" and #def.desc > 0, key .. ": missing desc")

	local slot = tostring(def.category) .. "#" .. tostring(def.order)
	check(not slots[slot], key .. ": shares slot " .. slot .. " with " .. tostring(slots[slot]))
	slots[slot] = key

	if def.variants then
		for _, v in ipairs(def.variants) do
			check(v.mod == nil or MP.Layers[v.mod], key .. ": variant points at unknown layer " .. tostring(v.mod))
		end
		check(not def.secret or MP.Layers[def.secret.mod], key .. ": secret variant points at unknown layer")
	else
		local layer = MP.Layers[key]
		check(layer, key .. ": no layer registered under the cell's key")
		if layer then check(has_effect(layer), key .. ": live cell, but its layer does nothing") end
		if layer and layer.flag then
			check(
				repo_mentions(layer.flag, 'flag = "' .. layer.flag .. '"') > 0,
				key .. ": flag " .. layer.flag .. " is never read"
			)
		end
	end
end
check(count > 0, "no mutators registered")

-- Switchability: runtime-only effects yes; bans / start-of-run setup no.
local SWITCHABLE = {
	score_instability = true,
	polymorph_spam = true,
	discard_tax = true,
	inflation = true,
	glass_cannon = true,
	no_red_seals = false, -- also bans Deja Vu
	no_uncommons = false,
	smallworld = false,
	shared_pockets = false,
	bigger_shop = false,
	sandbox_rotation = false,
}
for key, expected in pairs(SWITCHABLE) do
	check(MP.is_switchable(key) == expected, key .. ": is_switchable should be " .. tostring(expected))
end

-- Chaos Clock specs: valid at / lasts / severity; instants have `run`, windows
-- can be switched off; every switchable live cell has a spec (so nothing is
-- silently left out of the pool).
local function check_spec(key, spec)
	check(MP.CHAOS_CLOCK.AT[spec.at], key .. ": clock.at " .. tostring(spec.at) .. " unknown")
	check(MP.CHAOS_CLOCK.LASTS[spec.lasts], key .. ": clock.lasts " .. tostring(spec.lasts) .. " unknown")
	check(spec.severity == 1 or spec.severity == 2 or spec.severity == 3, key .. ": severity out of range")
	check(not spec.preset or MP.CHAOS_CLOCK.PRESETS[spec.preset], key .. ": unknown preset restriction")
	check(MP.CHAOS_CLOCK.eligible(key, spec), key .. ": clock spec can't be honoured (no run / not switchable)")
	-- apply() only switches the window it was drawn for, so a mismatched pick
	-- would be announced and never go live.
	check(
		spec.lasts == "instant" or spec.lasts == spec.at,
		key .. ": clock.lasts must be instant or match clock.at (" .. tostring(spec.at) .. ")"
	)
end
for key, def in pairs(MP.MUTATORS) do
	if def.clock then
		check_spec(key, def.clock)
	elseif not def.variants and MP.is_switchable(key) then
		check(false, key .. ": switchable but no clock spec, so the Chaos Clock never draws it")
	end
end
for key, ev in pairs(MP.CHAOS_CLOCK.EVENTS) do
	check(not MP.MUTATORS[key], key .. ": event key collides with a wall cell")
	check(ev.clock.lasts == "instant", key .. ": events are instant")
	check_spec(key, ev.clock)
end

-- Switching one layer off restores the baseline value of each game_modifier it
-- set, so two switchable layers sharing a key would clobber each other.
local modifier_owner = {}
for name, layer in pairs(MP.Layers) do
	if MP.is_switchable(name) then
		for k in pairs(layer.game_modifiers or {}) do
			check(not modifier_owner[k], k .. ": set by both " .. tostring(modifier_owner[k]) .. " and " .. name)
			modifier_owner[k] = name
		end
	end
end

-- Pool: On / ruleset-active cells are skipped; events always in.
local pool = MP.CHAOS_CLOCK.build_pool(function(k)
	return k == "glass_cannon"
end)
local function in_list(list, v)
	for _, x in ipairs(list) do
		if x == v then return true end
	end
	return false
end
check(not in_list(pool.ante.s2, "glass_cannon"), "skipped cell left out of the pool")
check(in_list(pool.blind.s2, "score_instability"), "blind cell in blind pool")
check(in_list(pool.blind.s1, "suit_storm"), "event in blind pool")
check(in_list(pool.ante.s3, "polymorph_spam"), "Polymorph is an ante instant")
check(not in_list(pool.blind.s3, "polymorph_spam"), "Polymorph cannot be drawn at blind start")
check(MP.MUTATORS.polymorph_spam.clock.preset == "mayhem", "Polymorph is Mayhem-only")
check(in_list(pool.ante.s3, "debuff_played_cards"), "ante cell in ante pool")
check(
	not in_list(pool.ante.s2, "no_uncommons") and not in_list(pool.ante.s1, "no_uncommons"),
	"ban layer never in the pool"
)

-- On state and the clock preset round-trip through the sync string.
MP.MODIFIERS = {}
MP.add_modifier("glass_cannon")
MP.add_modifier("clock_normal")
local wire = MP.modifiers_serialize()
MP.modifiers_parse(wire)
check(MP.has_modifier("glass_cannon"), "on state lost in serialize/parse: " .. wire)
check(MP.CHAOS_CLOCK.preset_key() == "normal", "clock preset lost in serialize/parse: " .. wire)
check(not MP.toggle_modifier("glass_cannon"), "toggle turns an on cell off")
check(not MP.has_modifier("glass_cannon"), "off state")

-- Variant cycles: the most specific match wins, the secret is index 0, and
-- setting one variant clears every other variant's mods.
local cycle = {
	variants = {
		{ label = "Off" },
		{ label = "A", mod = "test_a" },
		{ label = "A+", mod = { "test_a", "test_a_plus" } },
	},
	secret = { label = "S", mod = "test_s" },
}
MP.MODIFIERS = {}
check(select(2, MP.variant_of(cycle)) == 1, "no mods reads as the default")
MP.set_variant(cycle, cycle.variants[3])
check(select(2, MP.variant_of(cycle)) == 3, "A+ (two mods) isn't read as A")
MP.set_variant(cycle, cycle.variants[2])
check(not MP.has_modifier("test_a_plus"), "set_variant clears the other variant's extra mod")
check(select(2, MP.variant_of(cycle)) == 2, "A after A+")
MP.set_variant(cycle, cycle.secret)
check(select(2, MP.variant_of(cycle)) == 0 and not MP.has_modifier("test_a"), "secret is index 0, alone")
MP.set_variant(cycle, cycle.variants[1])
check(#MP.MODIFIERS == 0, "default clears everything")

print(("Mutator registry: %d mutators, %d checks, %d failed"):format(count, checks, #failures))
for _, f in ipairs(failures) do
	print("  FAIL " .. f)
end
os.exit(#failures == 0 and 0 or 1)
