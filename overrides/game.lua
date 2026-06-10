local ease_dollars_ref = ease_dollars
function ease_dollars(mod, instant)
	sendTraceMessage(string.format("Client sent message: action:moneyMoved,amount:%s", tostring(mod)), "MULTIPLAYER")
	return ease_dollars_ref(mod, instant)
end

-- Certain Steamodded builds still call save_run while saving is disabled
-- In multiplayer runs this can crash when SMODS serializes transient hand data
local save_run_ref = save_run
function save_run(...)
	if G and G.F_NO_SAVING then return end
	return save_run_ref(...)
end

local sell_card_ref = Card.sell_card
function Card:sell_card()
	if self.ability and self.ability.name then
		-- record() emits both the carbon line and the human "Client sent message:"
		-- line. Sell is positional by area + slot, captured before the card leaves
		-- its area. Area distinguishes selling a joker (4) from a consumable (5).
		local human = string.format("action:soldCard,card:%s", self.ability.name)
		local area = MP.UTILS.area_enum(self.area)
		local idx = MP.UTILS.index_in_area(self)
		if area and idx then MP.RLOG.record("sell", { area, idx }, human) end
	end
	return sell_card_ref(self)
end

local reroll_shop_ref = G.FUNCS.reroll_shop
function G.FUNCS.reroll_shop(e)
	-- Reroll has no positional target; the shop contents it produces are
	-- deterministic from the seed, so the bare opcode is enough to replay.
	-- record() emits both the carbon line and the human "Client sent message:".
	MP.RLOG.record("reroll", nil, string.format("action:rerollShop,cost:%s", G.GAME.current_round.reroll_cost))

	-- Update reroll stats if in a multiplayer game
	if MP.LOBBY.code and MP.GAME.stats then
		MP.GAME.stats.reroll_count = MP.GAME.stats.reroll_count + 1
		MP.GAME.stats.reroll_cost_total = MP.GAME.stats.reroll_cost_total + G.GAME.current_round.reroll_cost
	end

	return reroll_shop_ref(e)
end

local buy_from_shop_ref = G.FUNCS.buy_from_shop
function G.FUNCS.buy_from_shop(e)
	local c1 = e.config.ref_table
	if c1 and c1:is(Card) then
		-- record() emits both the carbon line and the human "Client sent message:"
		-- line. Buy is positional by shop area + slot, captured before the card
		-- leaves the shop. Booster packs and vouchers get distinct opcodes since
		-- they branch the game differently, but all reference an area + slot.
		local human = string.format("action:boughtCardFromShop,card:%s,cost:%s", c1.ability.name, c1.cost)
		local area = MP.UTILS.area_enum(c1.area)
		local idx = MP.UTILS.index_in_area(c1)
		if area and idx then
			local opcode = "buy"
			local set = c1.ability and c1.ability.set
			if set == "Booster" then
				opcode = "open_pack"
			elseif set == "Voucher" then
				opcode = "voucher"
			end
			MP.RLOG.record(opcode, { area, idx }, human)
		end
	end
	return buy_from_shop_ref(e)
end

local use_card_ref = G.FUNCS.use_card
function G.FUNCS.use_card(e, mute, nosave)
	local card = e.config and e.config.ref_table
	if card and card.ability and card.ability.name then
		-- record() emits both the carbon line and the human "Client sent message:".
		local human = string.format("action:usedCard,card:%s", card.ability.name)
		-- Pack picks share this hook (a picked card lives in G.pack_cards) but get
		-- their own opcode. Both reference a slot plus any highlighted hand targets
		-- (e.g. a Tarot from an Arcana pack applied to selected cards).
		if card.area == (G and G.pack_cards) then
			local idx = MP.UTILS.index_in_area(card, G.pack_cards)
			if idx then
				local targets = MP.UTILS.highlighted_hand_indices()
				MP.RLOG.record("pack_pick", (#targets > 0) and { idx, targets } or { idx }, human)
			end
		else
			local idx = MP.UTILS.index_in_area(card)
			if idx then
				local targets = MP.UTILS.highlighted_hand_indices()
				MP.RLOG.record("use", (#targets > 0) and { idx, targets } or { idx }, human)
			end
		end
	end
	return use_card_ref(e, mute, nosave)
end

-- Hook for end of pvp context (slightly scuffed)
local evaluate_round_ref = G.FUNCS.evaluate_round
G.FUNCS.evaluate_round = function()
	if G.after_pvp then
		G.after_pvp = nil
		SMODS.calculate_context({ mp_end_of_pvp = true })
	end
	evaluate_round_ref()
end

-- Carbon: skipping a booster pack.
if G.FUNCS.skip_booster then
	local skip_booster_ref = G.FUNCS.skip_booster
	function G.FUNCS.skip_booster(e)
		MP.RLOG.record("pack_skip", 0, "action:skipPack")
		return skip_booster_ref(e)
	end
end

-- Carbon: joker / hand reordering (drag-drop). There is no discrete base-game
-- callback for a reorder, so we diff each area's card order on update. This is
-- intentionally independent of the Preview integration (which has its own,
-- Preview-gated order tracker) so reorders are always logged. Detection is
-- debounced until no card in the area is mid-drag, so one drag emits one event,
-- and reorder_permutation only fires on a pure permutation (the card set is
-- unchanged) -- draws, plays and discards change the set and are ignored here.
local function rlog_reorder_area(cardarea)
	if cardarea == G.jokers then return MP.UTILS.AREA.jokers end
	if cardarea == G.hand then return MP.UTILS.AREA.hand end
	return nil
end

local function rlog_area_dragging(cardarea)
	for _, c in ipairs(cardarea.cards) do
		if c.states and c.states.drag and c.states.drag.is then return true end
	end
	return false
end

local cardarea_update_ref = CardArea.update
function CardArea:update(dt)
	cardarea_update_ref(self, dt)

	-- Cheap area check first (runs for every CardArea every frame); only the
	-- joker/hand areas do any further work, and only during a live MP game.
	local area_id = rlog_reorder_area(self)
	if not area_id or not self.cards or #self.cards == 0 then return end
	if not (MP.RLOG and MP.RLOG.is_active()) then return end
	if rlog_area_dragging(self) then return end -- wait for the drag to settle

	local cur = {}
	for i = 1, #self.cards do
		cur[i] = self.cards[i].sort_id
	end
	local prev = self._rlog_order
	self._rlog_order = cur

	if prev and #prev == #cur then
		local perm = MP.UTILS.reorder_permutation(prev, self.cards)
		if perm then
			MP.RLOG.record("reorder", { area_id, perm }, "action:reorder,area:" .. area_id)
		end
	end
end
