MP.PVP_SELL = MP.PVP_SELL or { handlers = {} }

function MP.PVP_SELL.is_active()
	return G and G.STAGE == G.STAGES.RUN and MP.is_pvp_boss()
end

function MP.PVP_SELL.register(center_key, handler)
	MP.PVP_SELL.handlers[center_key] = handler
end

local function sold_phantom_queue()
	MP.GAME = MP.GAME or {}
	MP.GAME.pvp_sold_phantom_keys = MP.GAME.pvp_sold_phantom_keys or {}
	return MP.GAME.pvp_sold_phantom_keys
end

function MP.PVP_SELL.show_sold_phantom(center_key)
	if not center_key or not (MP.LOBBY and MP.LOBBY.code) then return end
	if not (MP.ACTIONS and MP.ACTIONS.send_phantom) then return end
	table.insert(sold_phantom_queue(), center_key)
	MP.ACTIONS.send_phantom(center_key)
end

function MP.PVP_SELL.clear_sold_phantoms()
	local queue = sold_phantom_queue()
	if #queue < 1 then return end
	if MP.LOBBY and MP.LOBBY.code and MP.ACTIONS and MP.ACTIONS.remove_phantom then
		for _, center_key in ipairs(queue) do
			MP.ACTIONS.remove_phantom(center_key)
		end
	end
	MP.GAME.pvp_sold_phantom_keys = {}
end

function MP.PVP_SELL.empty_joker_slots_after_sale(card)
	if not (G and G.jokers and G.jokers.config and G.jokers.cards) then return 0 end
	local joker_count = #G.jokers.cards
	if card and card.area == G.jokers then joker_count = math.max(0, joker_count - 1) end
	return math.max((G.jokers.config.card_limit or 0) - joker_count, 0)
end

function MP.PVP_SELL.random_hand_cards(count, seed)
	local picked = {}
	if not (G and G.hand and G.hand.cards and #G.hand.cards > 0) then return picked end
	local candidates = {}
	for _, hand_card in ipairs(G.hand.cards) do candidates[#candidates + 1] = hand_card end
	pseudoshuffle(candidates, pseudoseed(seed or "mp_pvp_sell_hand"))
	for i = 1, math.min(count or 0, #candidates) do picked[#picked + 1] = candidates[i] end
	return picked
end

function MP.PVP_SELL.add_tag_with_sfx(tag_key)
	add_tag(Tag(tag_key))
	play_sound("generic1", 0.9 + math.random() * 0.1, 0.8)
	play_sound("holo1", 1.2 + math.random() * 0.1, 0.4)
end

function MP.PVP_SELL.apply_rental(card)
	if not card or card.REMOVED then return false end
	card.ability = card.ability or {}
	if card.ability.rental then return false end
	if card.set_rental then
		card:set_rental(true)
	else
		card.ability.rental = true
		if card.set_cost then card:set_cost() end
	end
	card:juice_up(0.4, 0.5)
	return true
end

function MP.PVP_SELL.clear_editions_and_stickers(card)
	if not card or card.REMOVED then return false end
	local changed = false

	if card.edition then
		if card.edition.type == "mp_phantom" and remove_phantom then remove_phantom(card) end
		card:set_edition(nil, true, true)
		changed = true
	end

	card.ability = card.ability or {}
	if card.ability.eternal then
		if card.set_eternal then card:set_eternal(false) else card.ability.eternal = false end
		changed = true
	end
	if card.ability.perishable or card.ability.perish_tally ~= nil
		or card.ability.perishable_tally ~= nil or card.ability.perishable_rounds ~= nil then
		-- Steamodded's Perishable sticker keeps its countdown in perish_tally.
		-- Clear through the registered sticker first, then force-reset every
		-- vanilla field so the badge/effect cannot survive on either client.
		local perishable_sticker = SMODS.Stickers and SMODS.Stickers.perishable
		if perishable_sticker and perishable_sticker.apply then
			perishable_sticker:apply(card, false)
		end
		if card.set_perishable then card:set_perishable(false) end
		card.ability.perishable = nil
		card.ability.perish_tally = nil
		card.ability.perishable_tally = nil
		card.ability.perishable_rounds = nil
		changed = true
	end
	if card.ability.rental then
		if card.set_rental then card:set_rental(false) else card.ability.rental = false end
		changed = true
	end

	for _, key in ipairs({
		"mp_sticker_balanced",
		"mp_sticker_extra_credit",
		"mp_sticker_persistent",
		"mp_sticker_unreliable",
		"mp_sticker_draining",
		"mp_sticker_nemesis",
	}) do
		if card.ability[key] then
			local sticker = SMODS.Stickers and SMODS.Stickers[key]
			if sticker and sticker.apply then sticker:apply(card, false) else card.ability[key] = false end
			changed = true
		end
	end

	if changed then
		if card.set_cost then card:set_cost() end
		card:juice_up(0.25, 0.25)
	end
	return changed
end

function MP.PVP_SELL.clear_area(area, excluded_card)
	local changed = 0
	if area and area.cards then
		for _, joker in ipairs(area.cards) do
			if joker ~= excluded_card and MP.PVP_SELL.clear_editions_and_stickers(joker) then changed = changed + 1 end
		end
	end
	return changed
end

function MP.PVP_SELL.clear_nemesis_display_stickers()
	local changed = 0
	if not (MP.shared and MP.shared.cards) then return changed end
	for _, joker in ipairs(MP.shared.cards) do
		if joker and joker.ability then
			if joker.ability.rental then
				if joker.set_rental then joker:set_rental(false) else joker.ability.rental = false end
				changed = changed + 1
			end
			-- Keep the Phantom edition/Nemesis marker: those identify the opponent's
			-- display copy and are not actual modifiers on their owned Joker.
		end
	end
	return changed
end

local function apply_jester_rental_to_area(area, requested_index)
	if not (area and area.cards and #area.cards > 0) then return false end
	local target = requested_index and area.cards[requested_index] or nil
	if target and not (target.ability and target.ability.rental) then return MP.PVP_SELL.apply_rental(target) end
	local candidates = {}
	for _, joker in ipairs(area.cards) do
		if joker and not joker.REMOVED and not (joker.ability and joker.ability.rental) then candidates[#candidates + 1] = joker end
	end
	if #candidates < 1 then return false end
	return MP.PVP_SELL.apply_rental(pseudorandom_element(candidates, pseudoseed("j_mp_jester_in_yellow_receive")))
end

MP.register_mod_action("pvp_jester_rental", function(payload)
	apply_jester_rental_to_area(G.jokers, tonumber(payload and payload.index))
end)

MP.register_mod_action("pvp_dynamic_duo", function()
	MP.PVP_SELL.clear_area(G.jokers)
end)

function MP.PVP_SELL.send_to_nemesis(action, params)
	if MP.LOBBY and MP.LOBBY.code and MP.ACTIONS and MP.ACTIONS.modded then
		MP.ACTIONS.modded(MP.id or "Multiplayer", action, params)
	end
end

local sell_card_ref = Card.sell_card
function Card:sell_card(...)
	local center_key = self.config and self.config.center and self.config.center.key
	local handler = center_key and MP.PVP_SELL.handlers[center_key]
	if handler and not self.mp_pvp_sell_triggered and MP.PVP_SELL.is_active() then
		self.mp_pvp_sell_triggered = true
		-- These six Jokers remain visible to the opponent as Phantom copies for
		-- the rest of this PvP Blind, even though the original card was sold.
		MP.PVP_SELL.show_sold_phantom(center_key)
		local ok, err = pcall(handler, self)
		if not ok then
			sendErrorMessage("PvP sell Joker failed (" .. tostring(center_key) .. "): " .. tostring(err), "MULTIPLAYER")
		end
	end
	return sell_card_ref(self, ...)
end

-- Cash Out is the lifetime boundary for sold PvP Joker Phantoms. Sending one
-- removal per queued sale also handles multiple copies of the same Joker.
local cash_out_ref = G.FUNCS.cash_out
function G.FUNCS.cash_out(...)
	MP.PVP_SELL.clear_sold_phantoms()
	return cash_out_ref(...)
end
