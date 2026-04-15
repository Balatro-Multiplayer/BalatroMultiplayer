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

-- Resolve layers on the init table before SMODS construction validates required_params
function MP.resolve_layers(init)
	if not init.layers then return init end
	for _, layer_name in ipairs(init.layers) do
		local layer = MP.Layers[layer_name]
		if not layer then error("Unknown layer: " .. tostring(layer_name)) end
		for k, v in pairs(layer) do
			if init[k] == nil then
				if type(v) == "table" then
					local copy = {}
					for i, item in ipairs(v) do
						copy[i] = item
					end
					init[k] = copy
				else
					init[k] = v
				end
			elseif type(v) == "table" and type(init[k]) == "table" then
				local merged = {}
				for _, item in ipairs(v) do
					merged[#merged + 1] = item
				end
				for _, item in ipairs(init[k]) do
					merged[#merged + 1] = item
				end
				init[k] = merged
			end
		end
	end
	init.layers = nil

	for _, field in ipairs(MP._LAYER_ARRAY_FIELDS) do
		if init[field] == nil then init[field] = {} end
	end
	return init
end
