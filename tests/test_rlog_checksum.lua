--[[
  Replay-log (MP.RLOG) tamper-detection test.

  Verifies the CHK trailer's carbon hash equals a SHA-256 (via love.data.hash)
  over a canonical JSON re-encoding of the recorded {t, opcode, args} gameplay
  events (RLOG._structured_events) -- NOT the carbon text lines -- and that
  changing a single event's args changes the hash, i.e. the anti-cheat
  fingerprint catches a tampered log. This is the value the server
  independently recomputes and compares against at match-resolve time
  (matchmaking.service.ts's evaluateAntiCheat, Phase 8) -- see
  lib/replay_log.lua's canonical_hash_input/encode_event_tuple.

  Run from the repo root:
    lua tests/test_rlog_checksum.lua
]]

-- Minimal JSON encoder covering exactly what canonical_hash_input needs:
-- scalars and positional arrays (every RLOG.record args value in this
-- codebase is nil/scalar/array -- never a dict, see lib/replay_log.lua's
-- header comment). Dict-shaped tables (MANIFEST/END's payloads) fall back to
-- "{}" -- their exact content isn't asserted on by this test.
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

-- Deterministic stand-in for a real cryptographic hash -- this test is
-- checking canonicalization/wiring (the right bytes get hashed, tampering
-- changes the result), not LÖVE's SHA-256 implementation itself.
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

MP = {
	LOBBY = { code = "TEST" },
	ACTIONS = {},
	UTILS = {
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

-- Mirrors lib/replay_log.lua's private encode_event_tuple/canonical_hash_input
-- against RLOG._structured_events (a real, accessible module field, unlike
-- the local canonical_hash_input function itself) -- same pattern the
-- previous version of this test used for joker_hash.
local function canonical_hash_input(events)
	local parts = {}
	for _, ev in ipairs(events) do
		local args_json = ev.args == nil and "null" or json_encode(ev.args)
		parts[#parts + 1] = string.format("[%d,%s,%s]", ev.t, json_encode(ev.opcode), args_json)
	end
	return "[" .. table.concat(parts, ",") .. "]"
end

local function sha256_hex(str)
	return love.data.encode("string", "hex", love.data.hash("string", "sha256", str))
end

RLOG.begin_run({ seed = "S", ruleset = "r", gamemode = "g", deck = "d", stake = 1 })
RLOG.record("buy", { 1, 1 }, "action:boughtCardFromShop,card:X,cost:1")
RLOG.record("sell", { 4, 2 }, "action:soldCard,card:Y")
RLOG.record("select_blind", 0, "action:selectBlind,blind:bl_small") -- bare scalar args
local carbon_hash = RLOG.end_run({ result = "stop" })

-- The wire transport (pvp_api/replay_log_actions.lua's normalize_args, which
-- lib/ can't reference directly) wraps a bare-scalar args value into a
-- single-element array before broadcasting -- what the server ends up
-- buffering. _structured_events must already reflect that same wrapped shape
-- (see lib/replay_log.lua's normalize_for_hash), or a clean run's
-- server-recomputed hash would never match this client-computed one for any
-- bare-scalar opcode (select_blind, skip_blind, pack_skip, ready_blind,
-- set_ante_key).
local select_blind_ev = RLOG._structured_events[3]
assert(select_blind_ev.opcode == "select_blind", "expected select_blind at index 3")
assert(
	type(select_blind_ev.args) == "table" and select_blind_ev.args[1] == 0 and #select_blind_ev.args == 1,
	"bare scalar args must be normalized to a 1-element array before hashing"
)

local chk_carbon
for _, l in ipairs(captured) do
	chk_carbon = l:match("^MP_RLOG: CHK v1 carbon=(%x+)") or chk_carbon
end
assert(chk_carbon == carbon_hash, "CHK trailer carbon hash != end_run return")

local expected_hash = sha256_hex(canonical_hash_input(RLOG._structured_events))
assert(expected_hash == carbon_hash, "CHK carbon hash must equal SHA-256 of the canonical event-tuple JSON")

-- Framing opcodes never entered _structured_events (only RLOG.record pushes
-- to it; begin_run/end_run call emit_carbon directly) -- exactly the 3
-- gameplay events recorded above, nothing else.
assert(#RLOG._structured_events == 3, "expected exactly 3 gameplay events, got " .. #RLOG._structured_events)

-- Tamper: mutate the recorded "buy" event's slot index. The hash must change.
local tampered = {}
for i, ev in ipairs(RLOG._structured_events) do
	tampered[i] = { t = ev.t, opcode = ev.opcode, args = ev.args }
end
tampered[1].args = { 1, 2 } -- was {1, 1}
local tampered_hash = sha256_hex(canonical_hash_input(tampered))
assert(tampered_hash ~= carbon_hash, "tampered stream must not match the stored hash")

print("test_rlog_checksum: OK")
