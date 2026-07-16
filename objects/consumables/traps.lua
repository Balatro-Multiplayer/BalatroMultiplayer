-- Trap: a new consumable type that reacts to something your Nemesis does. Visual/
-- registration only for now -- no calculate/use effects yet (see layers/traps.lua
-- for the layer that gates when these can spawn at all).
SMODS.ConsumableType({
	key = "Trap",
	primary_colour = MP.COLOURS.BLACK,
	secondary_colour = MP.COLOURS.DARK_PINK,
	loc_txt = {
		["en-us"] = {
			name = "Trap",
			collection = "{} Trap Cards",
			undiscovered = "??? Trap Card",
		},
	},
})

local TRAPS = {
	{ key = "trap_glyph_of_warding", atlas = "t_glyph_of_warding.png" },
	{ key = "trap_symbol", atlas = "t_symbol.png" },
	{ key = "trap_alarm", atlas = "t_alarm.png" },
	{ key = "trap_explosive_runes", atlas = "t_explosive_runes.png" },
	{ key = "trap_sepia_snake_sigil", atlas = "t_sepia_snake_sigil.png" },
	{ key = "trap_fire_trap", atlas = "t_fire_trap.png" },
	{ key = "trap_guards_and_wards", atlas = "t_guards_and_wards.png" },
	{ key = "trap_magic_mouth", atlas = "t_magic_mouth.png" },
	{ key = "trap_snare", atlas = "t_snare.png" },
	{ key = "trap_arcane_lock", atlas = "t_arcane_lock.png" },
	{ key = "trap_programmed_illusion", atlas = "t_programmed_illusion.png" },
	{ key = "trap_web", atlas = "t_web.png" },
	{ key = "trap_forbiddance", atlas = "t_forbiddance.png" },
	{ key = "trap_faithful_hound", atlas = "t_faithful_hound.png" },
	{ key = "trap_phase_door", atlas = "t_phase_door.png" },
	{ key = "trap_mental_prison", atlas = "t_mental_prison.png" },
}

for _, def in ipairs(TRAPS) do
	SMODS.Atlas({
		key = def.key,
		path = def.atlas,
		px = 71,
		py = 95,
	})
	SMODS.Consumable({
		key = def.key,
		set = "Trap",
		atlas = def.key,
		cost = 4,
		unlocked = true,
		discovered = true,
	})
end
