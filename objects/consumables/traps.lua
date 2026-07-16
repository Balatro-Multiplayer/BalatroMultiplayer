-- Trap: a consumable type that reacts to something your Nemesis does. A Trap can only be
-- drafted from a Trap booster pack (objects/boosters/traps.lua); drafting one plants it,
-- face-down, in the drafter's Nemesis's own consumables instead of the drafter's (see
-- lib/trap_utils.lua's MP.TRAP.plant/disguise). When the Nemesis's own action satisfies the
-- trap's trigger, it reveals itself on their screen and its effect benefits the ORIGINAL
-- drafter -- who also gets a "use" animation on their own screen. See lib/trap_utils.lua for
-- the shared plant/disguise/reveal/notify_owner framework every card below reuses, and the
-- layer that gates when these can spawn at all in layers/traps.lua.
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
	-- Alarm: when the holder rerolls their shop, the drafter gains 2 free rerolls.
	{
		key = "trap_alarm",
		atlas = "t_alarm.png",
		calculate = function(self, card, context)
			if context.reroll_shop then
				MP.TRAP.reveal_and_consume(card)
				return MP.TRAP.notify_owner(card, { rerolls = 2 })
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			G.GAME.current_round.free_rerolls = (G.GAME.current_round.free_rerolls or 0) + context.data.rerolls
			MP.UI.show_trap_fired_animation("Alarm")
		end,
	},
	{ key = "trap_explosive_runes", atlas = "t_explosive_runes.png" },
	{ key = "trap_sepia_snake_sigil", atlas = "t_sepia_snake_sigil.png" },
	{ key = "trap_fire_trap", atlas = "t_fire_trap.png" },
	{ key = "trap_guards_and_wards", atlas = "t_guards_and_wards.png" },
	{ key = "trap_magic_mouth", atlas = "t_magic_mouth.png" },
	-- Snare: when the holder skips a blind, the drafter gains a copy of the tag they got.
	{
		key = "trap_snare",
		atlas = "t_snare.png",
		calculate = function(self, card, context)
			if context.skip_blind then
				local skipped_tag = G.GAME.tags[#G.GAME.tags]
				MP.TRAP.reveal_and_consume(card)
				return MP.TRAP.notify_owner(card, { tag_key = skipped_tag and skipped_tag.key })
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			if context.data.tag_key then
				add_tag(Tag(context.data.tag_key))
			end
			MP.UI.show_trap_fired_animation("Snare")
		end,
	},
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
	MPAPI.Consumable({
		key = def.key,
		set = "Trap",
		atlas = def.key,
		cost = 4,
		unlocked = true,
		discovered = true,
		-- A trap is never manually clicked once disguised in someone's inventory -- it fires
		-- passively via calculate. use() only exists for the draft-time interception below.
		can_use = function(self, card)
			return false
		end,
		-- Fires exactly once: the moment this card is drafted from a Trap pack (see
		-- lib/trap_utils.lua's MP.TRAP.plant for why this is the sole, exact interception point).
		use = function(self, card, area, copier)
			MP.TRAP.plant(card)
		end,
		calculate = def.calculate,
		receive = def.receive,
	})
end
