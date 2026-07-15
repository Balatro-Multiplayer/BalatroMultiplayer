-- Credit to @MathIsFun_ for creating TheOrder, which this integration is a modified copy of
-- Patches card creation to not be ante-based and use a single pool for every type/rarity
local cc = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
	if MP.should_use_the_order() then
		local a = G.GAME.round_resets.ante
		G.GAME.round_resets.ante = 0
		G.GAME.round_resets.mp_real_ante = a
		if _type == "Tarot" or _type == "Planet" or _type == "Spectral" then
			if area == G.pack_cards then
				key_append = _type .. "_pack"
			else
				key_append = _type
			end
		elseif not (_type == "Base" or _type == "Enhanced") then
			if key_append == "jud" and G.GAME.modifiers.enable_eternals_in_shop then -- separate judgement rarity queue to avoid jank (and create a little)
				_rarity = pseudorandom("order_jud_rarity") -- dumb but should be fine
			end
			key_append = nil
		end
		local c = cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
		G.GAME.round_resets.ante = a
		G.GAME.round_resets.mp_real_ante = nil
		return c
	end
	return cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
end

-- Patches idol RNG when using the order to sort deck based on count of identical cards instead of default deck order
local original_reset_idol_card = reset_idol_card
function reset_idol_card()
	if MP.should_use_the_order() then

		G.GAME.current_round.idol_card.rank = "Ace"
		G.GAME.current_round.idol_card.suit = "Spades"

		-- ----------------------------------------------------------------
		-- Helper: enhancement / seal / edition weights
		-- NOTE: field names below assume base-Balatro conventions:
		--   card.ability.effect  -> "Wild Card" / "Glass Card" / "Lucky Card" / ...
		--   card.seal            -> "Red" / "Blue" / "Gold" / "Purple" / nil
		--   card.edition         -> { foil=true } / { holo=true } / { polychrome=true } / nil
		-- Adjust these three helpers if your mod stores these differently.
		-- ----------------------------------------------------------------
		local function is_wild(card)
			return card.ability and card.ability.effect == "Wild Card"
		end

		local function edition_weight(card)
			local e = card.edition
			if not e then return 0.0 end
			if e.polychrome then return 1.05 end
			if e.glass then return 0.95 end -- some mods track glass as an edition, not enhancement
			if e.holo then return 0.50 end
			if e.foil then return 0.15 end
			return 0.0
		end

		local function enhancement_weight(card)
			local eff = card.ability and card.ability.effect
			if eff == "Glass Card" then return 0.95 end
			if eff == "Lucky Card" then return 0.45 end
			if eff == "Steel Card" then return 0.15 end
			if eff == "Wild Card" then return 0.15 end
			if eff == "Bonus Card" then return 0.10 end
			if eff == "Mult Card" then return 0.10 end
			if eff == "Gold Card" then return 0.05 end
			return 0.0
		end

		local function seal_weight(card)
			local s = card.seal
			if s == "Red" then return 1.2 end
			if s == "Purple" then return 0.15 end
			if s == "Gold" then return 0.30 end
			if s == "Blue" then return 0.05 end
			return 0.0
		end

		-- ----------------------------------------------------------------
		-- Step 1: Build count_map keyed by (value, suit), tracking every
		-- physical card so we can later sum seal/edition/enhancement
		-- weights and detect wild cards.
		-- ----------------------------------------------------------------
		local count_map = {}
		local valid_idol_cards = {}

		for _, v in ipairs(G.playing_cards) do
			if v.ability.effect ~= "Stone Card" then
				local key = v.base.value .. "_" .. v.base.suit
				if not count_map[key] then
					count_map[key] = {
						count      = 0,
						card       = v,
						value      = v.base.value,
						suit       = v.base.suit,
						cards      = {},
						wild_count = 0,
					}
					table.insert(valid_idol_cards, count_map[key])
				end
				local entry = count_map[key]
				entry.count = entry.count + 1
				table.insert(entry.cards, v)
				if is_wild(v) then
					entry.wild_count = entry.wild_count + 1
				end
			end
		end

		if #valid_idol_cards == 0 then return end

		-- ----------------------------------------------------------------
		-- Step 2: Rank / suit ordering from SMODS (positional index)
		-- ----------------------------------------------------------------
		local rank_index = {}
		for i, rank_key in ipairs(SMODS.Rank.obj_buffer) do
			rank_index[rank_key] = i
		end

		local suit_index = {}
		for i, suit_key in ipairs(SMODS.Suit.obj_buffer) do
			suit_index[suit_key] = i
		end

		-- ----------------------------------------------------------------
		-- Step 3: Aggregate per-rank totals (physical only) + wild-by-rank
		-- ----------------------------------------------------------------
		local rank_totals = {}   -- rank_key -> total physical count across all suits
		local wild_by_rank = {}  -- rank_key -> total wild-enhanced count across all suits
		local distinct_ranks_set = {}

		for _, entry in ipairs(valid_idol_cards) do
			local r = entry.value
			rank_totals[r]  = (rank_totals[r] or 0) + entry.count
			wild_by_rank[r] = (wild_by_rank[r] or 0) + entry.wild_count
			distinct_ranks_set[r] = true
		end

		local distinct_ranks = 0
		for _ in pairs(distinct_ranks_set) do
			distinct_ranks = distinct_ranks + 1
		end

		local total_cards = 0
		for _, entry in ipairs(valid_idol_cards) do
			total_cards = total_cards + entry.count
		end

		local raw_mean_by_number = total_cards / distinct_ranks

		-- ----------------------------------------------------------------
		-- Step 4: Face / low pools + baselines (unchanged, mean-based,
		-- rank-restricted: only face ranks / nominal 2-5 ranks qualify)
		-- ----------------------------------------------------------------
		local face_pool = 0
		local low_pool  = 0
		local face_ranks_present = 0
		local low_ranks_present  = 0

		for rank_key, total in pairs(rank_totals) do
			local rank_obj = SMODS.Ranks[rank_key]
			if rank_obj then
				if rank_obj.face then
					face_pool = face_pool + total
					face_ranks_present = face_ranks_present + 1
				elseif rank_obj.nominal and rank_obj.nominal >= 2 and rank_obj.nominal <= 5 then
					low_pool = low_pool + total
					low_ranks_present = low_ranks_present + 1
				end
			end
		end

		local function round_to_nearest_05(x)
			return math.floor(x * 20 + 0.5) / 20
		end

		local face_baseline = round_to_nearest_05(raw_mean_by_number * face_ranks_present)
		local low_baseline  = round_to_nearest_05(raw_mean_by_number * low_ranks_present)

		local W_GEN = 0.05
		local GEN_FLOOR = 0.00

		local function face_score_for_rank(rank_key)
			local rank_obj = SMODS.Ranks[rank_key]
			if rank_obj and rank_obj.face then
				return math.max(GEN_FLOOR, W_GEN * 1.1 * math.max(0.0, face_pool - face_baseline))
			end
			return 0.0
		end

		local function low_score_for_rank(rank_key)
			local rank_obj = SMODS.Ranks[rank_key]
			if rank_obj and rank_obj.nominal and rank_obj.nominal >= 2 and rank_obj.nominal <= 5 then
				return math.max(GEN_FLOOR, W_GEN * math.max(0.0, low_pool - low_baseline))
			end
			return 0.0
		end

		-- ----------------------------------------------------------------
		-- Step 5: Previous rank (positional wrap: index 1 -> last index)
		-- ----------------------------------------------------------------
		local function previous_rank_key(rank_key)
			local idx = rank_index[rank_key]
			if not idx then return nil end
			if idx == 1 then
				return SMODS.Rank.obj_buffer[#SMODS.Rank.obj_buffer]
			else
				return SMODS.Rank.obj_buffer[idx - 1]
			end
		end

		-- ----------------------------------------------------------------
		-- Step 6: Tier weights / achievability weights
		-- ----------------------------------------------------------------
		local TARGET_COPIES = 5   -- how many exact copies we're trying to reach

		local W_EDITION_A = 1.3   -- Tier A: extra effect of enhanced cards (quality-dominant tier)
		local W_EDITION_B = 0.7   -- Tier B: cares less about this bonus and more about quantity
		local W_COUNT_A = 0.5     -- Tier A: reward per existing copy (quality-dominant tier)
		local W_MAIN    = 2.0     -- Tier B: reward per existing copy (progress toward 5)
		local W_OFF     = 1.0     -- Tier B: suit-changer potential, capped by need
		local W_STR     = 1.0    -- Tier B: Strength potential, capped by need

		-- ----------------------------------------------------------------
		-- Step 7: Compute total score for each distinct (rank, suit) entry
		-- ----------------------------------------------------------------
		for _, entry in ipairs(valid_idol_cards) do
			local rank_key = entry.value
			local suit_key = entry.suit
			local own_count = entry.count

			-- Effective count: physical copies + wild cards of same rank, other suits
			local wild_elsewhere = (wild_by_rank[rank_key] or 0) - entry.wild_count
			local effective_count = own_count + wild_elsewhere

			-- Quality terms (apply in both tiers)
			local face_score = face_score_for_rank(rank_key)
			local low_score  = low_score_for_rank(rank_key)
			local seal_score = 0.0
			local edition_score = 0.0
			for _, card in ipairs(entry.cards) do
				seal_score = seal_score + seal_weight(card)
				edition_score = edition_score + edition_weight(card) + enhancement_weight(card)
			end

			local main_hit, off_hit, strength_adj = 0.0, 0.0, 0.0
			local tier

			if effective_count >= TARGET_COPIES then
				-- ------------------------------------------------------
				-- TIER A: already at/above 5 — no operations required.
				-- Score by raw count + quality only; achievability terms
				-- (main/off/strength) don't apply, there's no gap to close.
				-- ------------------------------------------------------
				tier = 1
				entry.total_score = (W_COUNT_A * effective_count)
					+ face_score + low_score + ((seal_score + edition_score) * W_EDITION_A)
			else
				-- ------------------------------------------------------
				-- TIER B: below 5 — operations are required. Achievability
				-- terms are capped both by their mechanical limit AND by
				-- the actual gap remaining (closing more than the gap
				-- doesn't make the card any easier to complete).
				-- ------------------------------------------------------
				tier = 0
				local needed = TARGET_COPIES - effective_count

				-- Main Hit: direct reward for existing progress
				main_hit = W_MAIN * effective_count

				-- Off Hit: suit-changer potential (non-wild, off-suit, same rank)
				-- capped at 3 (suit-changer limit) and by remaining need
				local convertible_pool = (rank_totals[rank_key] or 0) - own_count - wild_elsewhere
				off_hit = W_OFF * math.min(3, math.max(0.0, convertible_pool), needed)

				-- Strength Adjacent: same-suit rank-1 neighbor (+ off-suit wild
				-- at rank-1), capped at 2 (Strength limit) and by remaining need
				local prev_rank = previous_rank_key(rank_key)
				local neighbor_count = 0
				if prev_rank then
					local neighbor_key = prev_rank .. "_" .. suit_key
					local neighbor_entry = count_map[neighbor_key]
					local physical_same_suit = neighbor_entry and neighbor_entry.count or 0
					local neighbor_wild_same_suit = neighbor_entry and neighbor_entry.wild_count or 0
					local prev_wild_total = wild_by_rank[prev_rank] or 0
					local prev_wild_elsewhere = prev_wild_total - neighbor_wild_same_suit
					neighbor_count = physical_same_suit + prev_wild_elsewhere
				end
				strength_adj = W_STR * math.min(2, neighbor_count, needed)

				entry.total_score = main_hit + off_hit + strength_adj
					+ face_score + low_score + ((seal_score + edition_score) * W_EDITION_B)
			end

			entry.tier = tier

		end

		-- ----------------------------------------------------------------
		-- Step 8: Sort — tier first (A above B), then score, then
		-- deterministic tiebreakers. Selection odds in Step 9 remain
		-- untouched: pure count / total_weight.
		-- ----------------------------------------------------------------
		table.sort(valid_idol_cards, function(a, b)
			if a.tier ~= b.tier then return a.tier > b.tier end
			if a.total_score ~= b.total_score then return a.total_score > b.total_score end
			if (rank_index[a.value] or 0) ~= (rank_index[b.value] or 0) then return (rank_index[a.value] or 0) > (rank_index[b.value] or 0) end
			if suit_index[a.suit] ~= suit_index[b.suit] then return suit_index[a.suit] > suit_index[b.suit] end
			return (rank_index[a.value] or 0) < (rank_index[b.value] or 0)
		end)

		local total_weight = 0
		for _, entry in ipairs(valid_idol_cards) do
			total_weight = total_weight + entry.count
		end

		if total_weight <= 0 then return end

		local raw_random = pseudorandom("idol" .. G.GAME.round_resets.ante)

		local threshold = 0
		for _, entry in ipairs(valid_idol_cards) do
			threshold = threshold + (entry.count / total_weight)
			if raw_random < threshold then
				local idol_card = entry.card
				sendDebugMessage(
					string.format(
						"Selected %s of %s, with a count of %d",
						idol_card.base.value, idol_card.base.suit, entry.count
					), "IdolAlgo"
				)
				G.GAME.current_round.idol_card.rank = idol_card.base.value
				G.GAME.current_round.idol_card.suit = idol_card.base.suit
				G.GAME.current_round.idol_card.id   = idol_card.base.id
				break
			end
		end
		return
	end

	return original_reset_idol_card()
end


local original_reset_mail_rank = reset_mail_rank

function reset_mail_rank()
	if MP.should_use_the_order() then
		G.GAME.current_round.mail_card.rank = "Ace"

		local count_map = {}
		local total_weight = 0
		local value_order = {}
		for i, rank in ipairs(SMODS.Rank.obj_buffer) do
			value_order[rank] = i
		end

		local valid_ranks = {}

		for _, v in ipairs(G.playing_cards) do
			if v.ability.effect ~= "Stone Card" then
				local val = v.base.value
				if not count_map[val] then
					count_map[val] = { count = 0, example_card = v }
					table.insert(valid_ranks, { value = val, count = 0, example_card = v })
				end
				count_map[val].count = count_map[val].count + 1
			end
		end

		-- Failsafe: all stone cards
		if #valid_ranks == 0 then return end

		-- Sort by count desc, then value asc
		table.sort(valid_ranks, function(a, b)
			if a.count ~= b.count then return a.count > b.count end
			return value_order[a.value] < value_order[b.value]
		end)

		total_weight = 0
		for _, entry in ipairs(valid_ranks) do
			total_weight = total_weight + count_map[entry.value].count
		end

		local raw_random = pseudorandom("mail" .. G.GAME.round_resets.ante)

		local threshold = 0
		for i, entry in ipairs(valid_ranks) do
			local count = count_map[entry.value].count
			local weight = (count / total_weight)
			threshold = threshold + weight
			if raw_random < threshold then
				--[[ nobody cares
				sendDebugMessage(
					"(Mail) Selected card "
						.. entry.example_card.base.value
						.. " with weight "
						.. count
						.. " of total "
						.. total_weight,
					"MULTIPLAYER"
				)
				]]
				G.GAME.current_round.mail_card.rank = entry.example_card.base.value
				G.GAME.current_round.mail_card.id = entry.example_card.base.id
				break
			end
		end

		return
	end

	return original_reset_mail_rank()
end

-- Take ownership of standard pack card creation
SMODS.Booster:take_ownership_by_kind("Standard", {
	create_card = function(self, card, i)
		local s_append = "" -- MP.get_booster_append(card)
		local b_append = MP.ante_based() .. s_append

		local _edition = poll_edition("standard_edition" .. b_append, 2, true)
		local _seal = SMODS.poll_seal({ mod = 10 })

		return {
			set = (pseudorandom(pseudoseed("stdset" .. b_append)) > 0.6) and "Enhanced" or "Base",
			edition = _edition,
			seal = _seal,
			area = G.pack_cards,
			skip_materialize = true,
			soulable = true,
			key_append = "sta" .. s_append,
			front = false,
		}
	end,
}, true)

-- Patch seal queues
local pollseal = SMODS.poll_seal
function SMODS.poll_seal(args)
	if MP.should_use_the_order() then
		local a = G.GAME.round_resets.ante
		G.GAME.round_resets.ante = 0
		G.GAME.round_resets.mp_real_ante = a
		local ret = pollseal(args)
		G.GAME.round_resets.ante = a
		G.GAME.round_resets.mp_real_ante = nil
		return ret
	end
	return pollseal(args)
end

-- Make voucher queue less chaotic
-- I don't like the fact that we have to do this twice

local function get_culled(_pool)
	local culled = {}
	for i = 1, #_pool, 2 do
		local first = _pool[i]
		local second = _pool[i + 1]

		if second == nil then
			-- idk if this ever triggers but just to be safe
			culled[#culled + 1] = (first ~= "UNAVAILABLE") and first or "UNAVAILABLE"
		elseif first ~= "UNAVAILABLE" and second ~= "UNAVAILABLE" then
			-- only true in the case of mods adding t3 vouchers
			culled[#culled + 1] = first
			culled[#culled + 1] = second
		elseif first ~= "UNAVAILABLE" then
			culled[#culled + 1] = first
		elseif second ~= "UNAVAILABLE" then
			culled[#culled + 1] = second
		else
			culled[#culled + 1] = "UNAVAILABLE"
		end
	end
	return culled
end

local nextvouchers = SMODS.get_next_vouchers
function SMODS.get_next_vouchers(vouchers)
	if MP.should_use_the_order() or MP.is_major_league_ruleset() then
		vouchers = vouchers or { spawn = {} }
		local _pool = get_current_pool("Voucher")
		local culled = get_culled(_pool)
		for i = #vouchers + 1, math.min(
			SMODS.size_of_pool(_pool),
			G.GAME.starting_params.vouchers_in_shop + (G.GAME.modifiers.extra_vouchers or 0)
		) do
			local center = pseudorandom_element(culled, pseudoseed("Voucher0"))
			local it = 1
			while center == "UNAVAILABLE" or vouchers.spawn[center] do
				it = it + 1
				center = pseudorandom_element(culled, pseudoseed("Voucher0"))
				if it > 1000 then -- fallback
					center = pseudorandom_element(culled, pseudoseed("Voucher0"..it))
				end
			end
			vouchers[#vouchers + 1] = center
			vouchers.spawn[center] = true
		end
		return vouchers
	end
	return nextvouchers(vouchers)
end

local nextvoucherkey = get_next_voucher_key
function get_next_voucher_key(_from_tag)
	if MP.should_use_the_order() or MP.is_major_league_ruleset() then
		local _pool = get_current_pool("Voucher")
		local culled = get_culled(_pool)
		local center = pseudorandom_element(culled, pseudoseed("Voucher0"))
		local it = 1
		while center == "UNAVAILABLE" do
			it = it + 1
			center = pseudorandom_element(culled, pseudoseed("Voucher0"))
			if it > 1000 then -- fallback
				center = pseudorandom_element(culled, pseudoseed("Voucher0"..it))
			end
		end
		return center
	end
	return nextvoucherkey(_from_tag)
end

-- Helper function to make code more readable - deal with ante
function MP.ante_based()
	if MP.should_use_the_order() then return 0 end
	return G.GAME.round_resets.ante
end

-- Handle round based rng with order (avoid desync with skips)
function MP.order_round_based(ante_based)
	if MP.should_use_the_order() then
		return G.GAME.round_resets.ante .. (G.GAME.blind.config.blind.key or "") .. (G.GAME.blind_on_deck or "")
	end
	if ante_based then return MP.ante_based() end
	return ""
end

-- Helper function for a sorted hand list to fix pairs() jank
function MP.sorted_hand_list(current_hand)
	if not current_hand then current_hand = "NULL" end
	local _poker_hands = {}
	local done = false
	local order = 1
	while not done do -- messy selection sort
		done = true
		for k, v in pairs(G.GAME.hands) do
			if v.order == order then
				order = order + 1
				done = false
				if v.visible and k ~= current_hand then _poker_hands[#_poker_hands + 1] = k end
			end
		end
	end
	return _poker_hands
end

local stdval = {
	centers = { -- these are roughly ordered in terms of current meta, doesn't matter toooo much? but they have to be ordered
		c_base = 0,
		m_stone = 106,
		m_bonus = 107,
		m_mult = 108,
		m_wild = 109,
		m_gold = 110,
		m_lucky = 111,
		m_steel = 112,
		m_glass = 113,
	},
	seals = {
		Gold = 122,
		Blue = 131,
		Purple = 140,
		Red = 149,
	},
	editions = {
		foil = 157,
		holo = 192,
		polychrome = 227,
	},
	-- no mod compat, but mods aren't too competitive, it won't matter much
}

local function give_stdval(card) -- give each card a value based on current enhancement/seal/edition
	card.mp_stdval = 0 + (stdval.centers[card.config.center_key] or 0)
	card.mp_stdval = card.mp_stdval + (stdval.seals[card.seal or "nil"] or 0)
	card.mp_stdval = card.mp_stdval + (stdval.editions[card.edition and card.edition.type or "nil"] or 0)
end

local function give_shufflevals(tbl, seed, joker)
	local tables = {}

	for k, v in pairs(tbl) do
		local key = nil
		if joker then
			key = v.config.center.key
		else
			give_stdval(v)
			key = v.config.center.key == "m_stone" and "Stone" or v.base.suit .. v.base.id
		end
		tables[key] = tables[key] or {}
		tables[key][#tables[key] + 1] = v
	end

	if seed and type(seed) == "string" then seed = pseudoseed(seed) end
	local true_seed = pseudorandom(seed)

	for k, v in pairs(tables) do
		if joker then
			table.sort(v, function(a, b)
				return a.sort_id < b.sort_id
			end) -- oldest joker (of specified key) first
		else
			table.sort(v, function(a, b)
				return a.mp_stdval > b.mp_stdval
			end) -- highest value (of specified suit+rank) first
		end
		local mega_seed = k .. true_seed
		for i, card in ipairs(v) do
			G._MP_UNSAVED_PRNG = true
			card.mp_shuffleval = pseudorandom(mega_seed)
			G._MP_UNSAVED_PRNG = false
		end
		G.GAME.pseudorandom[mega_seed] = nil -- just avoid flooding the table. we don't need to keep this
	end
end

-- Rework shuffle rng to be more similar between players
-- This also affects immolate and other uses of pseudoshuffle
local orig_pseudoshuffle = pseudoshuffle
function pseudoshuffle(list, seed)
	if MP.should_use_the_order() then
		local is_p_card = true
		for k, v in pairs(list) do
			if
				is_p_card
				and not (
					type(v) == "table"
					and v.ability
					and (v.ability.set == "Default" or v.ability.set == "Enhanced")
				)
			then
				is_p_card = false
			end
		end
		if is_p_card then
			give_shufflevals(list, seed or math.random())
			table.sort(list, function(a, b)
				return a.mp_shuffleval > b.mp_shuffleval
			end)
			return
		end
	end
	return orig_pseudoshuffle(list, seed)
end

-- Make pseudorandom_element selecting a joker/playing card less chaotic
local orig_pseudorandom_element = pseudorandom_element
function pseudorandom_element(_t, seed, args)
	if MP.should_use_the_order() then
		local is_joker = true
		local is_p_card = true
		for k, v in pairs(_t) do
			if is_joker and not (type(v) == "table" and v.ability and v.ability.set == "Joker") then
				is_joker = false
			end
			if
				is_p_card
				and not (
					type(v) == "table"
					and v.ability
					and (v.ability.set == "Default" or v.ability.set == "Enhanced")
				)
			then
				is_p_card = false
			end
		end
		if is_joker or is_p_card then
			local keys = {}
			for k, v in pairs(_t) do
				keys[#keys + 1] = { k = k, v = v }
			end
			give_shufflevals(_t, seed or math.random(), is_joker)
			table.sort(keys, function(a, b)
				return a.v.mp_shuffleval > b.v.mp_shuffleval
			end)

			local key = keys[1].k
			return _t[key], key
		end
	end
	return orig_pseudorandom_element(_t, seed, args)
end
