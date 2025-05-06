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

-- Rest of the packs since we're dealing with pack queues now
SMODS.Booster:take_ownership_by_kind('Arcana', {
	create_card = function(self, card, i)
		local s_append = ''	-- MP.get_booster_append(card)
		
		local _card
		if G.GAME.used_vouchers.v_omen_globe and pseudorandom('omen_globe') > 0.8 then
			_card = {set = "Spectral", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "ar2"..s_append}
		else
			_card = {set = "Tarot", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "ar1"..s_append}
		end
		return _card
	end,
}, true)
SMODS.Booster:take_ownership_by_kind('Celestial', {
	create_card = function(self, card, i)
		local s_append = ''	-- MP.get_booster_append(card)
		
		local _card
		if G.GAME.used_vouchers.v_telescope and i == 1 then
			local _planet, _hand, _tally = nil, nil, 0
			for k, v in ipairs(G.handlist) do
				if G.GAME.hands[v].visible and G.GAME.hands[v].played > _tally then
					_hand = v
					_tally = G.GAME.hands[v].played
				end
			end
			if _hand then
				for k, v in pairs(G.P_CENTER_POOLS.Planet) do
					if v.config.hand_type == _hand then
						_planet = v.key
					end
				end
			end
			_card = {set = "Planet", area = G.pack_cards, skip_materialize = true, soulable = true, key = _planet, key_append = "pl1"..s_append}
		else
			_card = {set = "Planet", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "pl1"..s_append}
		end
		return _card
	end,
}, true)
SMODS.Booster:take_ownership_by_kind('Spectral', {
	create_card = function(self, card, i)
		local s_append = ''	-- MP.get_booster_append(card)
		return {set = "Spectral", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "spe"..s_append}
	end,
}, true)
SMODS.Booster:take_ownership_by_kind('Buffoon', {
	create_card = function(self, card, i)
		local s_append = MP.get_booster_append(card)
		return {set = "Joker", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "buf"..s_append}
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

-- Helper function to make code more readable - deal with packs
-- Note that soul queue is based on type and not packs, so you probably won't miss out on soul if you avoid early mega arcanas or something
-- ^^^ above statement is unnecessary for now since functionality is only active for buffoon packs ^^^
function MP.get_booster_append(booster)
	if MP.INTEGRATIONS.TheOrder and false then
		if booster.ability.extra > 3.5 then	-- midpoint, i don't feel like string matching and this handles vanilla cases
			if (booster.config.center.config.choose or 1) > 1.5 then
				return 'mega'	-- if we want jumbos to have same queue as megas, change this or 'jumb' to be the same
			else
				return 'jumb'
			end
		end
		return 'norm'
	end
	return ''
end
