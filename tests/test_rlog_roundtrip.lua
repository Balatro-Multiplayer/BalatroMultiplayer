--[[
  Replay-log (MP.RLOG) round-trip test.

  Drives lib/replay_log.lua with stubbed globals, captures the lines it emits to
  the Lovely log, and asserts the dual stream is well-formed: a MANIFEST header
  (carrying schema_version/api_version/start_epoch_ms) and END + CHK trailer
  under the "MP_RLOG:" carbon prefix; carbon action lines tagged with `t`
  (milliseconds elapsed since the run began -- monotonically non-decreasing,
  not necessarily gapless once a real clock is involved); positional args
  (including ordered index-lists) intact; a paired human "Client sent message:"
  line per action; and CHK per-stream hashes that equal a recompute over the
  captured lines. (The live MPAPI broadcast side of the transport --
  RLOG.broadcast_event, installed by pvp_api/replay_log_actions.lua -- is
  covered separately by test_rlog_stream.lua; this test is local-log-only.)

  Two scenarios are run: (1) no love.timer stubbed, so `t` falls back to a
  plain incrementing counter (1, 2, 3, ...) -- this is what most of the
  assertions below check, since it gives predictable exact values; (2) a
  stubbed love.timer.getTime, to confirm the real elapsed-ms math itself.

  Run from the repo root:
    lua tests/test_rlog_roundtrip.lua
]]

-- Handles exactly what canonical_hash_input needs (scalars + positional,
-- possibly nested, arrays -- every RLOG.record args value in this codebase,
-- see lib/replay_log.lua's header comment); dict-shaped tables (MANIFEST/
-- END's payloads) fall back to "{}", not asserted on by this test.
local function json_encode(v)
	local t = type(v)
	if t == "number" then return tostring(v) end
	if t == "string" then return '"' .. v .. '"' end
	if t == "table" then
		if #v > 0 or next(v) == nil then
			local parts = {}
			for _, item in ipairs(v) do
				parts[#parts + 1] = json_encode(item)
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		return "{}"
	end
	error("json_encode stub: unsupported type " .. t)
end
package.loaded["json"] = { encode = json_encode }

local captured = {}
function sendTraceMessage(msg)
	captured[#captured + 1] = msg
end
function sendWarnMessage() end

-- Deterministic stand-in for a real cryptographic hash -- this test checks
-- wiring/canonicalization (the right bytes get hashed, into the right CHK
-- field), not LÖVE's SHA-256 implementation itself.
local function stub_hash_bytes(str)
	local a, b = 1, 0
	for i = 1, #str do
		a = (a + str:byte(i)) % 65521
		b = (b + a) % 65521
	end
	local v = b * 65536 + a
	return string.char(
		math.floor(v / 16777216) % 256,
		math.floor(v / 65536) % 256,
		math.floor(v / 256) % 256,
		v % 256
	)
end

-- Declared up front (not local) so scenario 2 can add .timer onto the same
-- table without dropping .data -- RLOG.end_run needs love.data in both scenarios.
love = {
	data = {
		hash = function(container, algorithm, data)
			assert(container == "string", "expected string container")
			assert(algorithm == "sha256", "expected sha256")
			return stub_hash_bytes(data)
		end,
		encode = function(container, format, data)
			assert(container == "string", "expected string container")
			assert(format == "hex", "expected hex format")
			local hex = {}
			for i = 1, #data do
				hex[#hex + 1] = string.format("%02x", data:byte(i))
			end
			return table.concat(hex)
		end,
	},
}

local function sha256_hex(str)
	return love.data.encode("string", "hex", love.data.hash("string", "sha256", str))
end

local function canonical_hash_input(events)
	local parts = {}
	for _, ev in ipairs(events) do
		local args_json = ev.args == nil and "null" or json_encode(ev.args)
		parts[#parts + 1] = string.format("[%d,%s,%s]", ev.t, json_encode(ev.opcode), args_json)
	end
	return "[" .. table.concat(parts, ",") .. "]"
end

MP = {
	LOBBY = { code = "TEST" },
	UTILS = {
		-- Real Adler-style hash from lib/crypto.lua so the domain matches prod.
		joker_hash = function(s)
			local a, b = 1, 0
			for i = 1, #s do
				a = (a + s:byte(i)) % 65521
				b = (b + a) % 65521
			end
			return string.format("%08x", b * 65536 + a)
		end,
	},
}

dofile("lib/replay_log.lua")
local RLOG = assert(MP.RLOG, "MP.RLOG not defined after load")

-- ─── Drive a run (scenario 1: no love.timer, fallback counter) ─────────────

RLOG.begin_run({ seed = "ABCD", ruleset = "r", gamemode = "g", deck = "Red Deck", stake = 1 })

-- begin_run must stamp these itself -- not required from the caller.
assert(RLOG._manifest.schema_version == RLOG.SCHEMA_VERSION, "schema_version not stamped")
assert(RLOG._manifest.start_epoch_ms and RLOG._manifest.start_epoch_ms > 0, "start_epoch_ms not stamped")
-- api_version is nil here since SMODS.Mods isn't stubbed -- just confirm it doesn't error.

RLOG.record("select_blind", 0, "action:selectBlind,blind:bl_small")
RLOG.record("buy", { 1, 2 }, "action:boughtCardFromShop,card:Blueprint,cost:4")
RLOG.record("play", { { 1, 3, 5, 7, 8 } }, "action:play,cards:1.3.5.7.8")
RLOG.record("use", { 1, { 2, 4 } }, "action:usedCard,card:The Tower")
RLOG.record("reroll", nil, "action:rerollShop,cost:5")
local carbon_hash, human_hash = RLOG.end_run({ result = "win" })

-- ─── Parse the captured log lines ───────────────────────────────────────────

assert(captured[1]:match("^MP_RLOG: MANIFEST {"), "first line must be MANIFEST, got: " .. tostring(captured[1]))
assert(captured[#captured - 1]:match("^MP_RLOG: END {"), "penultimate must be END, got: " .. tostring(captured[#captured - 1]))
assert(
	captured[#captured]:match("^MP_RLOG: CHK v1 carbon=%x+ human=%x+ bytes=%d+$"),
	"bad CHK: " .. tostring(captured[#captured])
)

local A = {} -- t -> arg string
local carbon_lines, human_lines = {}, {} -- in-order full lines (the hash domains)
local last_t = 0
for _, l in ipairs(captured) do
	local s, rest = l:match("^MP_RLOG: (%d+) (.+)$")
	if s then
		s = tonumber(s)
		A[s] = rest
		carbon_lines[#carbon_lines + 1] = l
		-- No love.timer stubbed -> elapsed_ms() falls back to a plain incrementing
		-- counter, so this scenario still expects exact gapless values (1, 2, 3, ...).
		assert(s == last_t + 1, "fallback counter not gapless/monotonic at " .. s)
		last_t = s
	end
	local payload = l:match("^Client sent message: (.+)$")
	if payload then
		human_lines[#human_lines + 1] = l
	end
end

-- ─── Assertions ─────────────────────────────────────────────────────────────

assert(A[1] == "select_blind 0", "A1=" .. tostring(A[1]))
assert(A[2] == "buy 1 2", "A2=" .. tostring(A[2]))
assert(A[3] == "play 1.3.5.7.8", "A3=" .. tostring(A[3])) -- ordered index-list preserved
assert(A[4] == "use 1 2.4", "A4=" .. tostring(A[4])) -- target index-list preserved
assert(A[5] == "reroll", "A5=" .. tostring(A[5])) -- nil args -> bare opcode
assert(A[6] == nil, "unexpected extra carbon action line")

assert(#human_lines == 5, "expected 5 human lines, got " .. #human_lines)
assert(human_lines[2] == "Client sent message: action:boughtCardFromShop,card:Blueprint,cost:4", "H2=" .. human_lines[2])

-- Hash domains: carbon's CHK value must equal a recompute over
-- RLOG._structured_events' canonical tuple JSON (not the text lines --
-- see lib/replay_log.lua); human's must equal a recompute over the in-order
-- human lines (exactly what gets re-extracted from a log by prefix).
local chk_carbon, chk_human = captured[#captured]:match("carbon=(%x+) human=(%x+)")
assert(chk_carbon == sha256_hex(canonical_hash_input(RLOG._structured_events)), "carbon hash domain mismatch")
assert(chk_human == MP.UTILS.joker_hash(table.concat(human_lines, "\n")), "human hash domain mismatch")
assert(carbon_hash == chk_carbon and human_hash == chk_human, "end_run return != CHK trailer")

-- ─── Scenario 2: real elapsed-ms math via a stubbed love.timer ─────────────

captured = {}
local clock = 100.0 -- love.timer.getTime() is a monotonic float in seconds
love.timer = { getTime = function() return clock end } -- .data stays intact, end_run still needs it

RLOG.begin_run({ seed = "EFGH", ruleset = "r", gamemode = "g", deck = "Red Deck", stake = 1 })
RLOG.record("select_blind", 0) -- t=0
clock = clock + 0.25
RLOG.record("play", nil) -- t=250
clock = clock + 1.5
RLOG.record("reroll", nil) -- t=1750
RLOG.end_run({ result = "stop" })

local clock_lines = {}
for _, l in ipairs(captured) do
	local t = l:match("^MP_RLOG: (%d+) ")
	if t then clock_lines[#clock_lines + 1] = tonumber(t) end
end
assert(clock_lines[1] == 0, "expected t=0 for the first event, got " .. tostring(clock_lines[1]))
assert(clock_lines[2] == 250, "expected t=250 (250ms later), got " .. tostring(clock_lines[2]))
assert(clock_lines[3] == 1750, "expected t=1750 (1.5s later), got " .. tostring(clock_lines[3]))
love = nil -- don't leak the stub into anything after this file

print("test_rlog_roundtrip: OK")
