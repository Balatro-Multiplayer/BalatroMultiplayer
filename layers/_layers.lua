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
        return MP.is_any_layer_active(owning_layers)
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

-- ----------------------------------------------------------------------------
-- Modifier layers
-- ----------------------------------------------------------------------------
-- MP.MODIFIERS is an ordered list of layer names picked at runtime (host in
-- the Modifiers overlay, or player in practice mode). Modifiers are *not*
-- materialized onto the ruleset — they're queried at read sites alongside the
-- ruleset's own layers. Reset to {} on lobby leave / practice exit.

MP.MODIFIERS = {}

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

-- Fire a named hook on every layer in the active chain. The ruleset's
-- self-name appears in the chain but isn't registered in MP.Layers, so the
-- lookup no-ops harmlessly.
function MP.RunLayerHooks(hook_name)
	for _, name in ipairs(MP.active_layer_chain()) do
		local layer = MP.Layers[name]
		if layer and layer[hook_name] then layer[hook_name]() end
	end
end

function MP.is_layer_active(layer_name)
	for _, name in ipairs(MP.active_layer_chain()) do
		if name == layer_name then return true end
	end
	return false
end

function MP.is_any_layer_active(layers)
    for _, layer_name in ipairs(layers) do
        if MP.is_layer_active(layer_name) then return true end
    end
    return false
end