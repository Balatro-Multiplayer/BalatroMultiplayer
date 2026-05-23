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

local LOADED_REWORKS = {}
-- Rework a center for specific layer(s). Use MP.LoadReworks() to swap in the active ruleset.
-- Multiple calls for the same key accumulate — each call targets its own layer slot
-- on the center, so registering a key once per layer is the supported pattern.
---@param key string e.g. "j_hanging_chad"
---@param opts table { layers, loc_key?, silent?, ...center properties }
function MP.ReworkCenter(key, opts)
	LOADED_REWORKS[key] = LOADED_REWORKS[key] or {}
	table.insert(LOADED_REWORKS[key], opts or {})
end

-- inject reworks properly
local inject_ref = SMODS.injectItems
function SMODS.injectItems()
	local ret = inject_ref()
	for key, opts_list in pairs(LOADED_REWORKS) do
		for _, opts in ipairs(opts_list) do
			local center_table = type(opts.center_table) == "table" and opts.center_table
				or G[opts.center_table]
				or G.P_CENTERS
			local center = center_table[key]

			-- Meta keys (not center properties)
			local reserved = { layers = true, loc_key = true, silent = true }
			local layers = opts.layers
			local loc_key = opts.loc_key
			local silent = opts.silent

			-- Convert single layer to list
			if type(layers) == "string" then layers = { layers } end

			-- Wrap loc_vars to inject loc_key if provided
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

			-- do we need to inject generate_ui for loc_vars to work?
			local needs_generate_ui = opts.loc_vars
				and not opts.generate_ui
				and not (center.generate_ui and type(center.generate_ui) == "function")

			-- inject mp_balanced if applicable
			if center.config then
				opts.config = opts.config or copy_table(center.config)
				opts.config.mp_balanced = true
			end

			-- Apply changes to all specified layers
			for _, layer in ipairs(layers) do
				local prefix = "mp_" .. layer .. "_"

				-- Store all reworked properties
				for k, v in pairs(opts) do
					if not reserved[k] then
						center[prefix .. k] = v
						if not center["mp_vanilla_" .. k] then center["mp_vanilla_" .. k] = center[k] or "NULL" end
					end
				end

				-- Auto-inject generate_ui when adding loc_vars to vanilla centers
				if needs_generate_ui then
					center[prefix .. "generate_ui"] = SMODS.Center.generate_ui
					if not center.mp_vanilla_generate_ui then
						center.mp_vanilla_generate_ui = center.generate_ui or "NULL"
					end
				end

				-- Mark this center as having reworks
				center.mp_reworks = center.mp_reworks or {}
				center.mp_reworks[layer] = true
				center.mp_reworks["vanilla"] = true

				center.mp_silent = center.mp_silent or {}
				center.mp_silent[layer] = silent
			end
		end
	end
	return ret
end

-- Load reworks for the active ruleset. Resolves via layer order then self-layer.
-- You can also call this function with a key to only affect that specific center.
function MP.LoadReworks(ruleset, key)
	ruleset = ruleset or "vanilla"
	if string.sub(ruleset, 1, 11) == "ruleset_mp_" then ruleset = string.sub(ruleset, 12, #ruleset) end

	local function process(key_, prefix_, tbl_)
		local center = tbl_[key_]
		for k, v in pairs(center) do
			if string.sub(k, 1, #prefix_) == prefix_ then
				local orig = string.sub(k, #prefix_ + 1)
				if orig == "rarity" then
					SMODS.remove_pool(G.P_JOKER_RARITY_POOLS[center[orig]], center.key)
					table.insert(G.P_JOKER_RARITY_POOLS[center[k]], center)
					table.sort(G.P_JOKER_RARITY_POOLS[center[k]], function(a, b)
						return a.order < b.order
					end)
				end
				if center[k] == "NULL" then
					center[orig] = nil
				else
					center[orig] = center[k]
				end
			end
		end
	end

	-- Resolution: vanilla → ruleset's layers → ruleset self → modifiers (only
	-- when target is the active ruleset). active_layer_chain handles the full
	-- layer-name list; vanilla is processed separately.
	local resolution = MP.active_layer_chain(ruleset)

	if key then
		process(key, "mp_vanilla_")
		for _, layer in ipairs(resolution) do
			process(key, "mp_" .. layer .. "_")
		end
	else
		for _, tbl in ipairs({
			G.P_CENTERS,
			G.P_TAGS,
			G.P_SEALS,
			SMODS.PokerHands,
			G.P_STAKES,
			G.P_BLINDS,
		}) do
			for k, v in pairs(tbl) do
				if v.mp_reworks then
					-- Always reset to vanilla first
					if v.mp_reworks["vanilla"] then process(k, "mp_vanilla_", tbl) end
					-- Apply layers in order, then self
					for _, layer in ipairs(resolution) do
						if v.mp_reworks[layer] then process(k, "mp_" .. layer .. "_", tbl) end
					end
				end
			end
		end
	end
end
