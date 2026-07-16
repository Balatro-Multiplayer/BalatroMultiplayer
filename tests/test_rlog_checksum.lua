--[[
  Replay-log (MP.RLOG) tamper-detection test.

  Verifies the CHK trailer's carbon hash equals a hash over the carbon
  (positional) stream as re-extracted from the log by its "MP_RLOG:" prefix, and
  that editing a single opcode changes the hash -- i.e. the cheap end-of-game
  fingerprint catches a tampered log. (joker_hash is not collision-resistant;
  this guards against casual edits, not a determined forger who also fixes the
  hash -- see lib/replay_log.lua.)

  Run from the repo root:
    lua tests/test_rlog_checksum.lua
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

RLOG.begin_run({ seed = "S", ruleset = "r", gamemode = "g", deck = "d", stake = 1 })
RLOG.record("buy", { 1, 1 }, "action:boughtCardFromShop,card:X,cost:1")
RLOG.record("sell", { 4, 2 }, "action:soldCard,card:Y")
local carbon_hash = RLOG.end_run({ result = "stop" })

-- Re-extract the carbon (positional) stream from the log by prefix: action
-- lines are "MP_RLOG: <t> ...", excluding MANIFEST/END/CHK. This is the domain.
-- `t` here is 1, 2, ... because love.timer isn't stubbed in this test, so
-- RLOG falls back to a plain incrementing counter (see lib/replay_log.lua's
-- elapsed_ms) -- same numbers as the old sequence counter, by design.
local carbon_lines = {}
local chk_carbon
for _, l in ipairs(captured) do
	if l:match("^MP_RLOG: %d") then
		carbon_lines[#carbon_lines + 1] = l
	end
	chk_carbon = l:match("^MP_RLOG: CHK v1 carbon=(%x+)") or chk_carbon
end

local original = table.concat(carbon_lines, "\n")
assert(chk_carbon == carbon_hash, "CHK trailer carbon hash != end_run return")
assert(MP.UTILS.joker_hash(original) == carbon_hash, "CHK carbon hash must equal hash of the carbon stream")

-- Tamper: buying slot 1 instead becomes slot 2. The hash must change.
local tampered = original:gsub("1 buy 1 1", "1 buy 1 2", 1)
assert(tampered ~= original, "tamper precondition failed (pattern not found)")
assert(MP.UTILS.joker_hash(tampered) ~= carbon_hash, "tampered stream must not match the stored hash")

print("test_rlog_checksum: OK")
