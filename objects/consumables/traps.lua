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
	-- Glyph of Warding: when the holder uses a Spectral card, the drafter gets a Jumbo
	-- Spectral pack to open.
	{
		key = "trap_glyph_of_warding",
		atlas = "t_glyph_of_warding.png",
		calculate = function(self, card, context)
			if context.using_consumeable and context.consumeable.config.center.set == "Spectral" then
				MP.TRAP.reveal_and_consume(card)
				return MP.TRAP.notify_owner(card, {})
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			local pack_card = SMODS.add_card({ key = "p_spectral_jumbo_1", area = G.consumeables, skip_materialize = true })
			if pack_card and pack_card.open then
				pack_card:open()
			end
			MP.UI.show_trap_fired_animation("Glyph of Warding")
		end,
	},
	-- Symbol: when the holder plays a flush, convert all scored cards to random suits.
	{
		key = "trap_symbol",
		atlas = "t_symbol.png",
		calculate = function(self, card, context)
			if context.before and context.poker_hands and next(context.poker_hands["Flush"]) then
				MP.TRAP.reveal_and_consume(card)
				for _, scored in ipairs(context.scoring_hand or {}) do
					local suit = pseudorandom_element({ "Spades", "Hearts", "Clubs", "Diamonds" }, pseudoseed("mp_trap_symbol"))
					scored:change_suit(suit)
				end
				return MP.TRAP.notify_owner(card, {})
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			MP.UI.show_trap_fired_animation("Symbol")
		end,
	},
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
	-- Explosive Runes: when the holder plays a hand with a glass card, all glass cards in
	-- that hand are guaranteed to break. Deferred: forcing a glass break bypasses SMODS's own
	-- probability roll and needs its own destroy_card-context hook (see plan's Phase 3 notes);
	-- not yet implemented.
	{ key = "trap_explosive_runes", atlas = "t_explosive_runes.png" },
	-- Sepia Snake Sigil: when the holder buys a Rare Joker, the drafter gains a copy of it.
	{
		key = "trap_sepia_snake_sigil",
		atlas = "t_sepia_snake_sigil.png",
		calculate = function(self, card, context)
			if
				context.buying_card
				and context.card.ability.set == "Joker"
				and (context.card.config.center.rarity == 3 or context.card.config.center.rarity == "Rare")
			then
				MP.TRAP.reveal_and_consume(card)
				return MP.TRAP.notify_owner(card, { key = context.card.config.center.key })
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			if context.data.key then
				SMODS.add_card({ key = context.data.key, area = G.jokers })
			end
			MP.UI.show_trap_fired_animation("Sepia Snake Sigil")
		end,
	},
	-- Fire Trap: when the holder plays a hand with a pair, decrease the rank of all scored
	-- cards by 1.
	{
		key = "trap_fire_trap",
		atlas = "t_fire_trap.png",
		calculate = function(self, card, context)
			if context.before and context.poker_hands and next(context.poker_hands["Pair"]) then
				MP.TRAP.reveal_and_consume(card)
				for _, scored in ipairs(context.scoring_hand or {}) do
					MP.TRAP.decrease_rank(scored)
				end
				return MP.TRAP.notify_owner(card, {})
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			MP.UI.show_trap_fired_animation("Fire Trap")
		end,
	},
	-- Guards and Wards: when the holder adds a playing card to their deck, add 2 Stone cards
	-- to their deck.
	{
		key = "trap_guards_and_wards",
		atlas = "t_guards_and_wards.png",
		calculate = function(self, card, context)
			if context.playing_card_added then
				MP.TRAP.reveal_and_consume(card)
				return MP.TRAP.notify_owner(card, {})
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			for _ = 1, 2 do
				create_playing_card({
					front = pseudorandom_element(G.P_CARDS, pseudoseed("mp_trap_guards")),
					center = G.P_CENTERS.m_stone,
				}, G.deck)
			end
			MP.UI.show_trap_fired_animation("Guards and Wards")
		end,
	},
	-- Magic Mouth: when the holder triggers a blue or purple seal, steal the consumable.
	-- Deferred: seal triggers resolve via direct per-card method calls (Card:calculate_seal /
	-- Card:get_end_of_round_effect), never a broadcast calculate context -- needs its own hook.
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
	-- Arcane Lock: when the holder uses (i.e. a different planted trap fires on) a Trap card,
	-- they get trapped instead. Deferred: needs a "another trap just fired" signal, which isn't
	-- a natural calculate-context flag -- would need MP.TRAP.reveal_and_consume itself to fire a
	-- custom local context so a co-resident Arcane Lock can intercept. Not yet implemented.
	{ key = "trap_arcane_lock", atlas = "t_arcane_lock.png" },
	-- Programmed Illusion: when the holder opens a booster pack, add a fake card to it.
	-- Deferred: Card:open builds its pack_cards list in a function-local table with no exposed
	-- extension point for injecting an extra card -- needs a direct hook/override, not a
	-- calculate-context check. Not yet implemented.
	{ key = "trap_programmed_illusion", atlas = "t_programmed_illusion.png" },
	-- Web: when the holder uses any consumable, the drafter gains a negative copy of it.
	{
		key = "trap_web",
		atlas = "t_web.png",
		calculate = function(self, card, context)
			if context.using_consumeable then
				MP.TRAP.reveal_and_consume(card)
				return MP.TRAP.notify_owner(card, { key = context.consumeable.config.center.key })
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			if context.data.key then
				SMODS.add_card({ key = context.data.key, area = G.consumeables, edition = "e_negative" })
			end
			MP.UI.show_trap_fired_animation("Web")
		end,
	},
	-- Forbiddance: when the holder discards, the cards drawn from their deck are flipped.
	-- Deferred: the draw loop (G.FUNCS.draw_from_deck_to_hand) has no exposed "flip after
	-- draw" hook -- needs a new override on the draw path, not a calculate-context check.
	-- Not yet implemented.
	{ key = "trap_forbiddance", atlas = "t_forbiddance.png" },
	-- Faithful Hound: when the holder uses a Planet card, the drafter gains 3 levels of that
	-- poker hand.
	{
		key = "trap_faithful_hound",
		atlas = "t_faithful_hound.png",
		calculate = function(self, card, context)
			if context.using_consumeable and context.consumeable.config.center.set == "Planet" then
				local hand_type = context.consumeable.ability.consumeable and context.consumeable.ability.consumeable.hand_type
				if hand_type then
					MP.TRAP.reveal_and_consume(card)
					return MP.TRAP.notify_owner(card, { hand_type = hand_type })
				end
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			if context.data.hand_type then
				level_up_hand(nil, context.data.hand_type, true, 3)
			end
			MP.UI.show_trap_fired_animation("Faithful Hound")
		end,
	},
	-- Phase Door: when the holder scores a gold card, the drafter gains $4 per gold card in
	-- their hand.
	{
		key = "trap_phase_door",
		atlas = "t_phase_door.png",
		calculate = function(self, card, context)
			if context.before and context.scoring_hand then
				local gold_count = 0
				for _, scored in ipairs(context.scoring_hand) do
					if SMODS.has_enhancement(scored, "m_gold") then
						gold_count = gold_count + 1
					end
				end
				if gold_count > 0 then
					MP.TRAP.reveal_and_consume(card)
					return MP.TRAP.notify_owner(card, { dollars = gold_count * 4 })
				end
			end
		end,
		receive = function(self, context)
			if context.data.owner ~= MP.TRAP.self_id() then
				return
			end
			ease_dollars(context.data.dollars, true)
			MP.UI.show_trap_fired_animation("Phase Door")
		end,
	},
	-- Mental Prison: when the holder fails to use a Wheel of Fortune they saw in a shop, create
	-- 2 Wheel of Fortunes. Deferred: needs new state-tracking (record Wheel of Fortune
	-- appearances per shop visit, checked at ending_shop) -- not a pure calculate-context check.
	-- Not yet implemented.
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
