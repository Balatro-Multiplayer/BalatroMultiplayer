G.P_CENTER_POOLS.Ruleset = {}
MP.Rulesets = {}
MP.Ruleset = SMODS.GameObject:extend({
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
		"create_info_menu",
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
	is_disabled = function(self)
		return false
	end,
	force_lobby_options = function(self)
		return false
	end,
})

function MP.is_ruleset_active(ruleset_name)
	local key = "ruleset_mp_" .. ruleset_name
	if MP.LOBBY.code then
		return MP.LOBBY.config.ruleset == key
	elseif MP.SP and MP.SP.ruleset then
		return MP.SP.ruleset == key
	end
	return false
end

function MP.get_active_ruleset()
	if MP.LOBBY.code then
		return MP.LOBBY.config.ruleset
	elseif MP.SP and MP.SP.ruleset then
		return MP.SP.ruleset
	end
	return nil
end

function MP.ApplyBans()
	local ruleset_key = nil
	local gamemode = nil

	if MP.LOBBY.code and MP.LOBBY.config.ruleset then
		ruleset_key = MP.LOBBY.config.ruleset
		gamemode = MP.Gamemodes["gamemode_mp_" .. MP.LOBBY.type]
	elseif MP.SP and MP.SP.ruleset then
		ruleset_key = MP.SP.ruleset
	end

	if ruleset_key then
		local ruleset = MP.Rulesets[ruleset_key]
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
			for k, v in pairs(MP.DECK["BANNED_" .. string.upper(table)]) do
				G.GAME.banned_keys[k] = true
			end
		end
		for _, v in ipairs(ruleset["banned_silent"] or {}) do
			G.GAME.banned_keys[v] = true
		end
	end
end

-- Rework a center for specific ruleset(s). Use MP.LoadReworks() to swap in the active ruleset.
---@param key string e.g. "j_hanging_chad"
---@param ruleset string|string[] e.g. "standard" or {"standard", "sandbox"}
---@param loc_key string|nil alternate localization key, or nil to keep original
---@param args table center properties (config, calculate, loc_vars, etc.) + silent = true to hide from UI
function MP.ReworkCenter(key, ruleset, loc_key, args)
	local center = G.P_CENTERS[key]
	args = args or {}

	-- Convert single ruleset to list
	local rulesets = ruleset
	if type(rulesets) == "string" then rulesets = { rulesets } end

	-- Wrap loc_vars to inject loc_key if provided
	if loc_key then
		local user_loc_vars = args.loc_vars or function()
			return {}
		end
		args.loc_vars = function(self, info_queue, card)
			local result = user_loc_vars(self, info_queue, card)
			result.key = loc_key
			return result
		end
	end

	-- do we need to inject generate_ui for loc_vars to work?
	local needs_generate_ui = args.loc_vars
		and not args.generate_ui
		and not (center.generate_ui and type(center.generate_ui) == "function")

	-- Apply changes to all specified rulesets
	for _, rs in ipairs(rulesets) do
		local prefix = "mp_" .. rs .. "_"

		-- Store all reworked properties
		for k, v in pairs(args) do
			if k ~= "silent" then
				center[prefix .. k] = v
				if not center["mp_vanilla_" .. k] then center["mp_vanilla_" .. k] = center[k] or "NULL" end
			end
		end

		-- Auto-inject generate_ui when adding loc_vars to vanilla centers
		if needs_generate_ui then
			center[prefix .. "generate_ui"] = SMODS.Center.generate_ui
			if not center.mp_vanilla_generate_ui then center.mp_vanilla_generate_ui = center.generate_ui or "NULL" end
		end

		-- Mark this center as having reworks
		center.mp_reworks = center.mp_reworks or {}
		center.mp_reworks[rs] = true
		center.mp_reworks["vanilla"] = true

		center.mp_silent = center.mp_silent or {}
		center.mp_silent[rs] = args.silent
	end
end

-- You can call this function without a ruleset to set it to vanilla
-- You can also call this function with a key to only affect that specific joker (might be useful)
function MP.LoadReworks(ruleset, key)
	ruleset = ruleset or "vanilla"
	if string.sub(ruleset, 1, 11) == "ruleset_mp_" then ruleset = string.sub(ruleset, 12, #ruleset) end
	local function process(key_, ruleset_)
		local center = G.P_CENTERS[key_]
		for k, v in pairs(center) do
			if string.sub(k, 1, #ruleset_) == ruleset_ then
				local orig = string.sub(k, #ruleset_ + 1)
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
	if key then
		process(key, "mp_" .. ruleset .. "_")
	else
		for k, v in pairs(G.P_CENTERS) do
			if v.mp_reworks then
				if v.mp_reworks[ruleset] then
					process(k, "mp_" .. ruleset .. "_")
				elseif v.mp_reworks["vanilla"] then -- Check vanilla separately to reset reworked jokers
					process(k, "mp_vanilla_")
				end
			end
		end
	end
end
