-- MP Jokers as native layer content, in practice runs (no lobby): the real
-- get_current_pool under Blitz Base/Off and Vanilla Base/On, then every MP
-- Joker and Asteroid through a solo blind, cash out and the shop.
local SEED = "MPCONT1"

local content = {} -- key -> pool name ("Common" | "Uncommon" | "Planet")
local POOLS = { "Common", "Uncommon", "Planet" }
local pools = {} -- label -> { [pool] = { keys } }
local prev_game, prev_opts, cash_out_btn

local function toggle(S, key)
	G.FUNCS.mp_toggle_mutator(S.fake_button({ def = MP.MUTATORS[key] }))
end

-- First element under a UIBox whose button is `name`.
local function find_button(box, name)
	local function walk(node)
		if node.config and node.config.button == name then return node end
		for _, child in ipairs(node.children or {}) do
			local hit = walk(child)
			if hit then return hit end
		end
	end
	return box and walk(box.UIRoot)
end

local function start(short, modifiers)
	MP.MODIFIERS = {}
	for _, m in ipairs(modifiers) do
		MP.add_modifier(m)
	end
	MP.SP.practice = true
	MP.SP.ruleset = "ruleset_mp_" .. short
	MP.LOBBY.config.ruleset = nil
	MP.LoadReworks(short)
	prev_game = G.GAME
	prev_opts = G.blind_select_opts and G.blind_select_opts.small
	G.FUNCS.start_run(nil, { seed = SEED, stake = 1 })
end

local function run_ready()
	return G.GAME ~= prev_game
		and G.STATE == G.STATES.BLIND_SELECT
		and G.blind_select_opts
		and G.blind_select_opts.small
		-- start_run from a run leaves the old boxes up for a frame; clicking one stalls.
		and G.blind_select_opts.small ~= prev_opts
end

-- get_current_pool hands back a shared temp table; copy it. Explicit rarity
-- names skip the rarity poll, so this draws no RNG.
local function snapshot(label)
	local out = {}
	for _, pool in ipairs(POOLS) do
		local src = pool == "Planet" and get_current_pool("Planet") or get_current_pool("Joker", pool)
		local copy = {}
		for i, k in ipairs(src) do
			copy[i] = k
		end
		out[pool] = copy
	end
	pools[label] = out
	return out
end

local function count_content(pool)
	local n = 0
	for _, r in pairs(content) do
		if r == pool then n = n + 1 end
	end
	return n
end

local function has(list, key)
	for _, k in ipairs(list) do
		if k == key then return true end
	end
	return false
end

-- Pool minus content keys and UNAVAILABLE slots, joined for comparison.
local function others(list)
	local out = {}
	for _, k in ipairs(list) do
		if not content[k] and k ~= "UNAVAILABLE" then out[#out + 1] = k end
	end
	return table.concat(out, ",")
end

-- Every content card in its pool, except ruleset bans and Penny Pincher
-- (in_pool waits for pincher_unlock): both hold an UNAVAILABLE slot.
local function check_present(S, label, snap)
	for key, pool in pairs(content) do
		if key ~= "j_mp_penny_pincher" and not G.GAME.banned_keys[key] then
			S.check(has(snap[pool], key), label .. ": " .. key .. " in the " .. pool .. " pool")
		end
	end
end

local function check_absent(S, label, snap)
	local leaked = {}
	for key, pool in pairs(content) do
		if has(snap[pool], key) then leaked[#leaked + 1] = key end
	end
	S.check(#leaked == 0, label .. ": no MP content in pools (leaked: " .. table.concat(leaked, ",") .. ")")
end

-- `with` = `without` + exactly the content slots, other slots in the same order.
local function check_slots(S, label, with, without)
	for _, pool in ipairs(POOLS) do
		local diff = #with[pool] - #without[pool]
		local want = count_content(pool)
		S.check(diff == want, ("%s: %s pool differs by %d slots (want %d)"):format(label, pool, diff, want))
		S.check(others(with[pool]) == others(without[pool]), label .. ": " .. pool .. " non-MP slots unchanged")
	end
end

-- MP content in G.GAME.banned_keys, sorted. On/Off must never add to it.
local function content_bans()
	local banned = {}
	for key in pairs(content) do
		if G.GAME.banned_keys[key] then banned[#banned + 1] = key end
	end
	table.sort(banned)
	return table.concat(banned, ",")
end

return {
	-- Wall: Standard base implies MP Jokers; one click On, two Off.
	{
		wait = 2,
		run = function(S)
			local layer = MP.Layers.multiplayer_jokers
			for _, key in ipairs(layer.included_jokers) do
				content[key] = ({ "Common", "Uncommon", "Rare" })[G.P_CENTERS[key].rarity]
			end
			for _, key in ipairs(layer.included_consumables) do
				content[key] = "Planet"
			end
			S.check(count_content("Common") + count_content("Uncommon") == 9, "nine MP Jokers registered")
			S.check(content.c_mp_asteroid == "Planet", "Asteroid registered as a Planet")

			MP.MODIFIERS = {}
			MP.CUSTOM.draft = MP.CUSTOM.new_draft()
			S.check(MP.CUSTOM.base_implies(MP.MUTATORS.multiplayer_jokers.implied_by), "Standard base implies MP Jokers")
			toggle(S, "multiplayer_jokers")
			toggle(S, "multiplayer_jokers")
			S.check(MP.has_modifier("no_multiplayer_jokers"), "wall set to MP Jokers: Off")
			G.FUNCS.overlay_menu({ definition = G.UIDEF.ruleset_selection_tabs("practice", "Custom") })
		end,
	},
	{
		wait = 1.5,
		run = function(S)
			S.shot("wall_off")
		end,
	},
	{
		wait = 0.5,
		run = function(S)
			MP.MODIFIERS = {}
			G.FUNCS.exit_overlay_menu()
		end,
	},

	-- Blitz, Base: inherited from the layer, no lobby needed.
	{
		wait = 0.5,
		run = function()
			start("blitz", {})
		end,
	},
	{
		wait = 1,
		until_ = run_ready,
		timeout = 15,
		run = function(S)
			S.check(MP.LOBBY.code == nil, "blitz base: no lobby")
			S.check(MP.multiplayer_jokers_enabled(), "blitz base: MP Jokers enabled in practice")
			pools.blitz_bans = content_bans()
			S.log("blitz bans (standard layer): " .. pools.blitz_bans)
			check_present(S, "blitz base", snapshot("blitz_base"))
		end,
	},

	-- Blitz, Off: removes the slots outright rather than banning them.
	{
		wait = 0.5,
		run = function()
			start("blitz", { "no_multiplayer_jokers" })
		end,
	},
	{
		wait = 1,
		until_ = run_ready,
		timeout = 15,
		run = function(S)
			S.check(not MP.multiplayer_jokers_enabled(), "blitz off: MP Jokers disabled")
			S.check(content_bans() == pools.blitz_bans, "blitz off: same bans as base (got " .. content_bans() .. ")")
			local off = snapshot("blitz_off")
			check_absent(S, "blitz off", off)
			check_slots(S, "blitz base vs off", pools.blitz_base, off)
		end,
	},

	-- Vanilla, Base: no layer, no content.
	{
		wait = 0.5,
		run = function()
			start("vanilla", {})
		end,
	},
	{
		wait = 1,
		until_ = run_ready,
		timeout = 15,
		run = function(S)
			S.check(not MP.multiplayer_jokers_enabled(), "vanilla base: MP Jokers disabled")
			check_absent(S, "vanilla base", snapshot("vanilla_base"))
		end,
	},

	-- Vanilla, On: adds the slots without disturbing the rest.
	{
		wait = 0.5,
		run = function()
			start("vanilla", { "multiplayer_jokers" })
		end,
	},
	{
		wait = 1,
		until_ = run_ready,
		timeout = 15,
		run = function(S)
			S.check(MP.multiplayer_jokers_enabled(), "vanilla on: MP Jokers enabled")
			S.check(content_bans() == "", "vanilla on: no MP content banned (got " .. content_bans() .. ")")
			local on = snapshot("vanilla_on")
			check_present(S, "vanilla on", on)
			check_slots(S, "vanilla on vs base", on, pools.vanilla_base)

			-- Effects with no opponent: every MP Joker and Asteroid in a solo run.
			G.jokers.config.card_limit = 10
			for key, pool in pairs(content) do
				if pool ~= "Planet" then SMODS.add_card({ key = key }) end
			end
			SMODS.add_card({ key = "c_mp_asteroid" })
		end,
	},
	{
		wait = 1,
		run = function(S)
			S.check(#G.jokers.cards == 9, "nine MP Jokers held (got " .. #G.jokers.cards .. ")")
			S.check(#G.consumeables.cards == 1, "Asteroid held")
			S.shot("jokers")
			G.FUNCS.select_blind(G.blind_select_opts.small:get_UIE_by_ID("select_blind_button"))
		end,
	},
	{
		wait = 1,
		until_ = function()
			return G.STATE == G.STATES.SELECTING_HAND and G.hand and #G.hand.cards > 0
		end,
		timeout = 15,
		run = function(S)
			S.shot("small_blind")
			for i = 1, math.min(5, #G.hand.cards) do
				G.hand:add_to_highlighted(G.hand.cards[i], true)
			end
			G.FUNCS.play_cards_from_highlighted()
		end,
	},
	{
		wait = 1,
		until_ = function()
			return G.GAME.current_round.hands_played == 1
				and (G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.ROUND_EVAL)
		end,
		timeout = 20,
		run = function(S)
			S.check(true, "hand scored with every MP Joker")
			S.log("first hand: " .. G.GAME.chips .. " / " .. G.GAME.blind.chips)
			-- Pacifist's xMult usually clears Small in one hand; otherwise force the win.
			if G.STATE == G.STATES.ROUND_EVAL then return end
			G.GAME.chips = G.GAME.blind.chips
			for i = 1, math.min(5, #G.hand.cards) do
				G.hand:add_to_highlighted(G.hand.cards[i], true)
			end
			G.FUNCS.play_cards_from_highlighted()
		end,
	},
	{
		wait = 1,
		until_ = function()
			if G.STATE ~= G.STATES.ROUND_EVAL or not G.round_eval then return false end
			for _, box in ipairs(G.I.UIBOX) do
				local btn = find_button(box, "cash_out")
				if btn then
					cash_out_btn = btn
					return true
				end
			end
		end,
		timeout = 20,
		run = function(S)
			S.check(true, "round evaluated with every MP Joker")
			S.shot("round_eval")
			G.FUNCS.cash_out(cash_out_btn)
		end,
	},
	{
		wait = 2,
		until_ = function()
			return G.STATE == G.STATES.SHOP and G.shop
		end,
		timeout = 15,
		run = function(S)
			S.check(true, "reached the shop")
			S.log("jokers after round: " .. #G.jokers.cards)
			S.shot("shop")
			S.check(MP.GAME.asteroids == 0, "no asteroids queued before use")
			G.FUNCS.use_card({ config = { ref_table = G.consumeables.cards[1] } })
		end,
	},
	{
		wait = 4,
		run = function(S)
			S.check(MP.GAME.asteroids == 1, "Asteroid used in a solo shop (asteroids=" .. MP.GAME.asteroids .. ")")
			S.check(#G.consumeables.cards == 0, "Asteroid consumed")
			MP.GAME.asteroids = 0
			MP.MODIFIERS = {}
		end,
	},
}
