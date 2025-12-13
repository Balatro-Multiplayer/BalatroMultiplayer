-- Rubber Ducky - Extra Credit Joker ported to Sandbox
-- Played cards lose chips when scored, joker gains them

SMODS.Joker({
	key = "rubberducky_sandbox",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = false,
	rarity = 2,
	cost = 5,
	atlas = "ec_jokers_sandbox",
	pos = { x = 4, y = 0 },
	config = { extra = { chips = 0, suck = 3, min_bonus = 0 }, mp_sticker_balanced = true },

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips, card.ability.extra.suck } }
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.play and context.individual and not context.blueprint then
			card.ability.extra.min_bonus = 0
			context.other_card.ability.perma_bonus = context.other_card.ability.perma_bonus or 0
			if context.other_card.ability.name == "Stone Card" then
				card.ability.extra.min_bonus = 50 * -1
			elseif context.other_card.ability.name == "Bonus" then
				card.ability.extra.min_bonus = (30 + context.other_card.base.nominal) * -1
			else
				card.ability.extra.min_bonus = context.other_card.base.nominal * -1
			end

			if context.other_card.ability.perma_bonus > card.ability.extra.min_bonus then
				local thunk = context.other_card.ability.perma_bonus
				context.other_card.ability.perma_bonus = math.max((context.other_card.ability.perma_bonus - card.ability.extra.suck), card.ability.extra.min_bonus)
				thunk = thunk - context.other_card.ability.perma_bonus
				card.ability.extra.chips = card.ability.extra.chips + thunk
				return {
					extra = { message = localize("k_eaten_ex"), colour = G.C.CHIPS },
					colour = G.C.CHIPS,
					card = card,
				}
			end
		elseif context.cardarea == G.jokers and context.joker_main then
			return {
				message = localize({ type = "variable", key = "a_chips", vars = { card.ability.extra.chips } }),
				chip_mod = card.ability.extra.chips,
				colour = G.C.CHIPS,
			}
		end
	end,

	mp_credits = { code = { "extracredit" } },
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
