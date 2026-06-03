--[[
  Rework determinism + desync-safety test.

  Backstops the design contract of MP.ReworkCenter / MP.ApplyReworks /
  MP.PreviewReworks: the EFFECTIVE properties of a reworked center (and the
  rarity-pool ORDER pool generation reads) must be a PURE FUNCTION of the
  resolved context (ruleset + layers + modifiers), identical on two clients no
  matter what either previewed/cycled first.

  It loads the REAL rulesets/_rulesets.lua, stubbing only the globals it touches,
  registers the same reworks the shipped object files do (m_glass multi-layer,
  j_sixth_sense rarity bump), then drives the mechanism through hostile call
  histories and asserts the results agree byte-for-byte.

  Necessary-not-sufficient, like the shape snapshot: it exercises the
  center-mutation path the shape test explicitly skips.

  Run from the repo root:
    lua tests/test_rework_determinism.lua
]]

local RULESETS = "rulesets/_rulesets.lua"

-- ─── Tiny assert framework ──────────────────────────────────────────────────
local pass, fail, failures = 0, 0, {}
local function check(label, cond)
	if cond then
		pass = pass + 1
	else
		fail = fail + 1
		failures[#failures + 1] = label
	end
end

-- ─── Minimal stubs (mirror tests/test_ruleset_shape.lua's approach) ──────────
function sendDebugMessage() end

SMODS = {
	injectItems = function() end, -- the real graft in _rulesets.lua wraps this
	Center = { generate_ui = function() end },
	PokerHands = {},
	process_loc_text = function() end,
	remove_pool = function() end,
	GameObject = {
		extend = function(_, tbl)
			local cls = {}
			for k, v in pairs(tbl) do cls[k] = v end
			setmetatable(cls, { __call = function(_c, init)
				local o = {}
				for k, v in pairs(cls) do o[k] = v end
				for k, v in pairs(init) do o[k] = v end
				return o
			end })
			return cls
		end,
	},
}

-- Two subjects + filler/edge jokers so the rarity rebuild has something to get
-- wrong (equal-order ties, a WIP joker, a demo joker, a non-joker decoy).
local function fresh_centers()
	return {
		m_glass = { key = "m_glass", set = "Enhanced", config = { Xmult = 2, extra = 5 } },
		j_sixth_sense = { key = "j_sixth_sense", set = "Joker", rarity = 1, order = 30 },
		j_common_a = { key = "j_common_a", set = "Joker", rarity = 1, order = 10 },
		j_common_b = { key = "j_common_b", set = "Joker", rarity = 1, order = 50 },
		j_rare_a = { key = "j_rare_a", set = "Joker", rarity = 3, order = 20 },
		j_rare_b = { key = "j_rare_b", set = "Joker", rarity = 3, order = 40 },
		j_rare_tie1 = { key = "j_rare_tie1", set = "Joker", rarity = 3, order = 30 },
		j_rare_tie2 = { key = "j_rare_tie2", set = "Joker", rarity = 3, order = 30 },
		j_wip = { key = "j_wip", set = "Joker", rarity = 3, order = 5, wip = true },
		j_demo = { key = "j_demo", set = "Joker", rarity = 3, order = 6, demo = true },
		c_decoy = { key = "c_decoy", set = "Tarot", rarity = 3, order = 7 },
	}
end

G = {
	P_CENTER_POOLS = { Ruleset = {} },
	localization = { descriptions = { Ruleset = {} } },
	FUNCS = {},
	P_TAGS = {},
	P_SEALS = {},
	P_STAKES = {},
	P_BLINDS = {},
	P_CENTERS = fresh_centers(),
	P_JOKER_RARITY_POOLS = { {}, {}, {}, {} },
}

MP = {
	LOBBY = { config = {} },
	SP = {},
	UI = {},
	Layers = {},
	Rulesets = {},
	MODIFIERS = {},
	_JOKER_LAYERS = {},
	_CONSUMABLE_LAYERS = {},
	_TAG_LAYERS = {},
	_LAYER_ARRAY_FIELDS = {
		"banned_jokers", "banned_consumables", "banned_vouchers",
		"banned_enhancements", "banned_tags", "banned_blinds", "banned_silent",
		"reworked_jokers", "reworked_consumables", "reworked_vouchers",
		"reworked_enhancements", "reworked_tags", "reworked_blinds",
		"spectral_banned_enhancements", "stickers",
	},
}
MP.is_practice_mode = function() return false end
MP.GHOST = { is_active = function() return false end }
MP.Layer = function(name, def) MP.Layers[name] = def end
MP.UTILS = setmetatable({}, { __index = function() return function() return false end end })
copy_table = function(t) local o = {} for k, v in pairs(t) do o[k] = v end return o end

-- ─── Load the REAL mechanism ────────────────────────────────────────────────
local chunk, err = loadfile(RULESETS)
if not chunk then
	io.stderr:write("ERROR: cannot load " .. RULESETS .. " (run from repo root): " .. tostring(err) .. "\n")
	os.exit(1)
end
chunk()

-- Layers our subjects target + the rulesets that compose them.
for _, n in ipairs({ "standard", "classic", "sandbox", "release", "mod_glassbump" }) do MP.Layer(n, {}) end
local function ruleset(short, layer_order)
	MP.Rulesets["ruleset_mp_" .. short] = { key = "ruleset_mp_" .. short, _layer_order = layer_order }
end
ruleset("standard_ctx", { "standard" })
ruleset("classic_ctx", { "classic" })
ruleset("sandbox_ctx", { "sandbox" })
ruleset("release_ctx", { "release" })
ruleset("vanilla_ctx", {})
ruleset("chaos_ctx", { "standard", "classic", "sandbox", "release" })

-- (Re)register the shipped reworks against fresh centers, then drain into the
-- ledger via the real injectItems graft.
local function register_reworks()
	MP._REWORK_BASELINE, MP._REWORK_LEDGER, MP._REWORK_OWNED = {}, {}, {}
	MP.ReworkCenter("m_glass", { layers = { "standard", "classic" }, config = { Xmult = 1.5, extra = 4 } })
	MP.ReworkCenter("m_glass", { layers = "sandbox", config = { Xmult = 1.5, extra = 3 } })
	MP.ReworkCenter("j_sixth_sense", { layers = "release", rarity = 3 })
	MP.ReworkCenter("m_glass", { layers = "mod_glassbump", config = { extra = 9 } })
	SMODS.injectItems()
end

-- ─── Read helpers ───────────────────────────────────────────────────────────
local function glass() local c = G.P_CENTERS.m_glass.config return c.Xmult, c.extra, c.mp_balanced end
local function bucket_keys(b)
	local o = {}
	for i, c in ipairs(G.P_JOKER_RARITY_POOLS[b]) do o[i] = c.key end
	return table.concat(o, ",")
end
local function all_pools()
	local p = {}
	for b = 1, 4 do p[b] = "[" .. b .. "]" .. bucket_keys(b) end
	return table.concat(p, " | ")
end
local function set_live(short) MP.LOBBY.config.ruleset = short and ("ruleset_mp_" .. short) or nil end

-- Resolve m_glass (config) and the pools after `history`, finalized on `final`.
-- history = list of { preview=short } or { apply=short }.
local function resolve(history, final)
	G.P_CENTERS = fresh_centers()
	G.P_JOKER_RARITY_POOLS = { {}, {}, {}, {} }
	register_reworks()
	for _, step in ipairs(history) do
		if step.preview then
			MP.PreviewReworks("ruleset_mp_" .. step.preview)
		else
			set_live(step.apply)
			MP.ApplyReworks("ruleset_mp_" .. step.apply)
		end
	end
	set_live(final)
	MP.ApplyReworks("ruleset_mp_" .. final)
	local x, e = glass()
	return { glass = x .. "/" .. e, pools = all_pools(), rarity = G.P_CENTERS.j_sixth_sense.rarity }
end

-- ─── D1: effective props are a pure function of context ─────────────────────
local std = resolve({}, "standard_ctx")
check("standard => m_glass 1.5/4", std.glass == "1.5/4")
check("standard => mp_balanced set", (function() return select(3, glass()) end)())
check("sandbox => m_glass 1.5/3", resolve({}, "sandbox_ctx").glass == "1.5/3")
check("classic => m_glass 1.5/4", resolve({}, "classic_ctx").glass == "1.5/4")
check("vanilla => m_glass restored 2/5", resolve({}, "vanilla_ctx").glass == "2/5")

-- Same finalize context, hostile histories => identical result.
check("standard after preview(sandbox) == standard", resolve({ { preview = "sandbox_ctx" } }, "standard_ctx").glass == std.glass)
check("standard after apply(sandbox) == standard", resolve({ { apply = "sandbox_ctx" } }, "standard_ctx").glass == std.glass)
check("standard after menu-cycle previews == standard",
	resolve({ { preview = "classic_ctx" }, { preview = "sandbox_ctx" }, { preview = "vanilla_ctx" } }, "standard_ctx").glass == std.glass)
check("standard after apply(chaos) == standard", resolve({ { apply = "chaos_ctx" } }, "standard_ctx").glass == std.glass)
check("standard applied twice == standard", resolve({ { apply = "standard_ctx" } }, "standard_ctx").glass == std.glass)

-- ─── D2: rarity / pool-order desync-safety ───────────────────────────────────
local relA = resolve({}, "release_ctx")
local relB = resolve({
	{ preview = "standard_ctx" }, { apply = "sandbox_ctx" },
	{ preview = "vanilla_ctx" }, { apply = "standard_ctx" }, { preview = "release_ctx" },
}, "release_ctx")
check("release => sixth_sense rarity 3 (client A)", relA.rarity == 3)
check("release => sixth_sense rarity 3 (client B, hostile history)", relB.rarity == 3)
check("release => rarity pools byte-identical across histories (A==B)", relA.pools == relB.pools)
check("release => sixth_sense in bucket 3, not 1",
	bucket_keys(3):find("j_sixth_sense") and not bucket_keys(1):find("j_sixth_sense"))
check("WIP joker excluded from pools (vanilla `not v.wip`)", not all_pools():find("j_wip"))
check("demo joker excluded from pools (vanilla `not v.demo`)", not all_pools():find("j_demo"))
check("non-joker decoy excluded from pools (vanilla `set=='Joker'`)", not all_pools():find("c_decoy"))
check("equal-order jokers ordered by key tiebreak",
	(function() local b = bucket_keys(3) local p1, p2 = b:find("j_rare_tie1"), b:find("j_rare_tie2") return p1 and p2 and p1 < p2 end)())
check("release applied twice => pools unchanged (no incremental re-sort)",
	resolve({ { apply = "release_ctx" } }, "release_ctx").pools == relA.pools)
local van = resolve({ { apply = "release_ctx" }, { apply = "chaos_ctx" } }, "vanilla_ctx")
check("vanilla finalize after release/chaos => sixth_sense rarity back to 1", van.rarity == 1)
check("vanilla finalize => sixth_sense in bucket 1, not 3",
	bucket_keys(1):find("j_sixth_sense") and not bucket_keys(3):find("j_sixth_sense"))

-- ─── Preview isolation (asymmetric call-site fix) ───────────────────────────
G.P_CENTERS = fresh_centers()
G.P_JOKER_RARITY_POOLS = { {}, {}, {}, {} }
register_reworks()
local bx, be = glass()
local bpools = all_pools()
MP.PreviewReworks("ruleset_mp_chaos_ctx") -- would change live state if it leaked
local ax, ae = glass()
check("preview does not mutate live m_glass", ax == bx and ae == be)
check("preview does not mutate rarity pools", all_pools() == bpools)
local pv = MP.preview_center("m_glass")
check("preview_center surfaces projected config (1.5/3 under chaos)", pv.config.Xmult == 1.5 and pv.config.extra == 3)
check("preview_center falls through to live for untouched prop", pv.set == "Enhanced")
pv.config = { Xmult = 999 }
check("write through preview proxy never touches live center", G.P_CENTERS.m_glass.config.Xmult == 2)

-- ─── Phase guard ────────────────────────────────────────────────────────────
MP._PREVIEW_ACTIVE = true
check("ApplyReworks errors while a preview projection is live",
	not pcall(function() MP.ApplyReworks("ruleset_mp_standard_ctx") end))
MP._PREVIEW_ACTIVE = false

-- ─── Modifier folding + documented SP run-start modifier-drop ───────────────
-- A modifier reworking m_glass to extra 9 folds in only when its target IS the
-- live ruleset; the SP run-start path (lobby ruleset nil, SP.ruleset set,
-- practice=false) yields active=nil, so modifiers drop — matching the OLD
-- chain-based LoadReworks. Pinned so any future change is deliberate.
G.P_CENTERS = fresh_centers()
register_reworks()
set_live("standard_ctx")
MP.MODIFIERS = { "mod_glassbump" }
MP.ApplyReworks("ruleset_mp_standard_ctx") -- target == live
check("modifier folds when target == live ruleset (extra 9)", select(2, glass()) == 9)

G.P_CENTERS = fresh_centers()
MP.LOBBY.config.ruleset = nil
MP.SP.ruleset = "ruleset_mp_standard_ctx"
MP.MODIFIERS = { "mod_glassbump" }
MP.ApplyReworks(MP.LOBBY.config.ruleset or MP.SP.ruleset) -- mirrors game_state.lua
check("SP run-start drops modifiers (extra 4, not 9) — matches old behavior", select(2, glass()) == 4)
MP.MODIFIERS, MP.SP.ruleset, MP.LOBBY.config.ruleset = {}, nil, nil

-- ─── Frozen baseline immutability ───────────────────────────────────────────
G.P_CENTERS = fresh_centers()
register_reworks()
check("frozen baseline config snapshot rejects writes",
	not pcall(function() MP._REWORK_BASELINE.P_CENTERS.m_glass.config.value.Xmult = 7 end))

-- ─── Report ─────────────────────────────────────────────────────────────────
print(string.format("Rework determinism test: %d passed, %d failed", pass, fail))
if fail > 0 then
	print("\nFailures:")
	for _, f in ipairs(failures) do print("  " .. f) end
	os.exit(1)
end
print("All rework determinism + desync-safety checks passed.")
