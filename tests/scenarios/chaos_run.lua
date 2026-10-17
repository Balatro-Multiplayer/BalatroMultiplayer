-- Practice run with the Chaos Clock on Mayhem, an On game modifier (skipped by
-- the clock) and the sandbox idol override: forecast on blind select, skip
-- Small (dodging its draw), play a hand in Big, then an ante-up.
local SEED = "CHAOS01"

local function picks_str(picks)
	local parts = {}
	for i, p in ipairs(picks) do
		parts[i] = p.key .. ":" .. p.window
	end
	return table.concat(parts, ",")
end

local cash_out_btn

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

return {
	{
		wait = 2,
		run = function(S)
			MP.MODIFIERS = {}
			MP.add_modifier("clock_mayhem")
			MP.add_modifier("discard_tax")
			MP.add_modifier("sandbox_retired")
			MP.add_modifier("idol_both")
			MP.SP.practice = true
			MP.SP.ruleset = "ruleset_mp_blitz"
			MP.LOBBY.config.ruleset = nil
			MP.LoadReworks("blitz")
			G.FUNCS.start_run(nil, { seed = SEED, stake = 1 })
		end,
	},
	{
		wait = 1,
		until_ = function()
			return G.STATE == G.STATES.BLIND_SELECT and G.blind_select_opts and G.blind_select_opts.small
		end,
		timeout = 15,
		run = function(S)
			S.check(G.GAME.modifiers.discard_cost == 1, "discard_tax wrote vanilla discard_cost")
			local clock = G.GAME.mp_clock
			S.check(clock and clock.preset == "mayhem", "clock started on Mayhem")
			local in_pool = false
			for _, list in pairs(clock.pool.blind) do
				for _, k in ipairs(list) do
					if k == "discard_tax" then in_pool = true end
				end
			end
			S.check(not in_pool, "On cell discard_tax left out of the pool")
			S.check(#clock.pool.blind.s1 > 0 and #clock.pool.ante.s2 > 0, "blind and ante pools filled")
			S.check(G.GAME.banned_keys["j_idol"] == true, "idol override bans vanilla Idol")
			S.check(
				MP.SANDBOX.is_joker_allowed("j_mp_idol_sandbox_zealot")
					and MP.SANDBOX.is_joker_allowed("j_mp_idol_sandbox_collector"),
				"idol_both allows both sandbox idols"
			)
			S.check(MP.SANDBOX.is_joker_allowed("j_mp_bloodstone_sandbox"), "retired group allowed on blitz")
			S.check(not MP.SANDBOX.is_joker_allowed("j_mp_mail_sandbox"), "rotation group not allowed on blitz")
			S.check(G.GAME.banned_keys["j_bloodstone"] == true, "retired group hides vanilla Bloodstone")
			S.check(clock.forecast and clock.forecast.ante == 1, "ante 1 forecast at run start")
			S.check(clock.ante == 1, "ante 1 draw applied at run start")
			for _, slot in ipairs({ "Small", "Big", "Boss" }) do
				S.log(slot .. " forecast: " .. picks_str(clock.forecast.blinds[slot]))
			end
		end,
	},
	{
		wait = 1.5,
		run = function(S)
			S.shot("blind_select")
			local skip = find_button(G.blind_select_opts.small, "skip_blind")
			S.check(skip ~= nil, "found small blind skip button")
			G.FUNCS.skip_blind(skip)
		end,
	},
	{
		wait = 1,
		until_ = function()
			return G.GAME.blind_on_deck == "Big" and G.blind_select_opts and G.blind_select_opts.big
		end,
		timeout = 10,
		run = function(S)
			local clock = G.GAME.mp_clock
			S.check(clock.done["1_Small"], "skipped Small marked done")
			for _, p in ipairs(clock.forecast.blinds.Small) do
				if p.window ~= "instant" then S.check(not clock.live[p.window][p.key], "skip dodged " .. p.key) end
			end
			local btn = find_button(G.blind_select_opts.big, "select_blind")
			S.check(btn ~= nil, "found big blind button")
			G.FUNCS.select_blind(btn)
		end,
	},
	{
		wait = 1,
		until_ = function()
			return G.STATE == G.STATES.SELECTING_HAND and G.hand and #G.hand.cards > 0
		end,
		timeout = 15,
		run = function(S)
			local clock = G.GAME.mp_clock
			S.check(clock.done["1_Big"], "Big blind applied")
			for _, p in ipairs(clock.forecast.blinds.Big) do
				if p.window ~= "instant" then
					S.check(clock.live[p.window][p.key] == true, p.key .. " live in the " .. p.window .. " window")
					local layer = MP.Layers[p.key]
					if layer.flag then S.check(G.GAME.modifiers[layer.flag] == true, p.key .. " flag on") end
				end
			end
			for _, p in ipairs(clock.forecast.ante_picks) do
				if p.window ~= "instant" then
					S.check(
						clock.live[p.window][p.key] == true,
						p.key .. " (ante draw) live in the " .. p.window .. " window"
					)
				end
			end
			S.check(#clock.pending == 0, "banner flushed on first hand drawn")
			S.check(G.MP_CLOCK_HUD ~= nil or #MP.CHAOS_CLOCK.live() == 0, "HUD readout up while windows are live")
		end,
	},
	{
		wait = 3,
		run = function(S)
			S.shot("first_hand")
			for i = 1, math.min(5, #G.hand.cards) do
				G.hand:add_to_highlighted(G.hand.cards[i], true)
			end
			G.FUNCS.play_cards_from_highlighted()
		end,
	},
	{
		wait = 1,
		until_ = function()
			return G.GAME.current_round.hands_played == 1 and G.STATE == G.STATES.SELECTING_HAND
		end,
		timeout = 20,
		run = function(S)
			local clock = G.GAME.mp_clock
			local n = 0
			for _ in pairs(clock.done) do
				n = n + 1
			end
			S.check(n == 2, "playing a hand doesn't apply a draw (done: " .. n .. ", want Small skip + Big)")
			S.check(#clock.pending == 0, "nothing queued after a played hand")
		end,
	},
	{
		wait = 2.5,
		run = function(S)
			S.shot("second_hand")
			-- Win Big on the next hand to reach the shop.
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
			-- The cash out button is its own UIBox (major = G.round_eval), added last.
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
			S.check(next(G.GAME.mp_clock.live.ante) ~= nil == (G.MP_CLOCK_HUD ~= nil), "HUD readout follows the shop")
			S.shot("shop")
			-- Smoke test for the ante-up hook: rolling happens in an event queued
			-- after the ante goes up.
			ease_ante(1)
		end,
	},
	{
		wait = 0.5,
		until_ = function()
			return G.GAME.round_resets.ante == 2 and G.GAME.mp_clock.ante == 2
		end,
		timeout = 5,
		run = function(S)
			S.check(true, "ante-up rolled ante 2 without a blind")
			S.check(not G.GAME.mp_clock.done["2_Small"], "ante-up doesn't apply a blind draw")
			S.check(G.GAME.mp_clock.forecast.ante == 2, "ante-up forecasts ante 2")
		end,
	},
	{
		wait = 0.6,
		run = function(S)
			S.shot("ante_up")
		end,
	},
}
