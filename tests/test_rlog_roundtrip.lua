--[[
  Replay-log (MP.RLOG) round-trip test.

  Drives lib/replay_log.lua with stubbed globals, writes a real .carbon file to
  tests/, parses it back, and asserts the dual stream is well-formed: manifest +
  trailer present, A/H lines paired by a gapless monotonic sequence, positional
  args (including ordered index-lists) round-trip exactly, and the CHK trailer's
  per-stream hashes equal a recompute over the parsed lines and match what was
  submitted to the server.

  Run from the repo root:
    lua tests/test_rlog_roundtrip.lua
]]

-- ─── Stubs ──────────────────────────────────────────────────────────────────

-- Minimal deterministic encoder; the test manifest/outcome are flat scalars.
package.loaded["json"] = {
	encode = function(t)
		local keys = {}
		for k in pairs(t) do keys[#keys + 1] = k end
		table.sort(keys)
		local parts = {}
		for _, k in ipairs(keys) do
			local v = t[k]
			local vs
			if type(v) == "string" then
				vs = '"' .. v .. '"'
			elseif type(v) == "table" then
				vs = "{}"
			else
				vs = tostring(v)
			end
			parts[#parts + 1] = '"' .. k .. '":' .. vs
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end,
}

local CARBON_LOG = "tests/_rlog_roundtrip.log"
local CARBON_FILE = "tests/_rlog_roundtrip.carbon"
package.loaded["lovely"] = { log_path = CARBON_LOG }

function sendTraceMessage() end
function sendWarnMessage() end

local submitted
MP = {
	LOBBY = { code = "TEST" },
	ACTIONS = {
		submit_log_hashes = function(c, h, seed)
			submitted = { carbon = c, human = h, seed = seed }
		end,
	},
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

os.remove(CARBON_FILE)
dofile("lib/replay_log.lua")

local RLOG = assert(MP.RLOG, "MP.RLOG not defined after load")

-- ─── Drive a run ────────────────────────────────────────────────────────────

RLOG.begin_run({ seed = "ABCD", ruleset = "r", gamemode = "g", deck = "Red Deck", stake = 1 })
RLOG.record("select_blind", 0, "action:selectBlind,blind:bl_small")
RLOG.record("buy", { 1, 2 }, "action:boughtCardFromShop,card:Blueprint,cost:4")
RLOG.record("play", { { 1, 3, 5, 7, 8 } }, "action:play,cards:1.3.5.7.8")
RLOG.record("use", { 1, { 2, 4 } }, "action:usedCard,card:The Tower")
RLOG.record("reroll", nil, "action:rerollShop,cost:5")
local carbon_hash, human_hash = RLOG.end_run({ result = "win" })

-- ─── Read + parse the carbon file ───────────────────────────────────────────

local f = assert(io.open(CARBON_FILE, "r"), "carbon file not written")
local content = f:read("*a")
f:close()

local lines = {}
for line in content:gmatch("[^\n]+") do
	lines[#lines + 1] = line
end

assert(lines[1]:match("^MANIFEST {"), "first line must be MANIFEST, got: " .. tostring(lines[1]))
assert(lines[#lines - 1]:match("^END {"), "penultimate line must be END, got: " .. tostring(lines[#lines - 1]))
assert(lines[#lines]:match("^CHK v1 carbon=%x+ human=%x+ bytes=%d+$"), "bad CHK: " .. tostring(lines[#lines]))

local A, H = {}, {} -- seq -> arg string / human payload
local A_full, H_full = {}, {} -- in-order full lines (the hash domain)
local last_seq = 0
for _, l in ipairs(lines) do
	local s, rest = l:match("^A (%d+) (.+)$")
	if s then
		s = tonumber(s)
		A[s] = rest
		A_full[#A_full + 1] = l
		assert(s == last_seq + 1, "A sequence not gapless/monotonic at " .. s)
		last_seq = s
	end
	local hs, hrest = l:match("^H (%d+) (.+)$")
	if hs then
		H[tonumber(hs)] = hrest
		H_full[#H_full + 1] = l
	end
end

-- ─── Assertions ─────────────────────────────────────────────────────────────

assert(A[1] == "select_blind 0", "A1=" .. tostring(A[1]))
assert(A[2] == "buy 1 2", "A2=" .. tostring(A[2]))
assert(A[3] == "play 1.3.5.7.8", "A3=" .. tostring(A[3])) -- ordered index-list preserved
assert(A[4] == "use 1 2.4", "A4=" .. tostring(A[4])) -- target index-list preserved
assert(A[5] == "reroll", "A5=" .. tostring(A[5])) -- nil args -> bare opcode
assert(A[6] == nil, "unexpected extra A line")

for i = 1, 5 do
	assert(H[i], "missing paired H line for seq " .. i)
end
assert(H[2] == "action:boughtCardFromShop,card:Blueprint,cost:4", "H2=" .. tostring(H[2]))

-- Hash domains: CHK values must equal a recompute over the in-order A / H lines.
local chk_carbon, chk_human = lines[#lines]:match("carbon=(%x+) human=(%x+)")
assert(chk_carbon == MP.UTILS.joker_hash(table.concat(A_full, "\n")), "carbon hash domain mismatch")
assert(chk_human == MP.UTILS.joker_hash(table.concat(H_full, "\n")), "human hash domain mismatch")
assert(carbon_hash == chk_carbon and human_hash == chk_human, "end_run return != CHK trailer")

-- The same hashes are what we send to the server, with the seed for keying.
assert(submitted, "hashes not submitted to server")
assert(submitted.carbon == carbon_hash and submitted.human == human_hash, "submitted hashes mismatch")
assert(submitted.seed == "ABCD", "seed not forwarded to server")

os.remove(CARBON_FILE)
print("test_rlog_roundtrip: OK")
