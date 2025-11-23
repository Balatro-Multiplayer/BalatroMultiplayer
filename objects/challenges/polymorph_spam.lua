SMODS.Challenge({
	key = "polymorph_spam",
	rules = {
		custom = {
			{ id = "mp_polymorph_spam" },
			{ id = "mp_polymorph_spam_EXTENDED1" },
			{ id = "mp_polymorph_spam_EXTENDED2" },
		},
	},
	restrictions = {
		banned_cards = function()
			local ret = {}
			local add = {
				j_campfire = true,
				j_invisible = true,
				j_caino = true,
				j_yorick = true,
			}
			for i, v in ipairs(G.P_CENTER_POOLS.Joker) do
				if (not v.perishable_compat) or add[v.key] then ret[#ret + 1] = { id = v.key } end
			end
			return ret
		end,
	},
	unlocked = function(self)
		return true
	end,
})

local function get_area(card)
	if not card then return end
	if card.config.center.set == "Joker" then
		return G.jokers
	elseif card.config.center.consumeable then
		return G.consumeables
	end
	return nil
end

local function get_pos(card)
	local area = get_area(card)
	for i, v in ipairs(area.cards) do
		if card == v then return i end
	end
	return nil
end

local function included(key)
	if G.GAME.banned_keys[key] then
		return false
	elseif G.P_CENTERS[key].mp_include and type(G.P_CENTERS[key].mp_include) == "function" then
		return G.P_CENTERS[key].mp_include()
	end
	return true
end

-- i should have separated this into 2 functions but this works i suppose
local function get_transmutations_loc(card)
	local done = false
	local num = 0
	local area = get_area(card)
	local limit = area.config.card_limit
	local pos = get_pos(card) or nil
	local ret = {}
	while not done do
		for i, v in ipairs(G.P_CENTER_POOLS[card.config.center.set]) do
			if included(v.key) then
				if num > 0 then
					ret[#ret + 1] = {
						strings = {
							localize({ type = "name_text", key = v.key, set = v.set }),
						},
						control = {
							C = (num - 1) == (limit - (pos or -1)) and "attention" or nil,
						},
					}
					if num == 1 then
						done = true
						break
					end
				end
				if v == card.config.center then
					num = limit
				else
					num = math.max(num - 1, 0)
				end
			end
		end
	end
	return ret
end

local function mass_polymorph(area)
	for _, card in ipairs(area) do
		local done = false
		local swap = 0
		while not done do
			for i, v in ipairs(G.P_CENTER_POOLS[card.config.center.set]) do
				if included(v.key) then
					if swap == 1 then
						card:set_ability(v)
						card:set_cost()
						done = true
						break
					end
					if v == card.config.center then
						swap = get_pos(card)
					else
						swap = math.max(swap - 1, 0)
					end
				end
			end
		end
	end
end

local calculate_context_ref = SMODS.calculate_context
function SMODS.calculate_context(context, return_table, no_resolve)
	if G.GAME.modifiers.mp_polymorph_spam and context and type(context) == "table" and context.setting_blind then
		mass_polymorph(G.jokers.cards)
		mass_polymorph(G.consumeables.cards)
	end
	return calculate_context_ref(context, return_table, no_resolve)
end

local set_ability_ref = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
	local ret = set_ability_ref(self, center, initial, delay_sprites)
	if G.GAME.modifiers.mp_polymorph_spam and G.OVERLAY_MENU then
		if not included(center.key) then self.ability.perma_debuff = true end
	end
	return ret
end

local transmute_card = nil -- global local :thinking:

local generate_card_ui_ref = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end, card)
	local ret =
		generate_card_ui_ref(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end, card)
	if G.GAME.modifiers.mp_polymorph_spam then
		if card and card.config.center then -- check for card and for tag
			if get_area(card) and included(card.config.center.key) then
				transmute_card = card -- whatever, surely won't break
				generate_card_ui_ref({ key = "mp_transmutations", set = "Other" }, ret) -- don't need to assign this to ret because lua
			end
		end
	end
	return ret
end

-- really inefficient and throws away a metric shit ton of tables
-- thanks to the advancements of my ancestors, i don't have to worry about it
local localize_ref = localize
function localize(args, misc_cat)
	if args.key == "mp_transmutations" then
		local loc_target = G.localization.descriptions.Other.mp_transmutations.text_parsed
		for i = 2, #loc_target do
			table.remove(loc_target, 2)
		end
		local list = get_transmutations_loc(transmute_card)
		for i = 1, #list do
			loc_target[#loc_target + 1] = { list[i] }
		end
	end
	return localize_ref(args, misc_cat)
end
