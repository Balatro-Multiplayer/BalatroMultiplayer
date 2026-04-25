MP.Layers = {}

function MP.Layer(name, definition)
	MP.Layers[name] = definition
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
