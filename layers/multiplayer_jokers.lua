-- Pool membership follows run configuration in multiplayer, practice and
-- replays alike. Card effects handle whether an opponent is present.
MP.Layer("multiplayer_jokers", {
	multiplayer_content = true,
	included_jokers = {
		"j_mp_speedrun",
		"j_mp_conjoined_joker",
		"j_mp_defensive_joker",
		"j_mp_pizza",
		"j_mp_penny_pincher",
		"j_mp_pacifist",
		"j_mp_lets_go_gambling",
		"j_mp_taxes",
		"j_mp_skip_off",
	},
	included_consumables = { "c_mp_asteroid" },
	pool_enabled = function()
		return MP.current_ruleset().multiplayer_content == true
	end,
	mutator = {
		category = "JOKERS",
		order = 1,
		label = "MP Jokers",
		desc = {
			"Adds Multiplayer Jokers and Asteroid.",
			"Default follows your base ruleset.",
			"Choose On or Off to change it.",
		},
		implied_by = "multiplayer_jokers",
		variants = {
			{ label = "MP Jokers: Default" },
			{ label = "MP Jokers: On", mod = "multiplayer_jokers" },
			{ label = "MP Jokers: Off", mod = "no_multiplayer_jokers" },
		},
	},
})

-- Override inherited content through pool_enabled/mp_include. Exclusion
-- removes these cards' pool slots; banning them would leave UNAVAILABLE slots
-- and change the seeded selection of the remaining cards.
MP.Layer("no_multiplayer_jokers", { multiplayer_content = false })

function MP.multiplayer_jokers_enabled()
	return MP.pool_layer_active("multiplayer_jokers")
end

function MP.set_multiplayer_jokers(enabled)
	local cycle = MP.MUTATORS.multiplayer_jokers
	MP.set_variant(cycle, cycle.variants[enabled and 2 or 3])
end

-- Legacy lobby/replay booleans are imported once, after modifier_layers has
-- been parsed. Matching native choices retain their original modifier order.
function MP.import_multiplayer_jokers(value)
	if value == nil then return end
	local enabled = value == true or value == "true"
	if enabled ~= MP.multiplayer_jokers_enabled() then MP.set_multiplayer_jokers(enabled) end
end
