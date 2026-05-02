MP.Layers = {}

-- Reverse indices: full key -> array of layer names that list it.
-- Used to auto-attach `mp_include` on cards whose only gating is layer membership,
-- so the object file doesn't have to repeat what the layer already declared.
MP._JOKER_LAYERS = {}
MP._CONSUMABLE_LAYERS = {}

function MP.Layer(name, definition)
	MP.Layers[name] = definition
	if definition.reworked_jokers then
		for _, joker_key in ipairs(definition.reworked_jokers) do
			MP._JOKER_LAYERS[joker_key] = MP._JOKER_LAYERS[joker_key] or {}
			table.insert(MP._JOKER_LAYERS[joker_key], name)
		end
	end
	if definition.reworked_consumables then
		for _, consumable_key in ipairs(definition.reworked_consumables) do
			MP._CONSUMABLE_LAYERS[consumable_key] = MP._CONSUMABLE_LAYERS[consumable_key] or {}
			table.insert(MP._CONSUMABLE_LAYERS[consumable_key], name)
		end
	end
end

-- Build an mp_include closure that returns true iff any of the named layers is active.
local function layer_membership_include(owning_layers)
	return function(_)
		for _, layer_name in ipairs(owning_layers) do
			if MP.is_layer_active(layer_name) then return true end
		end
		return false
	end
end

-- A small graft on SMODS.Joker:register. Any joker whose full key appears in some
-- layer's reworked_jokers gets a default mp_include stitched on when none is
-- provided. By the time register runs the key is already prefixed, so we can look
-- it up directly. is_layer_active fails closed outside a live ruleset context, and
-- bespoke mp_include slips past untouched.
local _original_joker_register = SMODS.Joker.register
function SMODS.Joker:register()
	if not self.mp_include and MP._JOKER_LAYERS[self.key] then
		local owning_layers = MP._JOKER_LAYERS[self.key]
		sendDebugMessage(
			"Auto-gating " .. self.key .. " on layers: " .. table.concat(owning_layers, ", "),
			"MULTIPLAYER"
		)
		self.mp_include = layer_membership_include(owning_layers)
	end
	return _original_joker_register(self)
end

-- Same graft for consumables. The lovely patch in lovely/misc.toml that filters
-- _pool entries by mp_include works on any center, so consumables behave the
-- same way as jokers once mp_include is set.
local _original_consumable_register = SMODS.Consumable.register
function SMODS.Consumable:register()
	if not self.mp_include and MP._CONSUMABLE_LAYERS[self.key] then
		local owning_layers = MP._CONSUMABLE_LAYERS[self.key]
		sendDebugMessage(
			"Auto-gating " .. self.key .. " on layers: " .. table.concat(owning_layers, ", "),
			"MULTIPLAYER"
		)
		self.mp_include = layer_membership_include(owning_layers)
	end
	return _original_consumable_register(self)
end

-- Array-valued fields that get merged (layer base + ruleset additions)
MP._LAYER_ARRAY_FIELDS = {
	"banned_jokers",
	"banned_consumables",
	"banned_vouchers",
	"banned_enhancements",
	"banned_tags",
	"banned_blinds",
	"banned_silent",
	"reworked_jokers",
	"reworked_consumables",
	"reworked_vouchers",
	"reworked_enhancements",
	"reworked_tags",
	"reworked_blinds",
}

-- Resolve layers on the init table before SMODS construction validates required_params.
-- Scalars: last layer wins, but the ruleset's own value always beats any layer.
-- Arrays: concatenated across all layers + ruleset.
function MP.resolve_layers(init)
	if not init.layers then return init end
	local ruleset_owned = {}
	for k in pairs(init) do
		ruleset_owned[k] = true
	end
	for _, layer_name in ipairs(init.layers) do
		local layer = MP.Layers[layer_name]
		if not layer then error("Unknown layer: " .. tostring(layer_name)) end
		for k, v in pairs(layer) do
			if type(v) == "table" then
				if init[k] == nil then
					local copy = {}
					for i, item in ipairs(v) do
						copy[i] = item
					end
					init[k] = copy
				elseif type(init[k]) == "table" then
					local merged = {}
					for _, item in ipairs(v) do
						merged[#merged + 1] = item
					end
					for _, item in ipairs(init[k]) do
						merged[#merged + 1] = item
					end
					init[k] = merged
				end
			elseif not ruleset_owned[k] then
				init[k] = v
			end
		end
	end
	-- Preserve resolved layer names (ordered list + lookup set)
	local layer_set = {}
	local layer_order = {}
	for _, layer_name in ipairs(init.layers) do
		layer_set[layer_name] = true
		layer_order[#layer_order + 1] = layer_name
	end
	init._layers = layer_set
	init._layer_order = layer_order
	init.layers = nil

	for _, field in ipairs(MP._LAYER_ARRAY_FIELDS) do
		if init[field] == nil then init[field] = {} end
	end
	return init
end

-- Call a named hook on each active layer, in layer order
function MP.RunLayerHooks(hook_name)
	local ruleset_key = MP.get_active_ruleset()
	if not ruleset_key then return end
	local ruleset = MP.Rulesets[ruleset_key]
	if not ruleset or not ruleset._layer_order then return end
	for _, layer_name in ipairs(ruleset._layer_order) do
		local layer = MP.Layers[layer_name]
		if layer and layer[hook_name] then layer[hook_name]() end
	end
end

function MP.is_layer_active(layer_name)
	local ruleset_key = MP.get_active_ruleset()
	if not ruleset_key then return false end
	-- Every ruleset is implicitly its own layer
	if ruleset_key == "ruleset_mp_" .. layer_name then return true end
	local ruleset = MP.Rulesets[ruleset_key]
	return ruleset and ruleset._layers and ruleset._layers[layer_name] or false
end

-- ----------------------------------------------------------------------------
-- Modifier layers
-- ----------------------------------------------------------------------------
-- Runtime-toggleable layers picked by the host in the Modifiers overlay (or by
-- the player in practice mode). Source of truth is MP.MODIFIERS — an ordered
-- list of layer names. At lobby/practice create we *graft* these onto the
-- active ruleset's _layer_order/_layers and merge their banned_*/reworked_*
-- arrays and scalars in. After that, modifier layers ARE just layers as far as
-- is_layer_active, RunLayerHooks, LoadReworks, ApplyBans, and ruleset UI tabs
-- are concerned. On lobby leave / practice exit we restore from the snapshot.
--
-- Modifier layers are appended last in the layer order, so their scalars beat
-- both ruleset layers and the ruleset's own scalar values — modifiers are an
-- explicit override.

MP.MODIFIERS = {}

local _array_field_set = {}
for _, f in ipairs(MP._LAYER_ARRAY_FIELDS) do
	_array_field_set[f] = true
end

local _ruleset_snapshots = {} -- key -> snapshot
local _augmented_key = nil    -- which ruleset is currently grafted

local function shallow_copy_array(arr)
	local out = {}
	for i, v in ipairs(arr or {}) do
		out[i] = v
	end
	return out
end

local function shallow_copy_set(t)
	local out = {}
	for k, v in pairs(t or {}) do
		out[k] = v
	end
	return out
end

-- Snapshot ruleset state we'll mutate. Captures _layer_order, _layers, every
-- array field, and any scalar a modifier layer might overwrite (computed
-- lazily as we apply, so the snapshot only grows).
local function take_snapshot(ruleset)
	local snap = {
		_layer_order = shallow_copy_array(ruleset._layer_order),
		_layers = shallow_copy_set(ruleset._layers),
		arrays = {},
		scalars = {}, -- field -> original value, or "NULL" sentinel for nil
	}
	for _, field in ipairs(MP._LAYER_ARRAY_FIELDS) do
		snap.arrays[field] = shallow_copy_array(ruleset[field])
	end
	return snap
end

local function restore_from_snapshot(ruleset, snap)
	ruleset._layer_order = shallow_copy_array(snap._layer_order)
	ruleset._layers = shallow_copy_set(snap._layers)
	for _, field in ipairs(MP._LAYER_ARRAY_FIELDS) do
		ruleset[field] = shallow_copy_array(snap.arrays[field])
	end
	for k, v in pairs(snap.scalars) do
		if v == "NULL" then
			ruleset[k] = nil
		else
			ruleset[k] = v
		end
	end
end

-- Apply MP.MODIFIERS to the active ruleset. Idempotent: if a different ruleset
-- was previously grafted we restore it first, and re-applying onto the same
-- ruleset re-resets to snapshot before grafting.
function MP.apply_modifiers()
	local ruleset_key = MP.get_active_ruleset()
	if not ruleset_key then return end
	local ruleset = MP.Rulesets[ruleset_key]
	if not ruleset then return end

	if _augmented_key and _augmented_key ~= ruleset_key then
		local prev = MP.Rulesets[_augmented_key]
		local prev_snap = _ruleset_snapshots[_augmented_key]
		if prev and prev_snap then
			restore_from_snapshot(prev, prev_snap)
		end
		_ruleset_snapshots[_augmented_key] = nil
	end

	local snap = _ruleset_snapshots[ruleset_key]
	if not snap then
		snap = take_snapshot(ruleset)
		_ruleset_snapshots[ruleset_key] = snap
	else
		restore_from_snapshot(ruleset, snap)
	end
	_augmented_key = ruleset_key

	for _, mod_name in ipairs(MP.MODIFIERS) do
		local layer = MP.Layers[mod_name]
		if layer and not ruleset._layers[mod_name] then
			ruleset._layer_order[#ruleset._layer_order + 1] = mod_name
			ruleset._layers[mod_name] = true
			for k, v in pairs(layer) do
				if _array_field_set[k] then
					if type(v) == "table" then
						local target = ruleset[k]
						for _, item in ipairs(v) do
							target[#target + 1] = item
						end
					end
				elseif type(v) ~= "table" and type(v) ~= "function" then
					if snap.scalars[k] == nil then
						snap.scalars[k] = ruleset[k] == nil and "NULL" or ruleset[k]
					end
					ruleset[k] = v
				end
			end
		end
	end
end

-- Restore the augmented ruleset and clear MP.MODIFIERS. Call on lobby leave,
-- practice exit, or whenever entering a fresh selection screen.
function MP.clear_modifiers()
	if _augmented_key then
		local ruleset = MP.Rulesets[_augmented_key]
		local snap = _ruleset_snapshots[_augmented_key]
		if ruleset and snap then
			restore_from_snapshot(ruleset, snap)
		end
		_ruleset_snapshots[_augmented_key] = nil
		_augmented_key = nil
	end
	MP.MODIFIERS = {}
end

function MP.has_modifier(name)
	for _, n in ipairs(MP.MODIFIERS) do
		if n == name then return true end
	end
	return false
end

function MP.add_modifier(name)
	if not name or name == "" or MP.has_modifier(name) then return end
	MP.MODIFIERS[#MP.MODIFIERS + 1] = name
end

function MP.remove_modifier(name)
	for i, n in ipairs(MP.MODIFIERS) do
		if n == name then
			table.remove(MP.MODIFIERS, i)
			return
		end
	end
end

-- Wire format: comma-separated string for the existing lobby_options protocol.
function MP.modifiers_serialize()
	return table.concat(MP.MODIFIERS, ",")
end

function MP.modifiers_parse(s)
	MP.MODIFIERS = {}
	if not s or s == "" then return end
	for n in string.gmatch(s, "[^,]+") do
		MP.MODIFIERS[#MP.MODIFIERS + 1] = n
	end
end
