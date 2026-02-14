-- Pre-compile a reversed list of all the centers
local reversed_centers = nil

function MP.UTILS.card_to_string(card)
	if not card or not card.base or not card.base.suit or not card.base.value then return "" end

	if not reversed_centers then reversed_centers = MP.UTILS.reverse_key_value_pairs(G.P_CENTERS) end

	local suit = string.sub(card.base.suit, 1, 1)

	local rank_value_map = {
		["10"] = "T",
		Jack = "J",
		Queen = "Q",
		King = "K",
		Ace = "A",
	}
	local rank = rank_value_map[card.base.value] or card.base.value

	local enhancement = reversed_centers[card.config.center] or "none"
	local edition = card.edition and MP.UTILS.reverse_key_value_pairs(card.edition, true)["true"] or "none"
	local seal = card.seal or "none"

	local card_str = suit .. "-" .. rank .. "-" .. enhancement .. "-" .. edition .. "-" .. seal

	return card_str
end

function MP.UTILS.joker_to_string(card)
	if not card or not card.config or not card.config.center or not card.config.center.key then return "" end

	local edition = card.edition and MP.UTILS.reverse_key_value_pairs(card.edition, true)["true"] or "none"
	local eternal_or_perishable = "none"
	if card.ability then
		if card.ability.eternal then
			eternal_or_perishable = "eternal"
		elseif card.ability.perishable then
			eternal_or_perishable = "perishable"
		end
	end
	local rental = (card.ability and card.ability.rental) and "rental" or "none"

	local joker_string = card.config.center.key .. "-" .. edition .. "-" .. eternal_or_perishable .. "-" .. rental

	return joker_string
end

-- ??? seems to be dead code
function MP.UTILS.get_joker(key)
	if not G.jokers or not G.jokers.cards then return nil end
	for i = 1, #G.jokers.cards do
		if G.jokers.cards[i].ability.name == key then return G.jokers.cards[i] end
	end
	return nil
end

function MP.UTILS.get_phantom_joker(key)
	if not MP.shared or not MP.shared.cards then return nil end
	for i = 1, #MP.shared.cards do
		if
			MP.shared.cards[i].ability.name == key
			and MP.shared.cards[i].edition
			and MP.shared.cards[i].edition.type == "mp_phantom"
		then
			return MP.shared.cards[i]
		end
	end
	return nil
end

-- ??? seems to be dead code
function MP.UTILS.run_for_each_joker(key, func)
	if not G.jokers or not G.jokers.cards then return end
	for i = 1, #G.jokers.cards do
		if G.jokers.cards[i].ability.name == key then func(G.jokers.cards[i]) end
	end
end

-- ??? seems to be dead code
function MP.UTILS.run_for_each_phantom_joker(key, func)
	if not MP.shared or not MP.shared.cards then return end
	for i = 1, #MP.shared.cards do
		if MP.shared.cards[i].ability.name == key then func(MP.shared.cards[i]) end
	end
end

function MP.UTILS.get_deck_key_from_name(_name)
	for k, v in pairs(G.P_CENTERS) do
		if v.name == _name then return k end
	end
end

function MP.UTILS.get_culled_pool(_type, _rarity, _legendary, _append)
	local pool = get_current_pool(_type, _rarity, _legendary, _append)
	local ret = {}
	for i, v in ipairs(pool) do
		if v ~= "UNAVAILABLE" then ret[#ret + 1] = v end
	end
	return ret
end
