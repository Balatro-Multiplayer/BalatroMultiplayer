SMODS.Atlas({
	key = "idol_sandbox_bw",
	path = "j_idol_sandbox_bw.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "idol_sandbox_bw",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	rarity = 2,
	cost = 6,
	atlas = "idol_sandbox_bw",
	config = { extra = { xmult = 1.5 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		local idol_card = G.GAME.current_round.idol_card or { rank = "Ace" }
		return {
			vars = {
				localize(idol_card.rank, "ranks"),
				card.ability.extra.xmult,
			},
		}
	end,
	calculate = function(self, card, context)
		if
			context.individual
			and context.cardarea == G.play
			and context.other_card:get_id() == G.GAME.current_round.idol_card.id
		then
			return {
				xmult = card.ability.extra.xmult,
			}
		end
	end,
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})

SMODS.Atlas({
	key = "idol_sandbox_color",
	path = "j_idol_sandbox_color.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "idol_sandbox_color",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	rarity = 2,
	cost = 6,
	atlas = "idol_sandbox_color",
	config = { extra = { xmult = 1.5, charge = 0.5 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		local idol_card = G.GAME.current_round.idol_card or { rank = "Ace", suit = "Spades" }
		return {
			vars = {
				localize(idol_card.rank, "ranks"),
				card.ability.extra.xmult,
				localize(idol_card.suit, "suits_plural"),

				colours = { G.C.SUITS[idol_card.suit] },
				card.ability.extra.charge,
			},
		}
	end,
	calculate = function(self, card, context)
		if
			context.individual
			and context.cardarea == G.play
			and context.other_card:get_id() == G.GAME.current_round.idol_card.id
			and context.other_card:is_suit(G.GAME.current_round.idol_card.suit)
		then
			-- todo apply and reset xmult
			return {
				xmult = card.ability.extra.xmult,
			}
			-- TODO reset to 1.5 and juice down
		end
		if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
			card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.charge
			return {
				message = localize("k_val_up"),
				colour = G.C.MULT,
			}
		end
		-- TODO if end of round juice up and increase xmult
	end,
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})

-- Fantom's idol
-- Gives 1x + (0.05x * card count) mult per card if you play
-- specifically your most common rank+suit
-- TODO test implementation
local function get_most_common_card()
	local count_map = {}
	local valid_idol_cards = {}

	if G.playing_cards == nil then return { id = 14, rank = "Ace", suit = "Spades", count = 4 } end

	for _, v in ipairs(G.playing_cards) do
		if v.ability.effect ~= "Stone Card" then
			local key = v.base.value .. "_" .. v.base.suit
			if not count_map[key] then
				count_map[key] = { count = 0, card = v }
				table.insert(valid_idol_cards, count_map[key])
			end
			count_map[key].count = count_map[key].count + 1
		end
	end

	if #valid_idol_cards == 0 then return { id = 14, rank = "Ace", suit = "Spades", count = 0 } end

	-- Sort by count descending first, then by suit/value for consistency
	local value_order = {}
	for i, rank in ipairs(SMODS.Rank.obj_buffer) do
		value_order[rank] = i
	end

	local suit_order = {}
	for i, suit in ipairs(SMODS.Suit.obj_buffer) do
		suit_order[suit] = i
	end

	table.sort(valid_idol_cards, function(a, b)
		if a.count ~= b.count then return a.count > b.count end
		local a_suit = a.card.base.suit
		local b_suit = b.card.base.suit
		if suit_order[a_suit] ~= suit_order[b_suit] then return suit_order[a_suit] < suit_order[b_suit] end
		local a_value = a.card.base.value
		local b_value = b.card.base.value
		return value_order[a_value] < value_order[b_value]
	end)

	-- Return the most common card
	local most_common = valid_idol_cards[1]
	return {
		id = most_common.card.base.id,
		rank = most_common.card.base.value,
		suit = most_common.card.base.suit,
		count = most_common.count,
	}
end

SMODS.Joker({
	key = "idol_sandbox_fantom",
	no_collection = MP.sandbox_no_collection,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	rarity = 2,
	cost = 6,
	atlas = "idol_sandbox_color", -- TODO create new sprite
	config = { extra = { xmult = 1.0, xmult_per_card = 0.05 }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		local most_common_card = get_most_common_card()
		local xmult = card.ability.extra.xmult + card.ability.extra.xmult_per_card * most_common_card.count
		return {
			vars = {
				localize(most_common_card.rank, "ranks"),
				localize(most_common_card.suit, "suits_plural"),
				xmult,
				card.ability.extra.xmult_per_card,
				colours = { G.C.SUITS[most_common_card.suit] },
			},
		}
	end,
	calculate = function(self, card, context)
		local most_common_card = get_most_common_card()
		if
			context.individual
			and context.cardarea == G.play
			and context.other_card:get_id() == most_common_card.id
			and context.other_card:is_suit(most_common_card.suit)
		then
			return {
				xmult = card.ability.extra.xmult + card.ability.extra.xmult_per_card * most_common_card.count,
			}
		end
	end,
	mp_include = function(self)
		return MP.SANDBOX.is_joker_allowed(self.key)
	end,
})
