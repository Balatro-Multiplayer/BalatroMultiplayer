-- Each group enables its sandbox cards through MP.SANDBOX.is_joker_allowed
-- and silently bans the vanilla cards they replace.
MP.Layer("sandbox_rotation", {
	banned_silent = MP.SANDBOX.vanilla_bans_for("rotation"),
	mutator = {
		category = "JOKERS",
		order = 2,
		label = "Sandbox",
		desc = { "Adds the current Sandbox Jokers", "and replaces their original versions." },
		implied_by = "sandbox",
		count = #MP.SANDBOX.mappings_in("rotation"),
	},
})

MP.Layer("sandbox_retired", {
	banned_silent = MP.SANDBOX.vanilla_bans_for("retired"),
	mutator = {
		category = "JOKERS",
		order = 3,
		label = "Encore",
		desc = { "Brings back retired Sandbox Jokers", "and their balance changes." },
		count = #MP.SANDBOX.mappings_in("retired"),
	},
})

MP.Layer("sandbox_extra_credit", {
	on_apply_bans = MP.SANDBOX.ban_extra_credit_if_loaded,
	mutator = {
		category = "JOKERS",
		order = 4,
		label = "Extra Credit",
		desc = { "Adds Sandbox versions", "of Extra Credit Jokers." },
		unavailable = function()
			return SMODS.Mods["extracredit"] and SMODS.Mods["extracredit"].can_load
		end,
		unavailable_desc = { "Unavailable while", "Extra Credit is enabled." },
		implied_by = "sandbox",
		count = #MP.SANDBOX.mappings_in("extra_credit"),
	},
})

-- Idol picker: one wall cell driving four mutually exclusive layers. With none
-- of them on, the sandbox layer's seeded random pick applies.
for _, v in ipairs({ "zealot", "collector", "both", "none" }) do
	MP.Layer("idol_" .. v, { banned_silent = { "j_idol" } })
end

MP.Mutator({
	key = "idol",
	category = "JOKERS",
	order = 5,
	label = "Idol",
	desc = { "Choose which Sandbox Idol", "can appear. Random chooses", "one for the run." },
	variants = {
		{ label = "Idol: Random", mod = nil },
		{ label = "Idol: Zealot", mod = "idol_zealot" },
		{ label = "Idol: Collector", mod = "idol_collector" },
		{ label = "Idol: Both", mod = "idol_both" },
	},
	-- Reached with shift-click; not listed in the tooltip.
	secret = { label = "Idol: None", mod = "idol_none" },
})
