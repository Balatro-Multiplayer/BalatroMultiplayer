MP.MOD_HASH = "0000"
MP.MOD_STRING = ""

function hash(str)
	local str_to_hash = str or "0000"
	local hash = 0
	for i = 1, #str_to_hash do
		local char = string.byte(str_to_hash, i)
		hash = (hash * 31 + char) % 10000
	end
	return string.format("%04d", hash)
end

local function get_mod_data()
	local mod_table = {}
	for key, mod in pairs(SMODS.Mods) do
		if not mod.disabled and key ~= "Balatro" then table.insert(mod_table, key .. "-" .. (mod.version or "UNK")) end
	end
	for key, mod in pairs(MP.INTEGRATIONS) do
		if mod then table.insert(mod_table, key .. "-MultiplayerIntegration") end
	end
	return mod_table
end

function MP:generate_hash()
	local mod_data = get_mod_data()
	table.sort(mod_data)
	table.insert(mod_data, 1, "serversideConnectionID=" .. tostring(MP.UTILS.server_connection_ID()))
	table.insert(mod_data, 1, "encryptID=" .. tostring(MP.UTILS.encrypt_ID()))
	SMODS.Mods["Multiplayer"].config.unlocked = MP.UTILS.unlock_check()
	table.insert(mod_data, 1, "unlocked=" .. tostring(SMODS.Mods["Multiplayer"].config.unlocked))
	table.insert(mod_data, 1, "preview=" .. tostring(SMODS.Mods["Multiplayer"].config.integrations.Preview))
	local mod_string = table.concat(mod_data, ";")
	MP.MOD_STRING = mod_string
	MP.MOD_HASH = hash(mod_string) or "0000"
    if MP.ACTIONS.set_username then
        MP.ACTIONS.set_username(MP.LOBBY.username)
    end
end

local hash_generated = false

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	game_update_ref(self, dt)

	if not hash_generated and SMODS.booted then
		MP:generate_hash()
		hash_generated = true
	end
end

function MP.UTILS.unlock_check()
	local notFullyUnlocked = false

	for k, v in pairs(G.P_CENTER_POOLS.Joker) do
		if not v.unlocked then
			notFullyUnlocked = true
			break -- No need to keep checking once we know it's not fully unlocked
		end
	end

	return not notFullyUnlocked
end

function MP.UTILS.encrypt_ID()
	local encryptID = 1
	for key, center in pairs(G.P_CENTERS or {}) do
		if type(key) == "string" and key:match("^j_") then
			if center.cost and type(center.cost) == "number" then encryptID = encryptID + center.cost end
			if center.config and type(center.config) == "table" then
				encryptID = encryptID + MP.UTILS.sum_numbers_in_table(center.config)
			end
		elseif type(key) == "string" and key:match("^[cvp]_") then
			if center.cost and type(center.cost) == "number" then
				if center.cost == 0 then return 0 end
				encryptID = encryptID + center.cost
			end
		end
	end
	for key, value in pairs(G.GAME.starting_params or {}) do
		if type(value) == "number" and value % 1 == 0 then encryptID = encryptID * value end
	end
	local day = tonumber(os.date("%d")) or 1
	encryptID = encryptID * day
	local gameSpeed = G.SETTINGS.GAMESPEED
	if gameSpeed then
		gameSpeed = gameSpeed * 16
		gameSpeed = gameSpeed + 7
		encryptID = encryptID + (gameSpeed / 1000)
	else
		encryptID = encryptID + 0.404
	end
	return encryptID
end

-- Parses a semicolon-delimited hash string containing client configuration data
--
-- Input format: "encryptID=123456;unlocked=true;ModName1-1.0.0;ModName2-2.1.0;serversideConnectionID=abc123"
--
-- Returns:
--   config (table): Parsed configuration object with structure:
--     {
--       encryptID = number,     -- Client's encryption ID
--       unlocked = boolean,     -- Whether client has all content unlocked
--       Mods = table           -- Parsed mod list (see parse_modlist for structure)
--     }
--   mod_string (string): Semicolon-delimited string of mod entries only (for backward compatibility)
function MP.UTILS.parse_Hash(hash)
	local parts = {}
	for part in string.gmatch(hash, "([^;]+)") do
		table.insert(parts, part)
	end

	local config = {
		encryptID = nil,
		unlocked = nil,
		Mods = {},
	}

	local mod_data = {}

	for _, part in ipairs(parts) do
		local key, val = string.match(part, "([^=]+)=([^=]+)")
		if key == "encryptID" then
			config.encryptID = tonumber(val)
		elseif key == "unlocked" then
			config.unlocked = val == "true"
		elseif key ~= "serversideConnectionID" then
			table.insert(mod_data, part)
		end
	end

	config.Mods = MP.UTILS.parse_modlist(mod_data)
	-- this is for backwards compatibility
	-- We don't need to return mod_string anymore; can use config.Mods as a cleaner interface for the host/guest's mods
	-- and hash this in what we send to the server instead
	local mod_string = table.concat(mod_data, ";")

	return config, mod_string
end

-- Parses an array of mod entries into a mod table
--
-- Input: Array of mod entry strings: {"ModName1-1.0.0", "ModName2-2.1.0", "ModName3"}
--
-- Returns:
--   mods (table): Key-value pairs where:
--     - key = mod name (string)
--     - value = mod version (string) or nil if no version specified
--
-- Example output:
--   {
--     ModName1 = "1.0.0",
--     ModName2 = "2.1.0",
--     ModName3 = nil
--   }
function MP.UTILS.parse_modlist(mod_entries)
	if not mod_entries then return {} end

	local mods = {}

	for _, mod_entry in ipairs(mod_entries) do
		local mod_name, mod_version

		-- Split on the LAST dash to handle mod names with dashes (e.g., "lovely-compat-trance-v0.0.0")
		mod_name, mod_version = string.match(mod_entry, "^(.-)%-([^%-]*)$")
		if not mod_name then
			-- No dash found, entire string is mod name
			mod_name = mod_entry
			mod_version = nil
		end

		mods[mod_name] = mod_version
	end

	return mods
end

function MP.UTILS.resolve_mod_name_and_version(mod_name, mod_version)
    local fullname = mod_name .. "-" .. (mod_version or "")
    local new_mod_name, new_mod_version = fullname:match("^(.*)%-([^~]+~.*)$")
    mod_name = new_mod_name or mod_name
    mod_version = new_mod_version or mod_version
    return mod_name, mod_version
end

-- "0.4.0~pre1-DEV" -> "0.4.0". nil if no leading numeric version.
function MP.UTILS.version_prefix(version)
	if type(version) ~= "string" then return nil end
	return version:match("^(%d+%.%d+%.%d+)") or version:match("^(%d+%.%d+)")
end

-- Reads from hash_str, not the parsed Mods table: parse_modlist splits on the last dash
-- and would mangle versions that contain dashes (e.g. the -DEV suffix).
function MP.UTILS.player_mod_version(player, mod_name)
	if not player or not player.hash_str then return nil end
	return (";" .. player.hash_str):match(";" .. mod_name .. "%-([^;]+)")
end

function MP.UTILS.mp_version_mismatch()
	local other = MP.LOBBY.is_host and MP.LOBBY.guest or MP.LOBBY.host
	local their_version = other and MP.UTILS.player_mod_version(other, "Multiplayer")
	if not their_version then return false end
	local our_version = SMODS.Mods["Multiplayer"].version
	local our_prefix = MP.UTILS.version_prefix(our_version)
	local their_prefix = MP.UTILS.version_prefix(their_version)
	if our_prefix and their_prefix and our_prefix ~= their_prefix then
		return true, our_version, their_version
	end
	return false
end

-- Multiplayer compares on the X.Y.Z prefix (clean semver); Steamodded on the full string
-- (its ~BETA-<build> suffix makes any difference worth flagging).
local VERSION_CHECKS = {
	{ name = "Multiplayer", prefix = true },
	{ name = "Steamodded", prefix = false },
}

-- Returns { mod, our, their } for each checked mod whose version differs from the opponent's.
function MP.UTILS.version_mismatches()
	local other = MP.LOBBY.is_host and MP.LOBBY.guest or MP.LOBBY.host
	if not other then return {} end

	local results = {}
	for _, check in ipairs(VERSION_CHECKS) do
		local their_version = MP.UTILS.player_mod_version(other, check.name)
		local our_version = SMODS.Mods[check.name] and SMODS.Mods[check.name].version
		if their_version and our_version then
			local mismatch
			if check.prefix then
				local op = MP.UTILS.version_prefix(our_version)
				local tp = MP.UTILS.version_prefix(their_version)
				mismatch = op and tp and op ~= tp
			else
				mismatch = our_version ~= their_version
			end
			if mismatch then
				table.insert(results, { mod = check.name, our = our_version, their = their_version })
			end
		end
	end
	return results
end

-- Mod-policy keys are matched case- and punctuation-insensitively, so staff can
-- key the banned/approved lists by display name (e.g. "Joker Display") and still
-- match the wire-reported SMODS id (e.g. "JokerDisplay" or "jokerdisplay").
function MP.UTILS.normalize_mod_name(name)
	if type(name) ~= "string" then return "" end
	return (name:lower():gsub("[^%w]", ""))
end

-- Cache the normalized index per source table; keyed weakly by table identity so
-- it auto-refreshes when the server replaces MP.BANNED_MODS / MP.APPROVED_MODS.
local _norm_index_cache = setmetatable({}, { __mode = "k" })
local function normalized_index(map)
	if type(map) ~= "table" then return {} end
	local cached = _norm_index_cache[map]
	if cached then return cached end
	local idx = {}
	for k, v in pairs(map) do
		idx[MP.UTILS.normalize_mod_name(k)] = v
	end
	_norm_index_cache[map] = idx
	return idx
end

-- A rule version matches the wire version on exact string OR on the X.Y.Z
-- (clean semver) prefix, so a rule like "1.0.0" still matches "1.0.0~BETA-1620a"
-- or "1.0.0-DEV". version_prefix is defined earlier in this file.
local function version_matches(rule_version, version)
	if version == rule_version then return true end
	local rp = MP.UTILS.version_prefix(rule_version)
	local vp = MP.UTILS.version_prefix(version)
	return rp ~= nil and rp == vp
end

-- A rule is true (any version), an exact version string, or a list of versions.
local function rule_matches(rule, version)
	if rule == nil then return false end
	if type(rule) == "boolean" then return rule end
	if type(rule) == "string" then return version_matches(rule, version) end
	if type(rule) == "table" then
		for _, v in ipairs(rule) do
			if version_matches(v, version) then return true end
		end
	end
	return false
end

-- A version-like segment starts with a digit, 'v', or '~' (e.g. "0.2.2", "v1",
-- "~BETA"). Used to guess where a mod id ends and its version begins.
local function looks_like_version(seg)
	return seg ~= nil and seg:match("^[%dv~]") ~= nil
end

-- Matches a parsed mod entry against a normalized index. A mod's version can
-- contain dashes (e.g. Saturn "0.2.2-E-ALPHA"), and parse_modlist splits on the
-- last dash, so mod_name can arrive with version fragments glued on
-- ("Saturn-0.2.2-E"). Walk the dash-delimited prefixes and treat a prefix as the
-- id only when the next segment looks like a version — so "Saturn|0.2.2" splits
-- but a genuinely dashed id like "Saturn-Extras|1.0" stays intact. First (shortest)
-- valid match wins. Heuristic, not airtight; special-case real collisions if any
-- ever show up.
local function index_match(idx, mod_name, mod_version)
	local segs = {}
	for seg in tostring(mod_name):gmatch("[^%-]+") do
		segs[#segs + 1] = seg
	end
	local candidate
	for i = 1, #segs do
		candidate = candidate and (candidate .. "-" .. segs[i]) or segs[i]
		if segs[i + 1] == nil or looks_like_version(segs[i + 1]) then
			if rule_matches(idx[MP.UTILS.normalize_mod_name(candidate)], mod_version) then return true end
		end
	end
	return false
end

-- Returns "banned" | "approved" | "unknown". Banned takes precedence.
function MP.UTILS.classify_mod(mod_name, mod_version)
	if index_match(normalized_index(MP.BANNED_MODS), mod_name, mod_version) then return "banned" end
	if index_match(normalized_index(MP.APPROVED_MODS), mod_name, mod_version) then return "approved" end
	return "unknown"
end

function MP.UTILS.get_banned_mods(mods)
	local banned_mods = {}
	if not mods then return banned_mods end

	local idx = normalized_index(MP.BANNED_MODS)
	for mod_name, mod_version in pairs(mods) do
		if index_match(idx, mod_name, mod_version) then
			table.insert(banned_mods, mod_name)
		end
	end

	return banned_mods
end

function MP.UTILS.sum_numbers_in_table(t)
	local sum = 0
	for k, v in pairs(t) do
		if type(v) == "number" then
			sum = sum + v
		elseif type(v) == "table" then
			sum = sum + MP.UTILS.sum_numbers_in_table(v)
		end
		-- ignore other types
	end
	return sum
end
