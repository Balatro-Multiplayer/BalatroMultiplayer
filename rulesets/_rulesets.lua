G.P_CENTER_POOLS.Ruleset = {}
MP.Rulesets = {}

local RulesetBase = SMODS.GameObject:extend({
	obj_table = {},
	obj_buffer = {},
	required_params = {
		"key",
		"multiplayer_content",
		"banned_jokers",
		"banned_consumables",
		"banned_vouchers",
		"banned_enhancements",
		"banned_tags",
		"banned_blinds",
		"reworked_jokers",
		"reworked_consumables",
		"reworked_vouchers",
		"reworked_enhancements",
		"reworked_tags",
		"reworked_blinds",
	},
	class_prefix = "ruleset",
	inject = function(self)
		MP.Rulesets[self.key] = self
		if not G.P_CENTER_POOLS.Ruleset then G.P_CENTER_POOLS.Ruleset = {} end
		table.insert(G.P_CENTER_POOLS.Ruleset, self)
	end,
	process_loc_text = function(self)
		SMODS.process_loc_text(G.localization.descriptions["Ruleset"], self.key, self.loc_txt)
	end,
	create_info_menu = function(self)
		local gamemode_text = nil
		if self.forced_gamemode then
			gamemode_text = self.forced_gamemode_text or ("k_" .. self.forced_gamemode:gsub("gamemode_mp_", ""))
		end
		local raw_key = self.key:gsub("^ruleset_mp_", "")
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = self.multiplayer_content,
			forced_lobby_options = self.forced_lobby_options,
			forced_gamemode_text = gamemode_text,
			description_key = self.description_key or ("k_" .. raw_key .. "_description"),
			stickers = self.stickers,
		})
	end,
	is_disabled = function(self)
		return false
	end,
	force_lobby_options = function(self)
		return false
	end,
})

-- SMODS validates `required_params` inside __call, not inject(). Layers
-- declare those arrays separately, so resolve_layers has to pre-bake them
-- before construction. This is a workaround.
-- Proper fix: stop treating rulesets as GameObjects up front.
-- Keep them as plain tables and only flip into a SMODS object at inject() time
function MP.Ruleset(init)
	-- Mirror MP.Layer()'s reverse-index population for ruleset-level reworked
	-- entries, using the ruleset's short name (which appears in active_layer_chain).
	-- Lets the auto-graft mp_include in layers/_layers.lua gate cards declared
	-- directly on a ruleset, not just via a layer.
	if init.reworked_jokers then
		for _, key in ipairs(init.reworked_jokers) do
			MP._JOKER_LAYERS[key] = MP._JOKER_LAYERS[key] or {}
			table.insert(MP._JOKER_LAYERS[key], init.key)
		end
	end
	if init.reworked_consumables then
		for _, key in ipairs(init.reworked_consumables) do
			MP._CONSUMABLE_LAYERS[key] = MP._CONSUMABLE_LAYERS[key] or {}
			table.insert(MP._CONSUMABLE_LAYERS[key], init.key)
		end
	end
	return RulesetBase(MP.resolve_layers(init))
end

function MP.is_ruleset_active(ruleset_name)
	local key = "ruleset_mp_" .. ruleset_name
	if MP.LOBBY.code then
		return MP.LOBBY.config.ruleset == key
	elseif MP.is_practice_mode() then
		return MP.SP.ruleset == key
	end
	return false
end

-- "Active" meaning both a live lobby and the configuration-in-progress phase.
function MP.get_active_ruleset()
	if MP.LOBBY.config.ruleset then
		return MP.LOBBY.config.ruleset
	elseif MP.is_practice_mode() then
		return MP.SP.ruleset
	end
	return nil
end

function MP.get_active_gamemode()
	if MP.LOBBY.code then
		return MP.LOBBY.config.gamemode
	elseif MP.is_practice_mode() then
		-- Ghost replay stores the gamemode directly
		if MP.GHOST.is_active() and MP.GHOST.gamemode then return MP.GHOST.gamemode end
		return MP.current_ruleset().forced_gamemode
	end
	return nil
end

-- ----------------------------------------------------------------------------
-- Active context: the resolved view of (ruleset + active modifiers)
-- ----------------------------------------------------------------------------
-- Prep work. Looks pointless. Isn't.
-- A set so "is this an array field?" is O(1), and a per-lookup resolver that
-- merges (ruleset + active modifiers).

local _array_field_set = {}
for _, f in ipairs(MP._LAYER_ARRAY_FIELDS) do
	_array_field_set[f] = true
end

local function resolve_field(field)
	local ruleset_key = MP.get_active_ruleset()
	local ruleset = ruleset_key and MP.Rulesets[ruleset_key] or nil
	if _array_field_set[field] then
		local merged = {}
		if ruleset and ruleset[field] then
			for _, v in ipairs(ruleset[field]) do
				merged[#merged + 1] = v
			end
		end
		for _, mod_name in ipairs(MP.MODIFIERS) do
			local layer = MP.Layers[mod_name]
			if layer and layer[field] then
				for _, v in ipairs(layer[field]) do
					merged[#merged + 1] = v
				end
			end
		end
		return merged
	end
	-- Scalar / function / non-array: modifiers last-wins, then ruleset
	for i = #MP.MODIFIERS, 1, -1 do
		local layer = MP.Layers[MP.MODIFIERS[i]]
		if layer and layer[field] ~= nil then return layer[field] end
	end
	if ruleset then return ruleset[field] end
	return nil
end

local _resolver = setmetatable({}, {
	__index = function(_, field)
		return resolve_field(field)
	end,
})

-- The answer to "what's in the active ruleset?".
-- Safe with no active ruleset: arrays read as {}, the rest as nil.
function MP.current_ruleset()
	return _resolver
end

-- Returns a single deduped, ordered list of active layer names. Body looks
-- scarier than it is. Order: target ruleset's _layer_order, then its
-- self-name, then modifiers (when target is the active ruleset). Dedup
-- matters because not every hook is idempotent — smallworld's 75% cull
-- would re-cull the survivors.
function MP.active_layer_chain(target_short)
	local active_key = MP.get_active_ruleset()
	local active_short = active_key and active_key:gsub("^ruleset_mp_", "") or nil
	target_short = target_short or active_short

	local result, seen = {}, {}
	local function add(name)
		if name and not seen[name] then
			seen[name] = true
			result[#result + 1] = name
		end
	end

	if target_short then
		local ruleset = MP.Rulesets["ruleset_mp_" .. target_short]
		if ruleset and ruleset._layer_order then
			for _, name in ipairs(ruleset._layer_order) do
				add(name)
			end
		end
		add(target_short)
	end
	if target_short == active_short then
		for _, name in ipairs(MP.MODIFIERS) do
			add(name)
		end
	end
	return result
end

function MP.ApplyBans()
	local ruleset_key = MP.get_active_ruleset()
	local gamemode_key = MP.get_active_gamemode()
	local gamemode = gamemode_key and MP.Gamemodes[gamemode_key] or nil

	if ruleset_key then
		local ruleset = MP.current_ruleset()
		local banned_tables = {
			"jokers",
			"consumables",
			"vouchers",
			"enhancements",
			"tags",
			"blinds",
		}
		for _, table in ipairs(banned_tables) do
			for _, v in ipairs(ruleset["banned_" .. table]) do
				G.GAME.banned_keys[v] = true
			end
			if gamemode then
				for _, v in ipairs(gamemode["banned_" .. table]) do
					G.GAME.banned_keys[v] = true
				end
			end
			for _, v in pairs(MP.DECK["BANNED_" .. string.upper(table)]) do
				G.GAME.banned_keys[v] = true
			end
		end
		for _, v in ipairs(ruleset.banned_silent) do
			G.GAME.banned_keys[v] = true
		end
	end
end

-- ----------------------------------------------------------------------------
-- ReworkCenter: declarative center rebalancing, derived purely from context
-- ----------------------------------------------------------------------------
-- Old model smeared mp_<layer>_<prop> onto the shared center and mutated it in
-- place every time the active context changed. Effective state depended on call
-- history, not on (ruleset + layers + modifiers). Menu previews leaked into the
-- state gameplay reads (3a42f503), the "NULL" sentinel conflated absent-vs-real,
-- and rarity reworks re-sorted the pseudorandom pool incrementally — three of
-- the documented desync vectors, in one function.
--
-- New model is three tiers:
--   1. BASELINE — a deep, frozen snapshot of vanilla, captured once. The truth
--      we always rebuild from, so the result is the same on call 1 and call 100.
--   2. LEDGER — declared overrides, normalized per (table, key, layer). No
--      prefixes on the center; the override lives off to the side.
--   3. LIVE — G.P_* is a *projection* of (baseline ⊕ active layers), recomputed
--      from scratch. ApplyReworks is the only writer; PreviewReworks computes
--      into an isolated namespace and never touches G.P_*.
--
-- effective_props is a pure function of (table, key, layer-chain). That's the
-- whole determinism argument: two clients that finalize the same chain get
-- byte-identical centers regardless of what either browsed first.

-- Tables ReworkCenter can target, keyed by a stable id so baseline/ledger don't
-- alias across tables that happen to share a key string.
local function rework_tables()
	return {
		P_CENTERS = G.P_CENTERS,
		P_TAGS = G.P_TAGS,
		P_SEALS = G.P_SEALS,
		PokerHands = SMODS.PokerHands,
		P_STAKES = G.P_STAKES,
		P_BLINDS = G.P_BLINDS,
	}
end

-- Resolve an opts.center_table (table ref, global name, or nil) to a stable id.
local function resolve_table_id(center_table)
	if center_table == nil then return "P_CENTERS" end
	local tables = rework_tables()
	if type(center_table) == "string" then
		return tables[center_table] and center_table or nil
	end
	for id, tbl in pairs(tables) do
		if tbl == center_table then return id end
	end
	return nil
end

-- Frozen tables are read-through proxies: the real data lives behind FROZEN_DATA
-- so EVERY write (new key or existing) trips __newindex, not just new keys.
-- LuaJIT is 5.1 (no __pairs / table.freeze), so deep_copy unwraps them directly.
local FROZEN_DATA = setmetatable({}, { __mode = "k" })

local function deep_copy(v)
	if type(v) ~= "table" then return v end
	local src = FROZEN_DATA[v] or v
	local out = {}
	for k, vv in pairs(src) do
		out[k] = deep_copy(vv)
	end
	return out
end

-- Recursive freeze. A frozen baseline that's written to errors immediately,
-- instead of silently desyncing two clients weeks later.
local function deep_freeze(v)
	if type(v) ~= "table" then return v end
	local inner = {}
	for k, vv in pairs(v) do
		inner[k] = deep_freeze(vv)
	end
	local proxy = setmetatable({}, {
		__index = inner,
		__newindex = function()
			error("attempt to mutate a frozen rework baseline", 2)
		end,
		__metatable = false,
	})
	FROZEN_DATA[proxy] = inner
	return proxy
end

-- Deep-merge src onto dst (both plain tables). Tables recurse; scalars overwrite.
-- Mirrors the old config behaviour where {extra={...}} layered onto vanilla
-- config rather than replacing it wholesale.
local function deep_merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			deep_merge(dst[k], v)
		else
			dst[k] = deep_copy(v)
		end
	end
	return dst
end

MP._REWORK_BASELINE = {} -- [table_id][key] = { [prop] = { value, present = true } } (frozen)
MP._REWORK_LEDGER = {} -- [table_id][key][layer] = { props = <deepcopy>, silent }
MP._REWORK_OWNED = {} -- [table_id][key] = { prop = true } — the key-reset set
MP._PREVIEW_VIEW = {} -- [table_id][key] = { [prop] = value } — read-only preview projection
MP._PREVIEW_ACTIVE = false -- phase guard: true while a preview projection is live

-- Pending ReworkCenter calls, drained once at injectItems. We can't capture the
-- baseline at call time because the center may not be registered yet.
local PENDING_REWORKS = {}

-- Rework a center for specific layer(s). Effective props are derived from the
-- active context at ApplyReworks/PreviewReworks time — registering is pure data.
-- Multiple calls for the same key accumulate; each call's layers get their own
-- ledger slot, so a key reworked differently per layer is the supported pattern.
---@param key string e.g. "j_hanging_chad"
---@param opts table { layers, loc_key?, silent?, center_table?, ...center properties }
function MP.ReworkCenter(key, opts)
	PENDING_REWORKS[#PENDING_REWORKS + 1] = { key = key, opts = opts or {} }
end

-- Normalize one ReworkCenter call into the ledger. Runs once, post-registration.
-- This is where the loc_var-wrap / generate_ui / mp_balanced enrichment lives —
-- byte-for-byte the same behaviour as the old graft, just normalized into a
-- side table instead of smeared onto the center as mp_<layer>_<prop>.
local function ingest_rework(key, opts)
	local table_id = resolve_table_id(opts.center_table)
	if not table_id then return end
	local center = rework_tables()[table_id][key]
	if not center then return end

	local reserved = { layers = true, loc_key = true, silent = true, center_table = true }
	local layers = opts.layers
	if type(layers) == "string" then layers = { layers } end
	if not layers then return end

	-- Wrap loc_vars to inject loc_key if provided (unchanged semantics).
	local loc_key = opts.loc_key
	if loc_key then
		local user_loc_vars = opts.loc_vars or function()
			return {}
		end
		opts.loc_vars = function(self, info_queue, card)
			local result = user_loc_vars(self, info_queue, card)
			result.key = loc_key
			return result
		end
	end

	-- Inject generate_ui when adding loc_vars to a vanilla center (unchanged).
	local needs_generate_ui = opts.loc_vars
		and not opts.generate_ui
		and not (center.generate_ui and type(center.generate_ui) == "function")

	-- Force mp_balanced on the reworked config so the sticker patch fires
	-- (unchanged). We seed from vanilla config so callers can override a single
	-- field without re-declaring the whole table.
	if center.config then
		opts.config = opts.config or deep_copy(center.config)
		opts.config.mp_balanced = true
	end

	-- Collect the declared props once (same for every layer in this call).
	local props = {}
	for k, v in pairs(opts) do
		if not reserved[k] then props[k] = v end
	end
	if needs_generate_ui then props.generate_ui = SMODS.Center.generate_ui end

	MP._REWORK_LEDGER[table_id] = MP._REWORK_LEDGER[table_id] or {}
	MP._REWORK_LEDGER[table_id][key] = MP._REWORK_LEDGER[table_id][key] or {}
	MP._REWORK_OWNED[table_id] = MP._REWORK_OWNED[table_id] or {}
	MP._REWORK_OWNED[table_id][key] = MP._REWORK_OWNED[table_id][key] or {}
	local owned = MP._REWORK_OWNED[table_id][key]

	-- Baseline: deep snapshot of every prop this rework touches, before anyone
	-- mutates anything. Present-booleans, not a "NULL" string — absent stays
	-- absent. Frozen so the snapshot can't drift.
	MP._REWORK_BASELINE[table_id] = MP._REWORK_BASELINE[table_id] or {}
	MP._REWORK_BASELINE[table_id][key] = MP._REWORK_BASELINE[table_id][key] or {}
	local baseline = MP._REWORK_BASELINE[table_id][key]

	for prop in pairs(props) do
		owned[prop] = true
		if baseline[prop] == nil then
			local cur = center[prop]
			if cur == nil then
				baseline[prop] = deep_freeze({ present = false })
			else
				baseline[prop] = deep_freeze({ value = deep_copy(cur), present = true })
			end
		end
	end

	for _, layer in ipairs(layers) do
		-- Last write for a (key, layer) wins, matching the old prefix-overwrite.
		MP._REWORK_LEDGER[table_id][key][layer] = {
			props = deep_copy(props),
			silent = opts.silent,
		}
	end
end

-- Compute the effective props for one center under an ordered layer chain.
-- PURE: depends only on (frozen baseline, ledger, chain). No reads of, or writes
-- to, the live center — this is the heart of the determinism guarantee.
-- Returns (effective, owned) where `effective[prop] = value | nil`.
local function effective_props(table_id, key, chain)
	local owned = (MP._REWORK_OWNED[table_id] or {})[key] or {}
	local baseline = (MP._REWORK_BASELINE[table_id] or {})[key] or {}
	local ledger = (MP._REWORK_LEDGER[table_id] or {})[key] or {}

	-- Start from vanilla: every owned prop resets to its frozen baseline (or
	-- absent). This is why call-count and preview history can't leak in.
	local effective = {}
	for prop in pairs(owned) do
		local b = baseline[prop]
		if b and b.present then effective[prop] = deep_copy(b.value) end
	end

	-- Fold each active layer in chain order; later layers win, config deep-merges.
	for _, layer in ipairs(chain) do
		local slot = ledger[layer]
		if slot then
			for prop, v in pairs(slot.props) do
				if prop == "config" and type(v) == "table" and type(effective.config) == "table" then
					deep_merge(effective.config, v)
				else
					effective[prop] = deep_copy(v)
				end
			end
		end
	end
	return effective, owned
end

-- Set of centers some ledger entry touches, per table. Iterating this (not the
-- whole P_* table) keeps ApplyReworks scoped to rework-owned keys.
local function reworked_keys(table_id)
	local out = {}
	local ledger = MP._REWORK_LEDGER[table_id]
	if ledger then
		for key in pairs(ledger) do
			out[#out + 1] = key
		end
	end
	return out
end

-- Rebuild G.P_JOKER_RARITY_POOLS from scratch under the effective rarities.
-- NOT incremental: collect every joker whose effective rarity is bucket B,
-- stable-sort by (.order, key), and replace the bucket wholesale. Two clients
-- with the same chain produce byte-identical pools regardless of how many times
-- this ran or what they previewed — defeating the rarity re-sort desync.
local function rebuild_rarity_pools(chain, effective_rarity)
	if not G.P_JOKER_RARITY_POOLS then return end
	for bucket, pool in pairs(G.P_JOKER_RARITY_POOLS) do
		local members = {}
		for _, center in pairs(G.P_CENTERS) do
			-- Membership mirrors vanilla pool init byte-for-byte (game.lua:818/822):
			--   if not v.wip then if v.rarity and v.set == 'Joker' and not v.demo
			-- — i.e. a non-WIP Joker with a rarity that isn't a demo card. Effective
			-- rarity = the layer override if reworked, else the center's own rarity.
			-- (Vanilla applies no banned/discovered/skip_pool gate to the rarity
			-- pool; those act elsewhere or at draw-time, so we don't either.)
			local rarity = effective_rarity[center.key]
			if rarity == nil then rarity = center.rarity end
			if not center.wip and rarity and center.set == "Joker" and not center.demo and rarity == bucket then
				members[#members + 1] = center
			end
		end
		-- Vanilla sorts by .order alone; we add a key tiebreak so equal-order
		-- jokers can't land in different positions on two clients (table.sort is
		-- not stable). Strictly more deterministic than the game's own sort.
		table.sort(members, function(a, b)
			if a.order ~= b.order then return (a.order or 0) < (b.order or 0) end
			return tostring(a.key) < tostring(b.key)
		end)
		-- Replace contents in place (other code holds a reference to `pool`).
		for i = #pool, 1, -1 do
			pool[i] = nil
		end
		for i, center in ipairs(members) do
			pool[i] = center
		end
	end
end

-- Strip ruleset_mp_ prefix; nil/empty means vanilla (no layers active).
local function chain_for(ruleset)
	if not ruleset or ruleset == "" then return {} end
	if string.sub(ruleset, 1, 11) == "ruleset_mp_" then ruleset = string.sub(ruleset, 12) end
	return MP.active_layer_chain(ruleset)
end

-- Apply reworks for the active ruleset onto the LIVE centers. The ONLY function
-- that writes G.P_*; called once at run start (game_state.lua). Idempotent: it
-- rebuilds every owned prop from the frozen baseline, so calling it twice — or
-- after any number of previews — lands on the same state.
-- Pass a `key` to limit to one center (kept for parity with old call sites).
function MP.ApplyReworks(ruleset, key)
	if MP._PREVIEW_ACTIVE then
		error("ApplyReworks called during preview phase — pool mutation is forbidden while previewing")
	end
	local chain = chain_for(ruleset)
	local effective_rarity = {}

	for table_id, tbl in pairs(rework_tables()) do
		local keys = key and { key } or reworked_keys(table_id)
		for _, k in ipairs(keys) do
			local center = tbl[k]
			if center and (MP._REWORK_LEDGER[table_id] or {})[k] then
				local effective, owned = effective_props(table_id, k, chain)
				-- KEY-RESET the union of owned props: effective, else baseline,
				-- else nil. No prefix scanning — we touch exactly what reworks own.
				local baseline = MP._REWORK_BASELINE[table_id][k]
				for prop in pairs(owned) do
					if effective[prop] ~= nil then
						center[prop] = effective[prop]
					else
						local b = baseline[prop]
						center[prop] = (b and b.present) and deep_copy(b.value) or nil
					end
				end
				if table_id == "P_CENTERS" and owned.rarity then
					effective_rarity[k] = center.rarity
				end
			end
		end
	end

	-- One deterministic rebuild after all rarities are live (skip in by-key mode;
	-- a single center can't define a consistent whole-pool order).
	if not key and next(effective_rarity) then rebuild_rarity_pools(chain, effective_rarity) end
end

-- Project reworks for `ruleset` into an isolated read-only namespace. Never
-- writes G.P_* or the rarity pools. The info panel reads through
-- MP.preview_center(), so previewing ruleset Y can't leave residue in the state
-- a later game under ruleset X reads. This is the asymmetric-call-site fix.
function MP.PreviewReworks(ruleset)
	local chain = chain_for(ruleset)
	MP._PREVIEW_VIEW = {}
	MP._PREVIEW_ACTIVE = true
	for table_id in pairs(rework_tables()) do
		for _, k in ipairs(reworked_keys(table_id)) do
			local effective = effective_props(table_id, k, chain)
			MP._PREVIEW_VIEW[table_id] = MP._PREVIEW_VIEW[table_id] or {}
			MP._PREVIEW_VIEW[table_id][k] = effective
		end
	end
	MP._PREVIEW_ACTIVE = false
end

-- Thin accessor: the center as the active preview would render it. UI that
-- displays reworked centers reads through this instead of the live table, so it
-- shows preview numbers without anything mutating the live center. Outside a
-- preview (empty view) it returns the live center unchanged.
function MP.preview_center(key, center_table)
	local table_id = resolve_table_id(center_table) or "P_CENTERS"
	local tbl = rework_tables()[table_id]
	local live = tbl and tbl[key]
	local overlay = (MP._PREVIEW_VIEW[table_id] or {})[key]
	if not live or not overlay then return live end
	-- Read-through proxy: overlaid props (incl. the already-merged config the
	-- panel + balanced sticker read) come from the projection; everything else
	-- falls through to live. Writes land on the throwaway proxy, never on live —
	-- so even a Card constructor that scribbles on its center can't desync.
	return setmetatable({}, {
		__index = function(_, prop)
			local ov = overlay[prop]
			if ov ~= nil then return ov end
			return live[prop]
		end,
	})
end

-- Backwards-compatible shim. Old call sites pass a ruleset (+ optional key).
-- Game-start applies for real; menu/replay sites should migrate to
-- PreviewReworks, but routing them here keeps them correct (a preview that
-- writes the live center is still deterministic — it's just wasteful — because
-- the next ApplyReworks rebuilds from the frozen baseline regardless).
function MP.LoadReworks(ruleset, key)
	MP.ApplyReworks(ruleset, key)
end

-- inject reworks properly: drain every pending ReworkCenter into the ledger
-- AFTER the real injectItems has registered all centers.
local inject_ref = SMODS.injectItems
function SMODS.injectItems()
	local ret = inject_ref()
	for _, entry in ipairs(PENDING_REWORKS) do
		ingest_rework(entry.key, entry.opts)
	end
	PENDING_REWORKS = {}
	return ret
end
