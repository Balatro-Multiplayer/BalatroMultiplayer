--[[
  ReworkCenter engine checks (rulesets/_reworks.lua).

  Usage (from the repo root):
    lua tests/test_reworks.lua

  Stubs just enough of G / SMODS to load the engine, registers reworks, drains
  them through a fake SMODS.injectItems, and asserts on the live tables.
]]

local failures, passes = 0, 0
local function check(label, cond)
	if cond then
		passes = passes + 1
		print("ok   - " .. label)
	else
		failures = failures + 1
		print("FAIL - " .. label)
	end
end

local warnings = {}
function sendWarnMessage(msg)
	warnings[#warnings + 1] = msg
end

-- Stable dump of a value; tables by sorted key, functions by identity.
local function dump(v, seen)
	seen = seen or {}
	if type(v) ~= "table" then return type(v) .. ":" .. tostring(v) end
	if seen[v] then return "<cycle>" end
	seen[v] = true
	local keys = {}
	for k in pairs(v) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	local parts = {}
	for _, k in ipairs(keys) do
		parts[#parts + 1] = tostring(k) .. "=" .. dump(v[k], seen)
	end
	seen[v] = nil
	return "{" .. table.concat(parts, ",") .. "}"
end

local function pool_keys(bucket)
	local out = {}
	for i, c in ipairs(G.P_JOKER_RARITY_POOLS[bucket]) do
		out[i] = c.key
	end
	return table.concat(out, " ")
end

local function world()
	return dump({ G.P_CENTERS, G.P_TAGS, SMODS.PokerHands, pool_keys(1), pool_keys(2), pool_keys(3) })
end

local GENERATE_UI = function() end

-- Fresh game tables + a freshly loaded engine (its state is file-local).
local function fresh()
	local function joker(key, order, rarity, extra)
		return { key = key, set = "Joker", order = order, rarity = rarity, config = { extra = extra or {} } }
	end
	G = {
		P_CENTERS = {
			m_glass = { key = "m_glass", set = "Enhanced", config = { Xmult = 2, extra = 5 } },
			j_a = joker("j_a", 1, 1),
			j_b = joker("j_b", 2, 1),
			j_sixth_sense = joker("j_sixth_sense", 3, 1),
			j_c = joker("j_c", 4, 3),
			j_d = joker("j_d", 6, 3),
			j_greedy = joker("j_greedy", 7, 1, { s_mult = 3, suit = "Diamonds" }),
			j_wip = { key = "j_wip", set = "Joker", order = 99, rarity = 1, wip = true, config = {} },
		},
		P_TAGS = { tag_rare = { key = "tag_rare", config = { type = "store_joker_create" } } },
		P_SEALS = {},
		P_STAKES = {},
		P_BLINDS = {},
		STAGES = { MAIN_MENU = 1, RUN = 2 },
	}
	local c = G.P_CENTERS
	G.P_JOKER_RARITY_POOLS = {
		{ c.j_a, c.j_b, c.j_sixth_sense, c.j_greedy },
		{},
		{ c.j_c, c.j_d },
		{},
	}
	SMODS = {
		PokerHands = { ["Flush"] = { key = "Flush", l_mult = 2, l_chips = 15 } },
		Center = { generate_ui = GENERATE_UI },
		injectItems = function() end,
	}
	MP = {
		active_layer_chain = function(short)
			return { "chain_of", short }
		end,
	}
	warnings = {}
	dofile("rulesets/_reworks.lua")
end

local function register_basic()
	MP.ReworkCenter("m_glass", { layers = { "standard", "classic" }, config = { Xmult = 1.5, extra = 4 } })
	MP.ReworkCenter("m_glass", { layers = "sandbox", config = { Xmult = 1.5, extra = 3 } })
	MP.ReworkCenter("j_greedy", { layers = "release", config = { extra = { s_mult = 4 } } })
	MP.ReworkCenter("j_sixth_sense", { layers = "release", rarity = 3 })
	MP.ReworkCenter("tag_rare", { layers = "release", center_table = "P_TAGS", config = { odds = 2 } })
	MP.ReworkCenter("Flush", { layers = "release", center_table = SMODS.PokerHands, l_mult = 4 })
end

local function glass()
	local cfg = G.P_CENTERS.m_glass.config
	return cfg.Xmult .. "/" .. cfg.extra
end

-- ─── Resolution per chain ───────────────────────────────────────────────────
fresh()
register_basic()
local vanilla_world = world()
SMODS.injectItems()
check("drain leaves live tables untouched", world() == vanilla_world)

MP.ApplyReworks({})
check("{} => m_glass 2/5", glass() == "2/5")
check("{} => no Balanced flag", G.P_CENTERS.m_glass.mp_balanced == nil)
MP.ApplyReworks({ "standard", "blitz" })
check("standard => m_glass 1.5/4", glass() == "1.5/4")
check("standard => Balanced flag", G.P_CENTERS.m_glass.mp_balanced == true)
MP.ApplyReworks({ "standard", "sandbox" })
check("standard then sandbox => sandbox wins (1.5/3)", glass() == "1.5/3")
MP.ApplyReworks({ "release" })
local greedy = G.P_CENTERS.j_greedy.config.extra
check("partial config deep-merges (s_mult 4, suit kept)", greedy.s_mult == 4 and greedy.suit == "Diamonds")
check("P_TAGS by name", G.P_TAGS.tag_rare.config.odds == 2 and G.P_TAGS.tag_rare.config.type == "store_joker_create")
check("PokerHands by table ref", SMODS.PokerHands.Flush.l_mult == 4 and SMODS.PokerHands.Flush.l_chips == 15)
check("release leaves m_glass vanilla", glass() == "2/5")

-- ─── History independence and restore (spec 4, 8) ───────────────────────────
MP.ApplyReworks({})
check("{} after everything == pre-drain vanilla", world() == vanilla_world)

local histories = {
	{},
	{ { "sandbox" }, { "release" }, { "standard" } },
	{ { "release" }, { "release" }, {}, { "standard", "sandbox" } },
}
local targets = { { "standard" }, { "release" }, { "standard", "release" }, {} }
for _, target in ipairs(targets) do
	local results = {}
	for i, history in ipairs(histories) do
		for _, step in ipairs(history) do
			MP.ApplyReworks(step)
		end
		MP.ApplyReworks(target)
		results[i] = world()
	end
	check(
		"{" .. table.concat(target, ",") .. "} lands identically after 3 histories",
		results[1] == results[2] and results[2] == results[3]
	)
end

-- A card scribbling on its center can't leak into the next apply.
MP.ApplyReworks({ "standard" })
G.P_CENTERS.m_glass.config.Xmult = 999
G.P_CENTERS.j_greedy.config.extra.s_mult = 999
MP.ApplyReworks({ "standard" })
check("live mutation is rebuilt away (m_glass)", glass() == "1.5/4")
MP.ApplyReworks({})
check("live mutation is rebuilt away (j_greedy)", G.P_CENTERS.j_greedy.config.extra.s_mult == 3)
check("{} after mutation == vanilla", world() == vanilla_world)

-- ─── Rarity pools (spec 5, 6) ───────────────────────────────────────────────
fresh()
register_basic()
local c = G.P_CENTERS
local pool1, pool3 = G.P_JOKER_RARITY_POOLS[1], G.P_JOKER_RARITY_POOLS[3]
local before = { pool_keys(1), pool_keys(2), pool_keys(3), pool_keys(4) }
SMODS.injectItems()

MP.ApplyReworks({ "standard" })
check("config-only chain leaves pools exactly as loaded", pool_keys(1) == before[1] and pool_keys(3) == before[3])

MP.ApplyReworks({ "release" })
check("release => sixth_sense rarity 3", c.j_sixth_sense.rarity == 3)
check("release => sixth_sense out of bucket 1", pool_keys(1) == "j_a j_b j_greedy")
check("release => sixth_sense in bucket 3 at its order slot", pool_keys(3) == "j_sixth_sense j_c j_d")
check("pools refilled in place", G.P_JOKER_RARITY_POOLS[1] == pool1 and G.P_JOKER_RARITY_POOLS[3] == pool3)
MP.ApplyReworks({ "release" })
check("release twice => same pools", pool_keys(3) == "j_sixth_sense j_c j_d")

MP.ApplyReworks({})
check("{} => sixth_sense back to rarity 1", c.j_sixth_sense.rarity == 1)
check(
	"{} => every pool equals the load-time order",
	pool_keys(1) == before[1] and pool_keys(2) == before[2] and pool_keys(3) == before[3] and pool_keys(4) == before[4]
)

-- String rarities normalize the way SMODS does at inject.
fresh()
MP.ReworkCenter("j_sixth_sense", { layers = "release", rarity = "Rare" })
SMODS.injectItems()
MP.ApplyReworks({ "release" })
check("rarity = \"Rare\" lands in bucket 3", G.P_CENTERS.j_sixth_sense.rarity == 3 and pool_keys(3):find("j_sixth_sense"))

-- Unlisted jokers stay unlisted; a bucket nobody targets is never rebuilt.
fresh()
MP.ReworkCenter("j_wip", { layers = "release", rarity = 3 })
local bucket2 = G.P_JOKER_RARITY_POOLS[2]
bucket2[1] = G.P_CENTERS.j_a -- deliberately odd content, must survive untouched
SMODS.injectItems()
MP.ApplyReworks({ "release" })
check("WIP joker reworked to rare stays out of the pools", not pool_keys(3):find("j_wip"))
check("untargeted bucket untouched", G.P_JOKER_RARITY_POOLS[2][1] == G.P_CENTERS.j_a)

-- Game:init_item_prototypes (profile switch, language change) rebuilds every
-- center and pool table, and SMODS re-runs injectItems.
local function reinit()
	local old = G.P_CENTERS
	G.P_CENTERS = {}
	for key, center in pairs(old) do
		G.P_CENTERS[key] = { key = key, set = center.set, order = center.order, rarity = 1, config = { extra = {} } }
	end
	G.P_CENTERS.m_glass = { key = "m_glass", set = "Enhanced", config = { Xmult = 2, extra = 5 } }
	G.P_CENTERS.j_c.rarity, G.P_CENTERS.j_d.rarity = 3, 3
	G.P_CENTERS.j_greedy.config.extra = { s_mult = 3, suit = "Diamonds" }
	G.P_CENTERS.j_wip.wip = true
	local n = G.P_CENTERS
	G.P_JOKER_RARITY_POOLS = { { n.j_a, n.j_b, n.j_sixth_sense, n.j_greedy }, {}, { n.j_c, n.j_d }, {} }
	SMODS.injectItems()
end
fresh()
register_basic()
SMODS.injectItems()
MP.ApplyReworks({ "release" })
reinit()
check("re-inject puts the written chain back", G.P_CENTERS.j_sixth_sense.rarity == 3)
check("re-inject moves the fresh center, not the stale one", G.P_JOKER_RARITY_POOLS[3][1] == G.P_CENTERS.j_sixth_sense)
MP.ApplyReworks({})
check("after re-inject, {} restores the fresh pools", pool_keys(1) == "j_a j_b j_sixth_sense j_greedy" and pool_keys(3) == "j_c j_d")
MP.ApplyReworks({ "standard" })
check("after re-inject, config reworks hit the fresh center", glass() == "1.5/4")

-- ─── Absent props, loc_key, silent ──────────────────────────────────────────
fresh()
local my_loc_vars = function()
	return { vars = { 1 } }
end
MP.ReworkCenter("j_greedy", { layers = "release", loc_key = "j_mp_greedy_release", loc_vars = my_loc_vars })
MP.ReworkCenter("m_glass", { layers = "quiet", silent = true, config = { extra = 9 } })
MP.ReworkCenter("m_glass", { layers = "loud", config = { Xmult = 3 } })
SMODS.injectItems()
MP.ApplyReworks({ "release" })
local g = G.P_CENTERS.j_greedy
check("loc_key wraps loc_vars", g.loc_vars and g.loc_vars(g, {}, {}).key == "j_mp_greedy_release")
check("generate_ui added alongside loc_vars", g.generate_ui == GENERATE_UI)
MP.ApplyReworks({})
check("absent props removed again under {}", g.loc_vars == nil and g.generate_ui == nil)
MP.ApplyReworks({ "quiet" })
check("silent rework => applied, no Balanced flag", glass() == "2/9" and G.P_CENTERS.m_glass.mp_balanced == nil)
MP.ApplyReworks({ "quiet", "loud" })
check("silent + loud => Balanced flag", G.P_CENTERS.m_glass.mp_balanced == true and glass() == "3/9")

-- ─── Load-time errors ───────────────────────────────────────────────────────
fresh()
MP.ReworkCenter("m_glass", { layers = "standard", config = { extra = 4 } })
MP.ReworkCenter("m_glass", { layers = { "sandbox", "standard" }, config = { extra = 3 } })
check("duplicate (key, layer) errors at drain", not pcall(SMODS.injectItems))

fresh()
MP.ReworkCenter("j_nope", { layers = "standard", cost = 1 })
SMODS.injectItems()
check("unknown key warns instead of crashing", #warnings == 1 and warnings[1]:find("j_nope"))

-- ─── Run lock (spec 7) ──────────────────────────────────────────────────────
fresh()
register_basic()
local run_vanilla = world()
SMODS.injectItems()
MP.ApplyReworks({ "sandbox" })
MP.BeginRunReworks({ "standard" })
check("run start applies its chain", glass() == "1.5/4")
MP.ApplyReworks({ "standard" })
check("same chain mid-run is a quiet no-op", #warnings == 0)
MP.ApplyReworks({ "sandbox" })
check("different chain mid-run refused", glass() == "1.5/4")
check("refusal warns", #warnings == 1 and warnings[1]:find("refused"))
MP.BeginRunReworks({ "release" })
check("a new run start may change the chain", G.P_CENTERS.j_sixth_sense.rarity == 3)
MP.EndRunReworks()
check("run end restores vanilla", world() == run_vanilla)
MP.ApplyReworks({ "sandbox" })
check("menu preview works again after the run", glass() == "1.5/3")

-- ─── rework_chain ───────────────────────────────────────────────────────────
check("rework_chain(nil) => {}", #MP.rework_chain(nil) == 0)
check("rework_chain strips ruleset_mp_", MP.rework_chain("ruleset_mp_blitz")[2] == "blitz")
check("rework_chain accepts short names", MP.rework_chain("blitz")[2] == "blitz")

-- ─── Fingerprint ────────────────────────────────────────────────────────────
fresh()
register_basic()
SMODS.injectItems()
local fp_a = MP.rework_fingerprint()
check("fingerprint is 8 hex chars", fp_a:match("^%x%x%x%x%x%x%x%x$") ~= nil)

fresh()
MP.ReworkCenter("Flush", { layers = "release", center_table = SMODS.PokerHands, l_mult = 4 })
MP.ReworkCenter("tag_rare", { layers = "release", center_table = "P_TAGS", config = { odds = 2 } })
MP.ReworkCenter("j_sixth_sense", { layers = "release", rarity = 3 })
MP.ReworkCenter("j_greedy", { layers = "release", config = { extra = { s_mult = 4 } } })
MP.ReworkCenter("m_glass", { layers = "sandbox", config = { Xmult = 1.5, extra = 3 } })
MP.ReworkCenter("m_glass", { layers = { "standard", "classic" }, config = { Xmult = 1.5, extra = 4 } })
SMODS.injectItems()
check("registration order doesn't change the fingerprint", MP.rework_fingerprint() == fp_a)
MP.ApplyReworks({ "standard" })
check("applying a chain doesn't change the fingerprint", MP.rework_fingerprint() == fp_a)

fresh()
register_basic()
MP.ReworkCenter("m_glass", { layers = "experimental", config = { extra = 6 } })
SMODS.injectItems()
check("an extra rework changes the fingerprint", MP.rework_fingerprint() ~= fp_a)

fresh()
G.P_CENTERS.m_glass.config.Xmult = 2.5 -- another mod edited vanilla
register_basic()
SMODS.injectItems()
check("a different vanilla baseline changes the fingerprint", MP.rework_fingerprint() ~= fp_a)

print(string.format("\n%d passed, %d failed", passes, failures))
os.exit(failures == 0 and 0 or 1)
