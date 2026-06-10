--[[
  Replay-log (MP.RLOG) round-trip test.

  Drives lib/replay_log.lua with stubbed globals, captures the lines it emits to
  the Lovely log, and asserts the dual stream is well-formed: a MANIFEST header
  and END + CHK trailer under the "MP_RLOG:" carbon prefix; carbon action lines
  with a gapless monotonic sequence; positional args (including ordered index-
  lists) intact; a paired human "Client sent message:" line per action; and CHK
  per-stream hashes that equal a recompute over the captured lines and match
  what was submitted to the server.

  Run from the repo root:
    lua tests/test_rlog_roundtrip.lua
]]

package.loaded["json"] = {
	encode = function()
		return "{}"
	end,
}

local captured = {}
function sendTraceMessage(msg)
	captured[#captured + 1] = msg
end
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

-- ─── Parse the captured log lines ───────────────────────────────────────────

assert(captured[1]:match("^MP_RLOG: MANIFEST {"), "first line must be MANIFEST, got: " .. tostring(captured[1]))
assert(captured[#captured - 1]:match("^MP_RLOG: END {"), "penultimate must be END, got: " .. tostring(captured[#captured - 1]))
assert(
	captured[#captured]:match("^MP_RLOG: CHK v1 carbon=%x+ human=%x+ bytes=%d+$"),
	"bad CHK: " .. tostring(captured[#captured])
)

local A = {} -- seq -> arg string
local carbon_lines, human_lines = {}, {} -- in-order full lines (the hash domains)
local last_seq = 0
for _, l in ipairs(captured) do
	local s, rest = l:match("^MP_RLOG: (%d+) (.+)$")
	if s then
		s = tonumber(s)
		A[s] = rest
		carbon_lines[#carbon_lines + 1] = l
		assert(s == last_seq + 1, "carbon sequence not gapless/monotonic at " .. s)
		last_seq = s
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

-- Hash domains: CHK values must equal a recompute over the in-order carbon /
-- human lines (exactly what gets re-extracted from a log by prefix).
local chk_carbon, chk_human = captured[#captured]:match("carbon=(%x+) human=(%x+)")
assert(chk_carbon == MP.UTILS.joker_hash(table.concat(carbon_lines, "\n")), "carbon hash domain mismatch")
assert(chk_human == MP.UTILS.joker_hash(table.concat(human_lines, "\n")), "human hash domain mismatch")
assert(carbon_hash == chk_carbon and human_hash == chk_human, "end_run return != CHK trailer")

-- The same hashes are what we send to the server, with the seed for keying.
assert(submitted, "hashes not submitted to server")
assert(submitted.carbon == carbon_hash and submitted.human == human_hash, "submitted hashes mismatch")
assert(submitted.seed == "ABCD", "seed not forwarded to server")

print("test_rlog_roundtrip: OK")
