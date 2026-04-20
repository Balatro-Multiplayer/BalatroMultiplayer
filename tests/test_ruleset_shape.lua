--[[
  Ruleset shape snapshot test.

  Usage:
    lua tests/test_ruleset_shape.lua capture   -- write baseline to tests/ruleset_shape.snapshot.lua
    lua tests/test_ruleset_shape.lua test       -- compare current rulesets against baseline

  Run from the repo root:
    cd stockholm && lua tests/test_ruleset_shape.lua capture
    cd stockholm && lua tests/test_ruleset_shape.lua test
]]

local mode = arg[1] or "test"
local SNAPSHOT_PATH = "tests/ruleset_shape.snapshot.lua"
local ROOT = "."

-- ─── Minimal stubs ──────────────────────────────────────────────────────────

-- Stub SMODS.GameObject:extend so MP.Ruleset works
SMODS = {
	GameObject = {
		extend = function(self, tbl)
			local cls = {}
			for k, v in pairs(tbl) do cls[k] = v end
			-- Make instances callable via cls({...})
			setmetatable(cls, {
				__call = function(_, init)
					local obj = {}
					-- copy class defaults
					for k, v in pairs(cls) do obj[k] = v end
					-- copy instance fields (overrides)
					for k, v in pairs(init) do obj[k] = v end
					return obj
				end,
			})
			return cls
		end,
	},
	process_loc_text = function() end,
	Mods = {},
}

G = {
	P_CENTER_POOLS = { Ruleset = {} },
	localization = { descriptions = { Ruleset = {} } },
}

MP = {
	LOBBY = { config = {} },
	SP = {},
	DECK = {
		BANNED_JOKERS = {},
		BANNED_CONSUMABLES = {},
		BANNED_VOUCHERS = {},
		BANNED_ENHANCEMENTS = {},
		BANNED_TAGS = {},
		BANNED_BLINDS = {},
	},
	UTILS = {
		check_smods_version = function() return false end,
		check_lovely_version = function() return false end,
		is_standard_ruleset = function() return false end,
	},
	UI = {
		CreateRulesetInfoMenu = function(opts) return opts end,
	},
	EXPERIMENTAL = { show_sandbox_collection = false },
	INSANE_INT = {},
	GAME = { enemy = { score = 0 } },
	is_ruleset_active = function() return false end,
	is_pvp_boss = function() return false end,
	should_use_the_order = function() return false end,
}

-- Stub functions used by sandbox/smallworld
function pseudoshuffle() end
function pseudoseed() return 0 end
function pseudorandom_element(t) return t[1] end

-- Stub globals used by speedlatro
Game = { update = function() end }
function new_round() end
function end_round() end

-- Stubs for smallworld runtime hooks
Tag = { init = function() end }
Back = { apply_to_run = function() end }
Card = { apply_to_run = function() end }
function add_joker() end

-- Stub SMODS.showman
SMODS.showman = function() return false end

-- ─── Load layers and rulesets ───────────────────────────────────────────────

local function lua_files_in(dir)
	local files = {}
	local p = io.popen('ls "' .. dir .. '"/*.lua 2>/dev/null')
	if p then
		for line in p:lines() do
			files[#files + 1] = line
		end
		p:close()
	end
	-- Sort with _prefixed files first (infrastructure before definitions)
	table.sort(files, function(a, b)
		local a_under = a:match("/_[^/]*$") ~= nil
		local b_under = b:match("/_[^/]*$") ~= nil
		if a_under ~= b_under then return a_under end
		return a < b
	end)
	return files
end

-- Load layers if they exist (post-refactor); pre-refactor rulesets work without them
for _, path in ipairs(lua_files_in(ROOT .. "/layers")) do
	dofile(path)
end

-- Load all rulesets
for _, path in ipairs(lua_files_in(ROOT .. "/rulesets")) do
	local ok, err = pcall(dofile, path)
	if not ok then
		io.stderr:write("WARN: failed to load " .. path .. ": " .. tostring(err) .. "\n")
	end
end

-- ─── Shape extraction ───────────────────────────────────────────────────────

-- Fields that define the "shape" of a ruleset (data, not functions)
local DATA_FIELDS = {
	-- Scalars
	"key",
	"multiplayer_content",
	"standard",
	"forced_gamemode",
	"forced_lobby_options",
	-- Ban arrays
	"banned_jokers",
	"banned_consumables",
	"banned_vouchers",
	"banned_enhancements",
	"banned_tags",
	"banned_blinds",
	"banned_silent",
	-- Rework arrays
	"reworked_jokers",
	"reworked_consumables",
	"reworked_vouchers",
	"reworked_enhancements",
	"reworked_tags",
	"reworked_blinds",
}

-- Function-valued fields we track the *presence* of (not the body)
local FUNCTION_FIELDS = {
	"create_info_menu",
	"force_lobby_options",
	"is_disabled",
}

local function sorted_keys(t)
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys)
	return keys
end

local function serialize_value(v, indent)
	indent = indent or ""
	local next_indent = indent .. "  "
	if type(v) == "table" then
		-- Check if array-like
		local is_array = true
		local max_i = 0
		for k in pairs(v) do
			if type(k) ~= "number" then is_array = false; break end
			if k > max_i then max_i = k end
		end
		if is_array and max_i == #v then
			-- Serialize as array
			if #v == 0 then return "{}" end
			local parts = {}
			for i, item in ipairs(v) do
				parts[#parts + 1] = next_indent .. serialize_value(item, next_indent)
			end
			return "{\n" .. table.concat(parts, ",\n") .. ",\n" .. indent .. "}"
		else
			-- Serialize as dict
			local keys = sorted_keys(v)
			if #keys == 0 then return "{}" end
			local parts = {}
			for _, k in ipairs(keys) do
				parts[#parts + 1] = next_indent .. "[" .. string.format("%q", k) .. "] = " .. serialize_value(v[k], next_indent)
			end
			return "{\n" .. table.concat(parts, ",\n") .. ",\n" .. indent .. "}"
		end
	elseif type(v) == "string" then
		return string.format("%q", v)
	elseif type(v) == "boolean" then
		return tostring(v)
	elseif type(v) == "number" then
		return tostring(v)
	elseif v == nil then
		return "nil"
	else
		return string.format("%q", tostring(v))
	end
end

local function extract_shape(ruleset)
	local shape = {}
	for _, field in ipairs(DATA_FIELDS) do
		local val = ruleset[field]
		if val ~= nil then
			if type(val) == "table" then
				-- Sort arrays for stable comparison
				local copy = {}
				for i, v in ipairs(val) do copy[i] = v end
				table.sort(copy)
				shape[field] = copy
			else
				shape[field] = val
			end
		end
	end
	-- Track which function fields are defined (with non-default values)
	shape["_has_functions"] = {}
	for _, field in ipairs(FUNCTION_FIELDS) do
		if type(ruleset[field]) == "function" then
			shape["_has_functions"][field] = true
		end
	end
	return shape
end

local function extract_all_shapes()
	local shapes = {}
	local keys = sorted_keys(MP.Rulesets)
	for _, key in ipairs(keys) do
		shapes[key] = extract_shape(MP.Rulesets[key])
	end
	return shapes
end

-- ─── Capture mode ───────────────────────────────────────────────────────────

local function backup_snapshot()
	local src = io.open(SNAPSHOT_PATH, "r")
	if not src then return end
	local content = src:read("*a")
	src:close()
	local bak_path = SNAPSHOT_PATH .. ".bak"
	local dst = assert(io.open(bak_path, "w"))
	dst:write(content)
	dst:close()
	print("Backed up previous snapshot to " .. bak_path)
end

local function write_snapshot(shapes)
	backup_snapshot()
	local f = assert(io.open(SNAPSHOT_PATH, "w"))
	f:write("-- Auto-generated ruleset shape snapshot. Do not edit.\n")
	f:write("-- Regenerate with: lua tests/test_ruleset_shape.lua capture\n")
	f:write("return " .. serialize_value(shapes) .. "\n")
	f:close()
	print("Snapshot written to " .. SNAPSHOT_PATH)
	print("Captured " .. #sorted_keys(shapes) .. " rulesets:")
	for _, k in ipairs(sorted_keys(shapes)) do
		print("  " .. k)
	end
end

-- ─── Test mode ──────────────────────────────────────────────────────────────

local function deep_equal(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do
		if not deep_equal(v, b[k]) then return false end
	end
	for k, v in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

local function diff_shapes(key, expected, actual)
	local diffs = {}
	-- Check all expected fields
	local all_fields = {}
	for _, field in ipairs(DATA_FIELDS) do all_fields[field] = true end
	all_fields["_has_functions"] = true

	for field in pairs(all_fields) do
		local e = expected[field]
		local a = actual[field]
		if not deep_equal(e, a) then
			diffs[#diffs + 1] = string.format(
				"  %s:\n    expected: %s\n    actual:   %s",
				field,
				serialize_value(e),
				serialize_value(a)
			)
		end
	end
	return diffs
end

local function run_test()
	local ok, baseline = pcall(dofile, SNAPSHOT_PATH)
	if not ok then
		io.stderr:write("ERROR: No snapshot found at " .. SNAPSHOT_PATH .. "\n")
		io.stderr:write("Run 'lua tests/test_ruleset_shape.lua capture' first.\n")
		os.exit(1)
	end

	local current = extract_all_shapes()
	local passed = 0
	local failed = 0
	local errors = {}

	-- Check for missing rulesets
	for _, key in ipairs(sorted_keys(baseline)) do
		if not current[key] then
			failed = failed + 1
			errors[#errors + 1] = string.format("MISSING ruleset: %s", key)
		end
	end

	-- Check for unexpected new rulesets
	for _, key in ipairs(sorted_keys(current)) do
		if not baseline[key] then
			failed = failed + 1
			errors[#errors + 1] = string.format("UNEXPECTED new ruleset: %s", key)
		end
	end

	-- Compare shapes
	for _, key in ipairs(sorted_keys(baseline)) do
		if current[key] then
			local diffs = diff_shapes(key, baseline[key], current[key])
			if #diffs == 0 then
				passed = passed + 1
			else
				failed = failed + 1
				errors[#errors + 1] = string.format("CHANGED ruleset: %s\n%s", key, table.concat(diffs, "\n"))
			end
		end
	end

	-- Report
	print(string.format("\nRuleset shape test: %d passed, %d failed", passed, failed))
	if #errors > 0 then
		print("\nFailures:")
		for _, err in ipairs(errors) do
			print("\n" .. err)
		end
		os.exit(1)
	else
		print("All ruleset shapes match baseline.")
	end
end

-- ─── Main ───────────────────────────────────────────────────────────────────

if mode == "capture" then
	write_snapshot(extract_all_shapes())
elseif mode == "test" then
	run_test()
else
	io.stderr:write("Usage: lua tests/test_ruleset_shape.lua [capture|test]\n")
	os.exit(1)
end
