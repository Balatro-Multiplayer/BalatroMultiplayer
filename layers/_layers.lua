MP.Layers = {}

-- Reverse index: joker full key -> array of layer names that list it.
-- Used to auto-attach `mp_include` on jokers whose only gating is layer membership,
-- so the joker file doesn't have to repeat what the layer already declared.
MP._JOKER_LAYERS = {}

function MP.Layer(name, definition)
	MP.Layers[name] = definition
	if definition.reworked_jokers then
		for _, joker_key in ipairs(definition.reworked_jokers) do
			MP._JOKER_LAYERS[joker_key] = MP._JOKER_LAYERS[joker_key] or {}
			table.insert(MP._JOKER_LAYERS[joker_key], name)
		end
	end
end

-- Eldritch horror warning
-- The profane machinery below, the proxy wearing SMODS.Joker's skin, exists for
-- one purpose only: to supply a default value for a function parameter.
-- We replace SMODS.Joker with a hollow table wearing a metatable: 
-- __index forwards reads, __newindex forwards writes, __call forwards calls. 
-- From outside it is indistinguishable from the real thing.
-- From inside, every joker registration passes through __call, 
-- where we rifle through the init table and – if the joker belongs 
-- to a known layer and didn't bring its own mp_include – graft on
-- a default gate before passing it through.
-- The real SMODS.Joker never knows it's been intercepted. 
-- `is_layer_active` returns false outside a live ruleset context (lobby or practice),
-- so the default gate fails closed. Jokers with bespoke mp_include slip past untouched.
local _smods_joker = SMODS.Joker
SMODS.Joker = setmetatable({}, {
	__index = _smods_joker,
	__newindex = function(_, k, v)
		_smods_joker[k] = v
	end,
	__call = function(_, init)
		if init and not init.mp_include and init.key then
			local prefix = (SMODS.current_mod and SMODS.current_mod.prefix) or "mp"
			local full_key = "j_" .. prefix .. "_" .. init.key
			local owning_layers = MP._JOKER_LAYERS[full_key]
			if owning_layers then
				sendDebugMessage(
					"Auto-gating " .. full_key .. " on layers: " .. table.concat(owning_layers, ", "),
					"MULTIPLAYER"
				)
				init.mp_include = function(self)
					for _, layer_name in ipairs(owning_layers) do
						if MP.is_layer_active(layer_name) then return true end
					end
					return false
				end
			end
		end
		return _smods_joker(init)
	end,
})

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
		if layer and layer[hook_name] then
			layer[hook_name]()
		end
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
