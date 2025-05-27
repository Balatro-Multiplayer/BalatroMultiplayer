-- Credit to @MathIsFun_ for creating TheOrder, which this integration is a modified copy of
-- Patches card creation to not be ante-based and use a single pool for every type/rarity
local cc = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    if MP.INTEGRATIONS.TheOrder then
        local a = G.GAME.round_resets.ante
        G.GAME.round_resets.ante = 0
        if _type == "Tarot" or _type == "Planet" or _type == "Spectral" then
            key_append = _type
        end
        local c = cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, _rarity)	-- _rarity replacing key_append can be entirely removed to normalise skip tags and riff raff with shop rarity queues
        G.GAME.round_resets.ante = a
        return c
    end
    return cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
end

-- Patches idol RNG when using the order to sort deck based on count of identical cards instead of default deck order
local original_reset_idol_card = reset_idol_card
function reset_idol_card()
	if MP.INTEGRATIONS.TheOrder then
		G.GAME.current_round.idol_card.rank = 'Ace'
		G.GAME.current_round.idol_card.suit = 'Spades'

		local count_map = {}
		local valid_idol_cards = {}

		for _, v in ipairs(G.playing_cards) do
			if v.ability.effect ~= 'Stone Card' then
				local key = v.base.value .. '_' .. v.base.suit
				if not count_map[key] then
					count_map[key] = { count = 0, card = v }
					table.insert(valid_idol_cards, count_map[key])
				end
				count_map[key].count = count_map[key].count + 1
			end
		end
        --failsafe in case all are stone or no cards in deck. Defaults to Ace of Spades
		if #valid_idol_cards == 0 then
			return
		end

		local value_order = {
			["Ace"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5,
			["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["10"] = 10,
			["Jack"] = 11, ["Queen"] = 12, ["King"] = 13
		}

		local suit_order = {
			Spades = 1,
			Hearts = 2,
			Clubs = 3,
			Diamonds = 4
		}

		table.sort(valid_idol_cards, function(a, b)
			-- Sort by count descending first
			if a.count ~= b.count then
				return a.count > b.count
			end

			local a_suit = a.card.base.suit
			local b_suit = b.card.base.suit
			if suit_order[a_suit] ~= suit_order[b_suit] then
				return suit_order[a_suit] < suit_order[b_suit]
			end

			local a_value = a.card.base.value
			local b_value = b.card.base.value
			return value_order[a_value] < value_order[b_value]
		end)

		-- Weighted random selection based on count
		local total_weight = 0
		for _, entry in ipairs(valid_idol_cards) do
			total_weight = total_weight + entry.count
		end

		local raw_random = pseudorandom('idol'..G.GAME.round_resets.ante)
		local rand = raw_random * 1000

		local threshold = 0
		for _, entry in ipairs(valid_idol_cards) do
			threshold = threshold + (entry.count / total_weight) * 1000
			if rand <= threshold then
				local idol_card = entry.card
				G.GAME.current_round.idol_card.rank = idol_card.base.value
				G.GAME.current_round.idol_card.suit = idol_card.base.suit
				G.GAME.current_round.idol_card.id = idol_card.base.id
				break
			end
		end
		return
	end

	return original_reset_idol_card()
end


local original_reset_mail_rank = reset_mail_rank

function reset_mail_rank()
	if MP.INTEGRATIONS.TheOrder then
		G.GAME.current_round.mail_card.rank = 'Ace'

		local count_map = {}
		local total_weight = 0
		local value_order = {
			["Ace"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5,
			["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["10"] = 10,
			["Jack"] = 11, ["Queen"] = 12, ["King"] = 13
		}

		local valid_ranks = {}

		for _, v in ipairs(G.playing_cards) do
			if v.ability.effect ~= 'Stone Card' then
				local val = v.base.value
				if not count_map[val] then
					count_map[val] = { count = 0, example_card = v }
					table.insert(valid_ranks, { value = val, count = 0, example_card = v })
				end
				count_map[val].count = count_map[val].count + 1
			end
		end

		-- Failsafe: all stone cards
		if #valid_ranks == 0 then 
			return 
		end

		-- Sort by count desc, then value asc
		table.sort(valid_ranks, function(a, b)
			if a.count ~= b.count then
				return a.count > b.count
			end
			return value_order[a.value] < value_order[b.value]
		end)

		total_weight = 0
		for _, entry in ipairs(valid_ranks) do
			total_weight = total_weight + count_map[entry.value].count
		end

		local raw_random = pseudorandom('mail'..G.GAME.round_resets.ante)
		local rand = raw_random * 1000

		local threshold = 0
		for i, entry in ipairs(valid_ranks) do
			local count = count_map[entry.value].count
			local weight = (count / total_weight) * 1000
			threshold = threshold + weight
			if rand <= threshold then
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
-- This is irritating
SMODS.Booster:take_ownership_by_kind('Standard', {
	create_card = function(self, card, i)
		local s_append = ''	-- MP.get_booster_append(card)
		local b_append = MP.ante_based()..s_append
		
		local _edition = poll_edition('standard_edition'..b_append, 2, true)
		local _seal = SMODS.poll_seal({mod = 10, key = 'stdseal'..b_append})
		
		return {set = (pseudorandom(pseudoseed('stdset'..b_append)) > 0.6) and "Enhanced" or "Base", edition = _edition, seal = _seal, area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "sta"..s_append}
	end,
}, true)
-- Patch seal queues
local pollseal = SMODS.poll_seal
function SMODS.poll_seal(args)
	if MP.INTEGRATIONS.TheOrder then
		local a = G.GAME.round_resets.ante
		G.GAME.round_resets.ante = 0
		local ret = pollseal(args)
		G.GAME.round_resets.ante = a
		return ret
	end
	return pollseal(args)
end

-- Helper function to make code more readable - deal with ante
function MP.ante_based()
	if MP.INTEGRATIONS.TheOrder then
		return 0
	end
	return G.GAME.round_resets.ante
end

-- Handle round based rng with order (avoid desync with skips)
function MP.order_round_based(ante_based)
	if MP.INTEGRATIONS.TheOrder then
		return G.GAME.round_resets.ante..(G.GAME.blind.config.blind.key or '')	-- fine becase no boss shenanigans... change this if that happens
	end
	if ante_based then
		return MP.ante_based()
	end
	return ''
end

-- Rework shuffle rng to be more similar between players
local orig_shuffle = CardArea.shuffle
function CardArea:shuffle(_seed)
	if MP.INTEGRATIONS.TheOrder and self == G.deck then
		local centers = {	-- these are roughly ordered in terms of current meta, doesn't matter toooo much? but they have to be ordered
			c_base = 0,
			m_stone = 50,
			m_bonus = 51,
			m_mult = 52,
			m_wild = 53,
			m_gold = 54,
			m_lucky = 55,
			m_steel = 56,
			m_glass = 57,
		}
		local seals = {
			Gold = 75,
			Blue = 76,
			Purple = 77,
			Red = 78,
		}
		local editions = {
			foil = 100,
			holo = 101,
			polychrome = 102,
		}
		-- no mod compat, but mods aren't too competitive, it won't matter much
		
		local tables = {}
		
		for i, v in ipairs(self.cards) do	-- give each card a value based on current enhancement/seal/edition
			v.mp_stdval = 0 + (centers[v.config.center_key] or 0)
			v.mp_stdval = v.mp_stdval + (seals[v.seal or 'nil'] or 0)
			v.mp_stdval = v.mp_stdval + (editions[v.edition and v.edition.type or 'nil'] or 0)
			local key = v.config.center_key == 'm_stone' and 'Stone' or v.base.suit..v.base.id
			tables[key] = tables[key] or {}
			tables[key][#tables[key]+1] = v
		end
		
		local true_seed = pseudorandom(_seed or 'shuffle')
		
		for k, v in pairs(tables) do
			table.sort(v, function (a, b) return a.mp_stdval > b.mp_stdval end)
			local mega_seed = k..true_seed
			for i, card in ipairs(v) do
				card.mp_shuffleval = pseudorandom(mega_seed)
			end
		end
		table.sort(self.cards, function (a, b) return a.mp_shuffleval > b.mp_shuffleval end)
		self:set_ranks()
	else
		return orig_shuffle(self, _seed)
	end
end
