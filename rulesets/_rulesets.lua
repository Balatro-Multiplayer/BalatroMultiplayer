-- Credit to @MathIsFun_ and the Balatro Multiplayer project for the ruleset system this is based on.
-- Thin delegating wrapper around MPAPI.Ruleset: registers PvP rulesets into the
-- shared MPAPI.Rulesets registry (dupe-key checking, required_params validation,
-- reworked_* reverse-indexing, and `inject`'s G.P_CENTER_POOLS.Ruleset registration
-- all come from MPAPI for free) while keeping PvP's own default methods
-- (create_info_menu/is_disabled/force_lobby_options) and its own active-ruleset/
-- gamemode resolution (lobby / practice-mode / ghost-replay -- MPAPI only knows
-- about the lobby case, so this stays PvP-owned).
--
-- Key prefixing: PvP ruleset files pass short keys (key = "vanilla") and have
-- always relied on a "ruleset_mp_" prefix (class "ruleset" + this mod's "mp") to
-- get the full key used everywhere else in the codebase. MPAPI.Ruleset's own
-- class sets no class_prefix (Speed's rulesets are already fully-qualified, e.g.
-- "spdrn_order", and don't want one), so PvP computes the "ruleset_" segment
-- itself and tells SMODS not to touch the key further.
--
-- MP.Rulesets stays as a direct alias: read elsewhere (tests/test_ruleset_shape.lua,
-- lib/ghost_replay.lua, networking/action_handlers.lua) expecting a key -> ruleset
-- lookup table, which MPAPI.Rulesets now IS.
MP.Rulesets = MPAPI.Rulesets

function MP.create_info_menu(self)
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
end

function MP.is_disabled(self)
	return false
end

function MP.force_lobby_options(self)
	return false
end

function MP.Ruleset(init)
	init.key = "ruleset_mp_" .. init.key
	init.prefix_config = init.prefix_config or { key = false }
	init.create_info_menu = init.create_info_menu or MP.create_info_menu
	init.is_disabled = init.is_disabled or MP.is_disabled
	init.force_lobby_options = init.force_lobby_options or MP.force_lobby_options
	return MPAPI.Ruleset(init)
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
-- Reads from MPAPI's shared Rulesets/Layers/MODIFIERS tables now that MP.Ruleset/
-- MP.Layer delegate into them -- only the active-KEY resolution above stays
-- PvP-owned (lobby/practice/ghost).

local _array_field_set = {}
for _, f in ipairs(MPAPI._LAYER_ARRAY_FIELDS) do
	_array_field_set[f] = true
end

local function resolve_field(field)
	local ruleset_key = MP.get_active_ruleset()
	local ruleset = ruleset_key and MPAPI.Rulesets[ruleset_key] or nil
	if _array_field_set[field] then
		local merged = {}
		if ruleset and ruleset[field] then
			for _, v in ipairs(ruleset[field]) do
				merged[#merged + 1] = v
			end
		end
		for _, mod_name in ipairs(MPAPI.MODIFIERS) do
			local layer = MPAPI.Layers[mod_name]
			if layer and layer[field] then
				for _, v in ipairs(layer[field]) do
					merged[#merged + 1] = v
				end
			end
		end
		return merged
	end
	-- Scalar / function / non-array: modifiers last-wins, then ruleset
	for i = #MPAPI.MODIFIERS, 1, -1 do
		local layer = MPAPI.Layers[MPAPI.MODIFIERS[i]]
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
		local ruleset = MPAPI.Rulesets["ruleset_mp_" .. target_short]
		if ruleset and ruleset._layer_order then
			for _, name in ipairs(ruleset._layer_order) do
				add(name)
			end
		end
		add(target_short)
	end
	if target_short == active_short then
		for _, name in ipairs(MPAPI.MODIFIERS) do
			add(name)
		end
	end
	return result
end

-- Delegate straight to MPAPI: both take (key, opts) / (ruleset_key, key) and
-- MPAPI.LoadReworks resolves via MPAPI.active_layer_chain, which agrees with the
-- resolution above since MP.Ruleset/MP.Layer register into MPAPI's own tables.
MP.ReworkCenter = MPAPI.ReworkCenter
MP.LoadReworks = MPAPI.LoadReworks
