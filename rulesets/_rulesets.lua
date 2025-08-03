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
		"create_info_menu"
	},
	class_prefix = "ruleset",
	inject = function(self)
		MP.Rulesets[self.key] = self
		if not G.P_CENTER_POOLS.Ruleset then
			G.P_CENTER_POOLS.Ruleset = {}
		end
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
	end
})

function MP.ApplyBans()
	if MP.LOBBY.code and MP.LOBBY.config.ruleset then
		local ruleset = MP.Rulesets[MP.LOBBY.config.ruleset]
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
			for k, v in pairs(MP.DECK["BANNED_" .. string.upper(table)]) do
				G.GAME.banned_keys[k] = true
			end
		end
	end
end

-- This function writes any center rework data to G.P_CENTERS, where they will be used later in its specified ruleset
-- Example usage in rulesets/standard.lua
function MP.ReworkCenter(args)
	local center = G.P_CENTERS[args.key]

	-- Convert single ruleset to list for backward compatibility
	local rulesets = args.ruleset
	if type(rulesets) == "string" then
		rulesets = { rulesets }
	end

	-- Apply changes to all specified rulesets
	for _, ruleset in ipairs(rulesets) do
		local ruleset_ = "mp_" .. ruleset .. "_"
		for k, v in pairs(args) do
			if k ~= "key" and k ~= "ruleset" and k ~= "silent" then
				center[ruleset_ .. k] = v
				if not center["mp_vanilla_" .. k] then
					center["mp_vanilla_" .. k] = center[k]
				end
			end
		end
		center.mp_reworks = center.mp_reworks or {}
		center.mp_reworks[ruleset] = true -- Caching this for better load times since we're gonna be inefficiently looping through all centers probably
		center.mp_reworks["vanilla"] = true

		center.mp_silent = center.mp_silent or {}
		center.mp_silent[ruleset] = args.silent
	end
end

-- You can call this function without a ruleset to set it to vanilla
-- You can also call this function with a key to only affect that specific joker (might be useful)
function MP.LoadReworks(ruleset, key)
	ruleset = ruleset or "vanilla"
	if string.sub(ruleset, 1, 11) == "ruleset_mp_" then
		ruleset = string.sub(ruleset, 12, #ruleset)
	end
	local function process(key_, ruleset_)
		local center = G.P_CENTERS[key_]
		for k, v in pairs(center) do
			if string.sub(k, 1, #ruleset_) == ruleset_ then
				local orig = string.sub(k, #ruleset_ + 1)
				if orig == "rarity" then
					SMODS.remove_pool(G.P_JOKER_RARITY_POOLS[center[orig]], center.key)
					SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[center[k]], center, true)
				end
				center[orig] = center[k]
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
