--[[
  Determinism test for MP.rng and the features built on it.

  Two simulated clients share a run seed but do different amounts of unrelated
  RNG work (vanilla pseudorandom reseeds math.random constantly) and query in a
  different order. Everything keyed through MP.rng must still agree:

    - raw rolls / chance / element / pick
    - Chaos Clock schedule: ante rolls and per-blind rolls

  Also sanity-checks rates: each severity draws at its preset's rate, Calm
  never draws severity 3.

  Needs LuaJIT (vanilla's pseudorandom seeds math.random with a fraction).
  Usage (repo root):  luajit tests/test_rng_determinism.lua
]]

assert(jit, "run with luajit: vanilla pseudorandom needs a fractional math.randomseed")

local ROOT = "."
SMODS = { Mods = {} }
G = { FUNCS = {} }
MP = { LOBBY = { config = {} }, SP = {} }
dofile(ROOT .. "/tests/_stubs.lua")
dofile(ROOT .. "/lib/rng.lua")
dofile(ROOT .. "/layers/_layers.lua")
dofile(ROOT .. "/layers/_mutators.lua")
dofile(ROOT .. "/layers/chaos_clock.lua")

local failures, checks = {}, 0
local function check(cond, msg)
	checks = checks + 1
	if not cond then failures[#failures + 1] = msg end
end

local SEED = "MPTEST01"
local ANTES, BLINDS = 8, { "Small", "Big", "Boss" }
local POOL = { s1 = { "a1", "b1", "c1" }, s2 = { "a2", "b2", "c2", "d2" }, s3 = { "a3", "b3" } }

-- One client's view of a run: every keyed roll, in the client's own order,
-- with unrelated RNG noise between calls.
local function simulate(noise, reverse)
	local rng = MP.rng.stream(SEED)
	local out = { ante = {}, blind = {}, raw = {} }
	local antes = {}
	for a = 1, ANTES do
		antes[#antes + 1] = a
	end
	if reverse then
		local r = {}
		for i = #antes, 1, -1 do
			r[#r + 1] = antes[i]
		end
		antes = r
	end
	for _, a in ipairs(antes) do
		for _ = 1, noise do
			pseudorandom(math.random() * 1000)
		end
		out.ante[a] = table.concat(MP.CHAOS_CLOCK.roll(rng, "mayhem", POOL, "ante", a), ",")
		for _, b in ipairs(BLINDS) do
			math.random()
			out.blind[a .. b] = table.concat(MP.CHAOS_CLOCK.roll(rng, "normal", POOL, "blind", a, b), ",")
		end
		out.raw[a] = { rng:roll("raw", a), rng:int(1, 52, "int", a), rng:element({ "x", "y", "z" }, "el", a) }
	end
	return out
end

local A = simulate(0, false)
local B = simulate(37, true)

for a = 1, ANTES do
	check(A.ante[a] == B.ante[a], ("clock ante roll %d differs"):format(a))
	for i = 1, 3 do
		check(A.raw[a][i] == B.raw[a][i], ("raw roll %d/%d differs"):format(a, i))
	end
end
for k, v in pairs(A.blind) do
	check(B.blind[k] == v, "clock blind roll differs at " .. k)
end

-- Rates over a larger sample.
local rng = MP.rng.stream(SEED)
local N = 4000
local function rate(preset, sev)
	local only = { s1 = {}, s2 = {}, s3 = {} }
	only["s" .. sev] = POOL["s" .. sev]
	local n = 0
	for i = 1, N do
		if #MP.CHAOS_CLOCK.roll(rng, preset, only, "blind", i, "Small") > 0 then n = n + 1 end
	end
	return n / N
end
for _, preset in ipairs({ "calm", "normal", "mayhem" }) do
	for sev, want in ipairs(MP.CHAOS_CLOCK.PRESETS[preset].rates) do
		local got = rate(preset, sev)
		check(math.abs(got - want) < 0.03, ("%s severity %d rate %.3f, want ~%.2f"):format(preset, sev, got, want))
	end
end
check(rate("calm", 3) == 0, "calm never draws severity 3")
check(
	#MP.CHAOS_CLOCK.roll(rng, "mayhem", { s1 = {}, s2 = {}, s3 = {} }, "blind", 1, "Small") == 0,
	"empty pool draws nothing"
)

-- Different seeds diverge somewhere.
local other = MP.rng.stream("OTHERSEED")
local same = 0
for i = 1, 200 do
	if other:chance(0.5, "x", i) == rng:chance(0.5, "x", i) then same = same + 1 end
end
check(same < 160, "different seeds produce near-identical rolls (" .. same .. "/200)")

-- pick: n distinct items.
local picked = rng:pick({ 1, 2, 3, 4, 5, 6, 7, 8 }, 3, "pick-test")
local seen = {}
for _, v in ipairs(picked) do
	check(not seen[v], "pick returned a duplicate")
	seen[v] = true
end
check(#picked == 3, "pick returned " .. #picked .. " items, want 3")

print(("RNG determinism: %d checks, %d failed"):format(checks, #failures))
for _, f in ipairs(failures) do
	print("  FAIL " .. f)
end
os.exit(#failures == 0 and 0 or 1)
