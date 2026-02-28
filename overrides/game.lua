local ease_dollars_ref = ease_dollars
function ease_dollars(mod, instant)
	sendTraceMessage(string.format("Client sent message: action:moneyMoved,amount:%s", tostring(mod)), "MULTIPLAYER")
	return ease_dollars_ref(mod, instant)
end

local sell_card_ref = Card.sell_card
function Card:sell_card()
	if self.ability and self.ability.name then
		sendTraceMessage(
			string.format("Client sent message: action:soldCard,card:%s", self.ability.name),
			"MULTIPLAYER"
		)
		-- Track joker removals for telemetry
		if self.config and self.config.center and self.config.center.set == "Joker" then
			local key = self.config.center.key
			MP.STATS.on_joker_removed(key, "sold")
		end
	end
	return sell_card_ref(self)
end

local reroll_shop_ref = G.FUNCS.reroll_shop
function G.FUNCS.reroll_shop(e)
	sendTraceMessage(
		string.format("Client sent message: action:rerollShop,cost:%s", G.GAME.current_round.reroll_cost),
		"MULTIPLAYER"
	)

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
		sendTraceMessage(
			string.format("Client sent message: action:boughtCardFromShop,card:%s,cost:%s", c1.ability.name, c1.cost),
			"MULTIPLAYER"
		)
		-- Track joker acquisitions for telemetry
		if c1.config and c1.config.center and c1.config.center.set == "Joker" then
			local key = c1.config.center.key
			local edition = (c1.edition and c1.edition.type) or "none"
			local seal = c1.seal or "none"
			MP.STATS.on_joker_acquired(key, edition, seal, c1.cost, "shop")
		end
	end
	return buy_from_shop_ref(e)
end

-- Track joker acquisitions from non-shop sources (boosters, tags, etc.)
local add_to_deck_ref = Card.add_to_deck
function Card:add_to_deck(from_debuff)
	if self.config and self.config.center and self.config.center.set == "Joker" then
		if not (self.edition and self.edition.type == "mp_phantom") then
			local key = self.config.center.key
			-- Check if this joker was already tracked via shop purchase
			local already_tracked = false
			for i = #MP.STATS.joker_lifecycle, 1, -1 do
				local entry = MP.STATS.joker_lifecycle[i]
				if entry.key == key and entry.ante_removed == nil and entry.source == "shop" then
					already_tracked = true
					break
				end
			end
			if not already_tracked then
				local edition = (self.edition and self.edition.type) or "none"
				local seal = self.seal or "none"
				MP.STATS.on_joker_acquired(key, edition, seal, 0, "other")
			end
		end
	end
	return add_to_deck_ref(self, from_debuff)
end

local use_card_ref = G.FUNCS.use_card
function G.FUNCS.use_card(e, mute, nosave)
	if e.config and e.config.ref_table and e.config.ref_table.ability and e.config.ref_table.ability.name then
		sendTraceMessage(
			string.format("Client sent message: action:usedCard,card:%s", e.config.ref_table.ability.name),
			"MULTIPLAYER"
		)
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
