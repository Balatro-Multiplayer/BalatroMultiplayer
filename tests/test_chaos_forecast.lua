--[[
  Chaos Clock forecast (layers/chaos_clock.lua): the whole ante is rolled as it
  starts, each blind's draw applies when that blind starts.

    - what goes live at a blind is exactly that slot's forecast
    - skipping a blind dodges its draw (nothing from it goes live) and ends the
      previous blind's window
    - two clients with different skips get the same forecast every ante, because
      run-long picks leave the pool when drawn, not when they go live
    - a run-long pick is never drawn twice
    - instants show as "?" in forecast_for

  Usage (repo root):  luajit tests/test_chaos_forecast.lua
]]

assert(jit, "run with luajit: vanilla pseudorandom needs a fractional math.randomseed")

local ROOT = "."
SMODS = {
	GameObject = {
		extend = function(_, t)
			return setmetatable(t, {
				__call = function(_, i)
					return i
				end,
			})
		end,
	},
	Mods = {},
}
G = { P_CENTER_POOLS = { Ruleset = {} }, localization = { descriptions = { Ruleset = {} } }, FUNCS = {} }
MP = {
	LOBBY = { config = {} },
	SP = {},
	DECK = {},
	UTILS = {},
	UI = {},
	EXPERIMENTAL = {},
	is_pvp_boss = function()
		return false
	end,
	should_use_the_order = function()
		return false
	end,
}
dofile(ROOT .. "/tests/_stubs.lua")

local function lua_files_in(dir)
	local files = {}
	local p = io.popen('ls "' .. dir .. '"/*.lua 2>/dev/null')
	for line in p:lines() do
		files[#files + 1] = line
	end
	p:close()
	table.sort(files, function(a, b)
		local a_under, b_under = a:match("/_[^/]*$") ~= nil, b:match("/_[^/]*$") ~= nil
		if a_under ~= b_under then return a_under end
		return a < b
	end)
	return files
end

dofile(ROOT .. "/lib/rng.lua")
for _, path in ipairs(lua_files_in(ROOT .. "/layers")) do
	dofile(path)
end

-- The live pool has no severity 3 blind window, so a
-- blind draw is never run-long. Add one so the skip / pool checks have teeth.
MP.Layer("test_storm", { flag = "mp_test_storm" })
MP.Mutator({
	key = "test_storm",
	category = "CHAOS",
	order = 99,
	label = "Test Storm",
	desc = { "Test only." },
	clock = { at = "blind", lasts = "blind", severity = 3 },
})

local failures, checks = {}, 0
local function check(cond, msg)
	checks = checks + 1
	if not cond then failures[#failures + 1] = msg end
end

MP.active_layer_chain = function()
	return MP.MODIFIERS
end
G.E_MANAGER = { add_event = function() end }
Event = function(t)
	return t
end
copy_table = function(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = type(v) == "table" and copy_table(v) or v
	end
	return out
end
ease_hands_played = function(mod)
	G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + mod
end
ease_discard = function(mod)
	G.GAME.current_round.discards_left = G.GAME.current_round.discards_left + mod
end

local SLOTS = { "Small", "Big", "Boss" }
local ANTES = 8

local function picks_str(picks)
	local parts = {}
	for i, p in ipairs(picks) do
		parts[i] = p.key .. ":" .. p.window
	end
	return table.concat(parts, ",")
end

local function forecast_str(f)
	local parts = { "ante=" .. picks_str(f.ante_picks) }
	for _, slot in ipairs(SLOTS) do
		parts[#parts + 1] = slot .. "=" .. picks_str(f.blinds[slot])
	end
	return table.concat(parts, " ")
end

-- One client's run. `skip(ante, slot)` says which blinds this client skips.
local function client(seed, preset, skip)
	MP.MODIFIERS = { "clock_" .. preset }
	G.GAME = {
		modifiers = {},
		round_resets = { hands = 4, discards = 3, ante = 1 },
		current_round = { hands_left = 4, discards_left = 3 },
		pseudorandom = { seed = seed },
	}
	MP.ApplyGameModifiers()
	local clock = G.GAME.mp_clock
	local forecasts, run_draws, small_picks = {}, {}, 0
	for ante = 1, ANTES do
		if ante > 1 then
			G.GAME.round_resets.ante = ante
			MP.CHAOS_CLOCK.on_ante_start(false)
		end
		check(clock.forecast.ante == ante, seed .. ": forecast is for ante " .. ante)
		forecasts[ante] = forecast_str(clock.forecast)
		for _, p in ipairs(clock.forecast.ante_picks) do
			if p.window == "run" then run_draws[#run_draws + 1] = p.key end
		end
		for _, slot in ipairs(SLOTS) do
			local picks = clock.forecast.blinds[slot]
			if slot == "Small" then small_picks = small_picks + #picks end
			for _, p in ipairs(picks) do
				if p.window == "run" then run_draws[#run_draws + 1] = p.key end
			end
			local shown = MP.CHAOS_CLOCK.forecast_for(slot)
			for i, p in ipairs(picks) do
				check(
					(shown[i].text == "?") == (p.window == "instant"),
					seed .. ": forecast_for shows instants (and only instants) as ?"
				)
			end
			G.GAME.blind_on_deck = slot
			local where = seed .. " " .. ante .. "_" .. slot
			if skip(ante, slot) then
				MP.CHAOS_CLOCK.on_blind_skipped(slot)
				check(next(clock.live.blind) == nil, where .. ": skip ends the blind window")
				for _, p in ipairs(picks) do
					if p.window == "run" then
						check(not clock.live.run[p.key], where .. ": skipped run pick " .. p.key .. " never goes live")
					end
				end
				MP.CHAOS_CLOCK.on_blind_start() -- a skipped slot can't start later
				check(next(clock.live.blind) == nil, where .. ": skipped slot stays dodged")
			else
				MP.CHAOS_CLOCK.on_blind_start()
				local want = 0
				for _, p in ipairs(picks) do
					if p.window == "blind" or p.window == "run" then
						check(clock.live[p.window][p.key], where .. ": " .. p.key .. " live in " .. p.window)
					end
					if p.window == "blind" then want = want + 1 end
				end
				local live = 0
				for _ in pairs(clock.live.blind) do
					live = live + 1
				end
				check(
					live == want,
					where .. ": blind window is exactly the forecast (" .. live .. " vs " .. want .. ")"
				)
			end
		end
	end
	return forecasts, run_draws, small_picks
end

local never = function()
	return false
end
local smalls = function(_, slot)
	return slot == "Small"
end

-- Enough seeds that some Small blind draws a run-long pick early and a later
-- roll could land on it again: that's where live-vs-drawn exclusion diverges.
local any_small, any_run = false, false
for n = 1, 30 do
	local seed = "FORECAST" .. n
	local a, a_run, small_picks = client(seed, "mayhem", never)
	local b = client(seed, "mayhem", smalls)
	for ante = 1, ANTES do
		check(
			a[ante] == b[ante],
			seed .. " ante " .. ante .. ": skips changed the forecast\n  " .. a[ante] .. "\n  " .. b[ante]
		)
	end
	any_small = any_small or small_picks > 0
	any_run = any_run or #a_run > 0
	local seen = {}
	for _, key in ipairs(a_run) do
		check(not seen[key], seed .. ": run pick " .. key .. " drawn twice")
		seen[key] = true
	end
end

check(any_small, "no Small blind ever drew, so the skip checks are vacuous")
check(any_run, "no run-long pick drawn, so the pool checks are vacuous")

-- Normal has no run window: only the skip / apply checks apply.
client("FORECAST_NORMAL", "normal", smalls)

-- Polymorph must run at ante start, including between rounds before the shop,
-- rather than waiting for a hand. Exercise the real transformation with a tiny
-- card pool, forcing the clock to choose it whenever the preset permits it.
local original_rng = MP.rng.game
MP.rng.game = function()
	return {
		chance = function(_, rate, _, _, severity)
			return rate > 0 and severity == 3
		end,
		element = function(_, list)
			for _, key in ipairs(list) do
				if key == "polymorph_spam" then return key end
			end
			return list[1]
		end,
	}
end

local centers = {
	{ key = "poly_joker_a", set = "Joker" },
	{ key = "poly_joker_b", set = "Joker" },
	{ key = "poly_tarot_a", set = "Tarot", consumeable = true },
	{ key = "poly_tarot_b", set = "Tarot", consumeable = true },
}
G.P_CENTERS = {}
for _, center in ipairs(centers) do
	G.P_CENTERS[center.key] = center
end
G.P_CENTER_POOLS.Joker = { centers[1], centers[2] }
G.P_CENTER_POOLS.Tarot = { centers[3], centers[4] }
local function card(center)
	return {
		config = { center = center },
		set_ability = function(self, next_center)
			self.config.center = next_center
			self.transformations = (self.transformations or 0) + 1
		end,
		set_cost = function() end,
	}
end
local function start_polymorph_run(preset)
	MP.MODIFIERS = { "clock_" .. preset }
	G.GAME = {
		modifiers = {},
		banned_keys = {},
		round_resets = { hands = 4, discards = 3, ante = 1 },
		current_round = { hands_left = 4, discards_left = 3 },
		pseudorandom = { seed = "POLYMORPH" },
	}
	G.jokers = { cards = { card(centers[1]) }, config = { card_limit = 1 } }
	G.consumeables = { cards = { card(centers[3]) }, config = { card_limit = 1 } }
	G.hand = { cards = { {} } }
	MP.ApplyGameModifiers()
end

start_polymorph_run("mayhem")
check(G.jokers.cards[1].config.center == centers[2], "Mayhem transforms Jokers immediately at ante start")
check(G.consumeables.cards[1].config.center == centers[4], "Mayhem transforms consumables immediately at ante start")
MP.CHAOS_CLOCK.on_ante_start(false)
check(G.jokers.cards[1].transformations == 1, "repeated ante-start call doesn't transform twice")
for _, slot in ipairs(SLOTS) do
	G.GAME.blind_on_deck = slot
	MP.CHAOS_CLOCK.on_blind_start()
	MP.CHAOS_CLOCK.on_hand_drawn()
	check(G.jokers.cards[1].transformations == 1, slot .. ": blind and hand starts cannot retrigger Polymorph")
end
G.GAME.round_resets.ante = 2
MP.CHAOS_CLOCK.on_ante_start(false)
check(G.jokers.cards[1].transformations == 2, "next ante can trigger Polymorph before drawing a hand")
check(G.consumeables.cards[1].transformations == 2, "next ante also transforms consumables")
for _, preset in ipairs({ "calm", "normal" }) do
	start_polymorph_run(preset)
	check(not G.jokers.cards[1].transformations, preset .. ": Polymorph never transforms Jokers")
	check(not G.consumeables.cards[1].transformations, preset .. ": Polymorph never transforms consumables")
end
MP.rng.game = original_rng

print(("Chaos forecast: %d checks, %d failed"):format(checks, #failures))
for _, f in ipairs(failures) do
	print("  FAIL " .. f)
end
os.exit(#failures == 0 and 0 or 1)
