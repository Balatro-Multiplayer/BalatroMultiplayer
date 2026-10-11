-- ----------------------------------------------------------------------------
-- ReworkCenter: per-layer property overrides on vanilla objects
-- ----------------------------------------------------------------------------
-- Every apply rebuilds each reworked property from a snapshot of vanilla taken
-- at load, then folds the layer chain on top. Live state is a function of the
-- chain alone, so no call history can leave two clients disagreeing.
--
-- Lifecycle:
--   load        MP.ReworkCenter(key, opts) queues a declaration
--   injectItems the queue drains: vanilla snapshot + per-layer patches
--   menu        MP.ApplyReworks(chain) — preview, freely; the run overwrites it
--   start_run   MP.BeginRunReworks(chain) — apply and lock for the run
--   main_menu   MP.EndRunReworks() — unlock, back to vanilla

local ABSENT = {} -- snapshot marker: vanilla had no value for this prop

local TABLE_IDS = { "P_CENTERS", "P_TAGS", "P_SEALS", "P_STAKES", "P_BLINDS", "PokerHands" }

local function get_table(table_id)
	if table_id == "PokerHands" then return SMODS.PokerHands end
	return G[table_id]
end

-- opts.center_table is a table ref, a G.* name, or nil (P_CENTERS).
local function table_id_of(center_table)
	if center_table == nil then return "P_CENTERS" end
	for _, id in ipairs(TABLE_IDS) do
		if center_table == id or center_table == get_table(id) then return id end
	end
	return nil
end

local function copy(v, seen)
	if type(v) ~= "table" then return v end
	seen = seen or {}
	if seen[v] then return seen[v] end
	local out = {}
	seen[v] = out
	for k, vv in pairs(v) do
		out[k] = copy(vv, seen)
	end
	return out
end

local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			merge(dst[k], v)
		else
			dst[k] = copy(v)
		end
	end
end

local function sorted_keys(t)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return keys
end

local pending = {} -- { { key, opts }, ... } until injectItems
local drained = false
local vanilla = {} -- [table_id][key][prop] = deep copy | ABSENT
local patches = {} -- [table_id][key][layer] = { props, silent }
local pool_snapshot = {} -- [bucket] = { center, ... } for buckets a rarity rework touches
local locked_chain = nil -- set for the length of a run
local written_chain = {} -- what the live tables currently hold

---@param key string e.g. "m_glass"
---@param opts table { layers, center_table?, loc_key?, silent?, ...center properties }
--- `silent = true` reworks without the Balanced sticker.
function MP.ReworkCenter(key, opts)
	pending[#pending + 1] = { key = key, opts = opts or {} }
end

local RESERVED = { layers = true, center_table = true, loc_key = true, silent = true }
-- SMODS normalizes these at inject; pools are keyed by the number.
local VANILLA_RARITIES = { Common = 1, Uncommon = 2, Rare = 3, Legendary = 4 }

local function ingest(key, opts)
	local table_id = table_id_of(opts.center_table)
	local center = table_id and get_table(table_id)[key]
	if not center then
		sendWarnMessage("ReworkCenter: no center '" .. key .. "' in " .. tostring(table_id or opts.center_table), "MULTIPLAYER")
		return
	end
	local layers = type(opts.layers) == "string" and { opts.layers } or opts.layers
	if not layers or #layers == 0 then
		sendWarnMessage("ReworkCenter: '" .. key .. "' declares no layers", "MULTIPLAYER")
		return
	end

	local props = {}
	for k, v in pairs(opts) do
		if not RESERVED[k] then props[k] = v end
	end
	props.rarity = VANILLA_RARITIES[props.rarity] or props.rarity
	if opts.loc_key then
		local loc_vars = props.loc_vars or function()
			return {}
		end
		props.loc_vars = function(self, info_queue, card)
			local ret = loc_vars(self, info_queue, card)
			ret.key = opts.loc_key
			return ret
		end
	end
	-- Vanilla centers have no generate_ui, so new loc_vars would never be called.
	if props.loc_vars and not props.generate_ui and type(center.generate_ui) ~= "function" then
		props.generate_ui = SMODS.Center.generate_ui
	end

	vanilla[table_id] = vanilla[table_id] or {}
	vanilla[table_id][key] = vanilla[table_id][key] or {}
	local snapshot = vanilla[table_id][key]
	for prop in pairs(props) do
		if snapshot[prop] == nil then
			local v = rawget(center, prop)
			snapshot[prop] = v == nil and ABSENT or copy(v)
		end
	end

	patches[table_id] = patches[table_id] or {}
	patches[table_id][key] = patches[table_id][key] or {}
	for _, layer in ipairs(layers) do
		if patches[table_id][key][layer] then
			error("ReworkCenter: '" .. key .. "' is reworked twice for layer '" .. layer .. "'; merge the two calls")
		end
		patches[table_id][key][layer] = { props = copy(props), silent = opts.silent }
	end
end

-- Pure in (snapshot, patches, chain). Returns the resolved props and whether a
-- non-silent layer took part (the Balanced sticker).
local function resolve(table_id, key, chain)
	local out = {}
	for prop, v in pairs(vanilla[table_id][key]) do
		if v ~= ABSENT then out[prop] = copy(v) end
	end
	local balanced = false
	local layer_patches = patches[table_id][key]
	for _, layer in ipairs(chain) do
		local patch = layer_patches[layer]
		if patch then
			for prop, v in pairs(patch.props) do
				if prop == "config" and type(v) == "table" and type(out.config) == "table" then
					merge(out.config, v)
				else
					out[prop] = copy(v)
				end
			end
			if not patch.silent then balanced = true end
		end
	end
	return out, balanced
end

-- Rarity pools are rebuilt only for buckets some rarity rework can touch. Each
-- starts from its load-time snapshot; a joker whose resolved rarity differs from
-- vanilla moves out of its bucket and into the target at its (order, key) slot.
-- Under a chain with no rarity changes every bucket equals the snapshot exactly,
-- so the shop draws exactly what it would without the mod.
local function rarity_keys()
	local keys = {}
	for key, layer_patches in pairs(patches.P_CENTERS or {}) do
		for _, patch in pairs(layer_patches) do
			if patch.props.rarity ~= nil then
				keys[#keys + 1] = key
				break
			end
		end
	end
	table.sort(keys)
	return keys
end

local function snapshot_pools()
	if not G.P_JOKER_RARITY_POOLS then return end
	local function take(bucket)
		if bucket ~= nil and not pool_snapshot[bucket] and G.P_JOKER_RARITY_POOLS[bucket] then
			local list = {}
			for i, c in ipairs(G.P_JOKER_RARITY_POOLS[bucket]) do
				list[i] = c
			end
			pool_snapshot[bucket] = list
		end
	end
	for _, key in ipairs(rarity_keys()) do
		take(vanilla.P_CENTERS[key].rarity)
		for _, patch in pairs(patches.P_CENTERS[key]) do
			take(patch.props.rarity)
		end
	end
end

local function precedes(a, b)
	local ao, bo = a.order or 0, b.order or 0
	if ao ~= bo then return ao < bo end
	return tostring(a.key) < tostring(b.key)
end

local function apply_rarity_pools()
	if not next(pool_snapshot) then return end
	local moved_out, moved_in = {}, {}
	for _, key in ipairs(rarity_keys()) do
		local center = G.P_CENTERS[key]
		local from = vanilla.P_CENTERS[key].rarity
		local to = center.rarity
		local listed = false
		for _, c in ipairs(pool_snapshot[from] or {}) do
			if c == center then listed = true end
		end
		-- Unlisted jokers (WIP, demo, no-pool) stay unlisted wherever they move.
		if listed and to ~= from and pool_snapshot[to] then
			moved_out[center] = true
			moved_in[to] = moved_in[to] or {}
			table.insert(moved_in[to], center)
		end
	end
	for bucket, snapshot in pairs(pool_snapshot) do
		local rebuilt = {}
		for _, c in ipairs(snapshot) do
			if not moved_out[c] then rebuilt[#rebuilt + 1] = c end
		end
		for _, c in ipairs(moved_in[bucket] or {}) do
			local at = #rebuilt + 1
			for i, other in ipairs(rebuilt) do
				if precedes(c, other) then
					at = i
					break
				end
			end
			table.insert(rebuilt, at, c)
		end
		-- Refill in place: other code holds references to the pool table.
		local pool = G.P_JOKER_RARITY_POOLS[bucket]
		for i = #pool, 1, -1 do
			pool[i] = nil
		end
		for i, c in ipairs(rebuilt) do
			pool[i] = c
		end
	end
end

local function write(chain)
	for _, table_id in ipairs(TABLE_IDS) do
		local tbl = get_table(table_id)
		for key in pairs(patches[table_id] or {}) do
			local center = tbl[key]
			local resolved, balanced = resolve(table_id, key, chain)
			for prop in pairs(vanilla[table_id][key]) do
				center[prop] = resolved[prop]
			end
			center.mp_balanced = balanced or nil
		end
	end
	apply_rarity_pools()
	written_chain = copy(chain)
end

local function same_chain(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- Menu-time apply (ruleset preview). Refused while a run holds a different
-- chain: changing centers mid-run is the one thing that can still desync.
---@param chain string[] ordered layer names; {} is vanilla
function MP.ApplyReworks(chain)
	if not drained then return end
	chain = chain or {}
	if locked_chain then
		if not same_chain(chain, locked_chain) then
			sendWarnMessage(
				"ApplyReworks refused mid-run: live {"
					.. table.concat(locked_chain, ",")
					.. "}, requested {"
					.. table.concat(chain, ",")
					.. "}",
				"MULTIPLAYER"
			)
		end
		return
	end
	write(chain)
end

-- Run start: apply before any pool is read and hold the chain until the run ends.
function MP.BeginRunReworks(chain)
	if not drained then return end
	locked_chain = copy(chain or {})
	write(locked_chain)
end

function MP.EndRunReworks()
	locked_chain = nil
	MP.ApplyReworks({})
end

-- Ruleset key ("ruleset_mp_blitz" or "blitz") to its layer chain. nil is vanilla.
-- Modifiers fold in only when the ruleset is the active one (lobby, or practice).
function MP.rework_chain(ruleset)
	if not ruleset or ruleset == "" then return {} end
	return MP.active_layer_chain((ruleset:gsub("^ruleset_mp_", "")))
end

-- Chain-independent digest of every snapshot and patch. Equal fingerprints mean
-- any chain resolves identically on both clients. Functions hash by presence
-- only: LuaJIT bytecode differs between builds, so dumping it would false-alarm.
local fingerprint = nil
function MP.rework_fingerprint()
	if fingerprint then return fingerprint end
	local parts = {}
	local function emit(v)
		local t = type(v)
		if t == "table" then
			if v == ABSENT then
				parts[#parts + 1] = "~"
				return
			end
			parts[#parts + 1] = "{"
			for _, k in ipairs(sorted_keys(v)) do
				parts[#parts + 1] = tostring(k) .. "="
				emit(v[k])
				parts[#parts + 1] = ";"
			end
			parts[#parts + 1] = "}"
		elseif t == "function" then
			parts[#parts + 1] = "fn"
		else
			parts[#parts + 1] = t:sub(1, 1) .. tostring(v)
		end
	end
	emit({ vanilla = vanilla, patches = patches })
	local h = 0
	local s = table.concat(parts)
	for i = 1, #s do
		h = (h * 31 + s:byte(i)) % 4294967296
	end
	local digest = string.format("%08x", h)
	-- Cache only once the data is final; before the drain there is nothing to hash.
	if drained then fingerprint = digest end
	return digest
end

-- Drain after the real injectItems, once every center exists. SMODS runs it
-- again whenever Game:init_item_prototypes rebuilds G.P_* (profile switch,
-- language change): fresh vanilla tables and pools, so re-snapshot the pools and
-- put the current chain back.
local inject_ref = SMODS.injectItems
function SMODS.injectItems(...)
	local ret = inject_ref(...)
	for _, entry in ipairs(pending) do
		ingest(entry.key, entry.opts)
	end
	pending = {}
	pool_snapshot = {}
	snapshot_pools()
	if drained then write(written_chain) end
	drained = true
	return ret
end
