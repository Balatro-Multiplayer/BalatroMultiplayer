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
	},
	class_prefix = "ruleset",
	inject = function(self)
		MP.Rulesets[self.key] = self
		if not G.P_CENTER_POOLS.Ruleset then
			G.P_CENTER_POOLS.Ruleset = {}
		end
		table.insert(G.P_CENTER_POOLS.Ruleset, self)
		-- self.overrides()
	end,
	process_loc_text = function(self)
		SMODS.process_loc_text(G.localization.descriptions["Ruleset"], self.key, self.loc_txt)
	end,
	is_disabled = function(self)
		return false
	end,
})

MP.BANNED_OBJECTS = {
	jokers = {},
	consumables = {},
	vouchers = {},
	enhancements = {},
	tags = {},
	blinds = {},
}

function new_in_pool_for_blind(v) -- For blinds specifically, in_pool does overwrite basic checks like minimum ante, so we need to repackage all basic checks inside the new in_pool
	if MP.LOBBY.code then
		return false
	elseif
		not v.boss.showdown
		and (
			v.boss.min <= math.max(1, G.GAME.round_resets.ante)
			and ((math.max(1, G.GAME.round_resets.ante)) % G.GAME.win_ante ~= 0 or G.GAME.round_resets.ante < 2)
		)
	then
		return true
	elseif v.boss.showdown and G.GAME.round_resets.ante % G.GAME.win_ante == 0 and G.GAME.round_resets.ante >= 2 then
		return true
	else
		return false
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
			if k ~= "key" and k ~= ruleset then
				center[ruleset_ .. k] = v
				if not center["mp_vanilla_" .. k] then
					center["mp_vanilla_" .. k] = center[k]
				end
			end
		end
		center.mp_reworks = center.mp_reworks or {}
		center.mp_reworks[ruleset] = true -- Caching this for better load times since we're gonna be inefficiently looping through all centers probably
		center.mp_reworks["vanilla"] = true
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
	MP.AddOverrides(ruleset)
end

function MP.AddOverrides(rulesetName)
	print("MP.AddOverrides called with rulesetName:", rulesetName)

	if not MP.INTEGRATIONS.TheOrder then
		print("MP.INTEGRATIONS.TheOrder is false/nil, returning early")
		return
	end

	print("MP.INTEGRATIONS.TheOrder is available")

	if rulesetName ~= "sandbox" then
		the_order_standard_pack_ownership()
		return
	end

	print("Processing sandbox ruleset")
	-- TODO: Should we do this also for uhhhh whatever that voucher is called?
	SMODS.Booster:take_ownership_by_kind("Standard", {
		create_card = function(self, card, i)
			print("Creating card for sandbox ruleset, card index:", i)
			local enhancement_pool = {}

			-- Skip glass
			for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
				if v.key ~= "m_glass" then
					enhancement_pool[#enhancement_pool + 1] = v
				end
			end

			print("Built enchantment pool with", #enhancement_pool, "items (excluding glass)")

			local ante_rng = MP.ante_based()
			print("Generated ante_rng:", ante_rng)

			local default_center = G.P_CENTERS.c_base
			local roll = pseudorandom(pseudoseed("stdc1" .. ante_rng))

			print("Rolled ", roll)

			local center = roll > 0.6 and pseudorandom_element(enhancement_pool, pseudoseed("stdc2" .. ante_rng))
				or default_center

			print("Center gotten:", center.name)

			local _edition = poll_edition("standard_edition" .. ante_rng, 2, true)
			print("Generated edition:", _edition and _edition.key or "nil")

			local _seal = SMODS.poll_seal({ mod = 10, key = "stdseal" .. ante_rng })
			print("Generated seal:", _seal and _seal.key or "nil")

			-- TOOD: Not actually added to someones inventory?
			local newCard = create_playing_card({
				front = pseudorandom_element(G.P_CARDS, pseudoseed("stdset" .. ante_rng)),
				center = center,
			}, G.pack_cards, true, i ~= 1, { G.C.SECONDARY_SET.Default })

			newCard:set_edition(_edition)
			newCard:set_seal(_seal)

			print("Created new card with key:", newCard.config.center.key)

			return newCard
		end,
	}, true)
	print("Finished setting up sandbox standard pack override")

	print("MP.AddOverrides completed")
end

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
})

MP.BANNED_OBJECTS = {
	jokers = {},
	consumables = {},
	vouchers = {},
	enhancements = {},
	tags = {},
	blinds = {},
}

function new_in_pool_for_blind(v) -- For blinds specifically, in_pool does overwrite basic checks like minimum ante, so we need to repackage all basic checks inside the new in_pool
	if MP.LOBBY.code then
		return false
	elseif
		not v.boss.showdown
		and (
			v.boss.min <= math.max(1, G.GAME.round_resets.ante)
			and ((math.max(1, G.GAME.round_resets.ante)) % G.GAME.win_ante ~= 0 or G.GAME.round_resets.ante < 2)
		)
	then
		return true
	elseif v.boss.showdown and G.GAME.round_resets.ante % G.GAME.win_ante == 0 and G.GAME.round_resets.ante >= 2 then
		return true
	else
		return false
	end
end

function MP.apply_rulesets()
	for _, ruleset in pairs(MP.Rulesets) do
		local function process_banned_items(banned_items, banned_table)
			if not banned_items then
				return
			end
			for _, item_key in ipairs(banned_items) do
				banned_table[item_key] = banned_table[item_key] or {}
				banned_table[item_key][ruleset.key] = true
			end
		end

		local banned_types = {
			{ items = ruleset.banned_jokers, table = MP.BANNED_OBJECTS.jokers },
			{ items = ruleset.banned_consumables, table = MP.BANNED_OBJECTS.consumables },
			{ items = ruleset.banned_vouchers, table = MP.BANNED_OBJECTS.vouchers },
			{ items = ruleset.banned_enhancements, table = MP.BANNED_OBJECTS.enhancements },
			{ items = ruleset.banned_tags, table = MP.BANNED_OBJECTS.tags },
			{ items = ruleset.banned_blinds, table = MP.BANNED_OBJECTS.blinds },
		}

		for _, banned_type in ipairs(banned_types) do
			process_banned_items(banned_type.items, banned_type.table)
		end
	end

	local object_types = {
		{ objects = MP.BANNED_OBJECTS.jokers, mod = SMODS.Joker, global_banned = MP.DECK.BANNED_JOKERS },
		{ objects = MP.BANNED_OBJECTS.consumables, mod = SMODS.Consumable, global_banned = MP.DECK.BANNED_CONSUMABLES },
		{ objects = MP.BANNED_OBJECTS.vouchers, mod = SMODS.Voucher, global_banned = MP.DECK.BANNED_VOUCHERS },
		{
			objects = MP.BANNED_OBJECTS.enhancements,
			mod = SMODS.Enhancement,
			global_banned = MP.DECK.BANNED_ENHANCEMENTS,
		},
		{ objects = MP.BANNED_OBJECTS.tags, mod = SMODS.Tag, global_banned = MP.DECK.BANNED_TAGS },
		{ objects = MP.BANNED_OBJECTS.blinds, mod = SMODS.Blind, global_banned = MP.DECK.BANNED_BLINDS },
	}

	for _, type in ipairs(object_types) do
		for obj_key, rulesets in pairs(type.objects) do
			-- Find object with object key, using the same method as take_ownership
			local obj = type.mod.obj_table[obj_key] or (type.mod.get_obj and type.mod:get_obj(obj_key))

			if obj then
				local old_in_pool = obj.in_pool
				type.mod:take_ownership(obj_key, {
					orig_in_pool = old_in_pool, -- Save the original in_pool function inside the object itself
					in_pool = function(self) -- Update the in_pool function
						if rulesets[MP.LOBBY.config.ruleset] and MP.LOBBY.code then
							return false
						elseif self.orig_in_pool then
							-- behave like the original in_pool function if it's not nil
							return self:orig_in_pool()
						else
							return self.set ~= "Blind" or new_in_pool_for_blind(self) -- in_pool returning true doesn't overwrite original checks EXCEPT for blinds
						end
					end,
				}, true)
			else
				sendWarnMessage(("Cannot ban %s: Does not exist."):format(obj_key), type.mod.set)
			end
		end
		for obj_key, _ in pairs(type.global_banned) do
			type.mod:take_ownership(obj_key, {
				in_pool = function(self)
					if self.set ~= "Blind" then
						return not MP.LOBBY.code
					else
						return new_in_pool_for_blind(self)
					end
				end,
			}, true)
		end
	end
end
