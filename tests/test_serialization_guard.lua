--[[
  Serialization zip-bomb guard test.

  Exercises MP.UTILS.str_decode_and_unpack's size guard (lib/serialization.lua):
  an over-large encoded payload must be rejected BEFORE any base64/gzip work, a
  non-string must be rejected, and a normal small payload must still round-trip.
  Also covers MP.UTILS.compress_str/decompress_str (the plain-string codec RLOG
  uses for its finalized carbon block, see lib/replay_log.lua).

  love.data and STR_PACK are stubbed with identity codecs so the test runs under
  plain Lua (the guard logic is what we're covering, not love's real codecs).

  Run from the repo root:
    lua tests/test_serialization_guard.lua
]]

MP = { UTILS = {} }

-- Track whether the heavy decode path was entered, so we can prove the guard
-- short-circuits before spending any CPU on an oversized payload.
local decode_calls = 0

love = {
	data = {
		decode = function(_container, _fmt, s)
			decode_calls = decode_calls + 1
			return s
		end,
		decompress = function(_container, _fmt, s)
			return s
		end,
		compress = function(_container, _fmt, s)
			return s
		end,
		encode = function(_container, _fmt, s)
			return s
		end,
	},
}

-- Minimal STR_PACK for a flat table of string/number values -> "return { ... }".
function STR_PACK(data)
	local parts = {}
	for k, v in pairs(data) do
		local key = string.format("[%q]", k)
		local val = type(v) == "number" and tostring(v) or string.format("%q", v)
		parts[#parts + 1] = key .. "=" .. val
	end
	return "return {" .. table.concat(parts, ",") .. "}"
end

dofile("lib/serialization.lua")

local failures = 0
local function check(name, cond)
	if cond then
		print("ok   - " .. name)
	else
		failures = failures + 1
		print("FAIL - " .. name)
	end
end

-- ─── 1. Oversized payload is rejected before any decode work ──────────────────
decode_calls = 0
local big = string.rep("A", MP.UTILS.MAX_ENCODED_BYTES + 1)
local res, err = MP.UTILS.str_decode_and_unpack(big)
check("oversized payload returns nil", res == nil)
check("oversized payload reports 'too large'", type(err) == "string" and err:find("too large") ~= nil)
check("oversized payload never reached love.data.decode", decode_calls == 0)

-- ─── 2. Non-string payload is rejected ───────────────────────────────────────
local res2 = MP.UTILS.str_decode_and_unpack({ not_a = "string" })
check("non-string payload returns nil", res2 == nil)

-- ─── 3. A normal small payload still round-trips ─────────────────────────────
local original = { name = "Blueprint", cost = 10 }
local encoded = MP.UTILS.str_pack_and_encode(original)
check("normal payload is under the cap", #encoded <= MP.UTILS.MAX_ENCODED_BYTES)
local decoded = MP.UTILS.str_decode_and_unpack(encoded)
check("normal payload round-trips", type(decoded) == "table" and decoded.name == "Blueprint" and decoded.cost == 10)

-- ─── 4. compress_str/decompress_str round-trip a plain string ────────────────
-- (no STR_PACK table-serialization step -- the input IS already a string, e.g.
-- an RLOG carbon block, so the codec is just gzip+base64 with nothing else.)
local carbon_block = "MP_RLOG: MANIFEST {}\nMP_RLOG: 0 select_blind 0\nMP_RLOG: 250 buy 1 2"
local packed = MP.UTILS.compress_str(carbon_block)
check("compress_str returns a string", type(packed) == "string")
local unpacked, err2 = MP.UTILS.decompress_str(packed)
check("decompress_str round-trips the exact original string", unpacked == carbon_block)
local bad, bad_err = MP.UTILS.decompress_str({ not_a = "string" })
check("decompress_str rejects a non-string payload", bad == nil and type(bad_err) == "string")

if failures > 0 then
	error(failures .. " check(s) failed")
end
print("\nAll serialization guard checks passed.")
