--[[
  Replay-log (MP.RLOG) tamper-detection test.

  Verifies that the CHK trailer's carbon hash equals a hash over the carbon
  (positional) stream, and that editing a single opcode changes the hash -- i.e.
  the cheap end-of-game fingerprint catches a tampered log. (joker_hash is not
  collision-resistant; this guards against casual edits, not a determined forger
  who also fixes the hash -- see lib/replay_log.lua.)

  Run from the repo root:
    lua tests/test_rlog_checksum.lua
]]

package.loaded["json"] = { encode = function() return "{}" end }

local CARBON_LOG = "tests/_rlog_checksum.log"
local CARBON_FILE = "tests/_rlog_checksum.carbon"
package.loaded["lovely"] = { log_path = CARBON_LOG }

function sendTraceMessage() end
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

os.remove(CARBON_FILE)
dofile("lib/replay_log.lua")
local RLOG = assert(MP.RLOG, "MP.RLOG not defined after load")

RLOG.begin_run({ seed = "S", ruleset = "r", gamemode = "g", deck = "d", stake = 1 })
RLOG.record("buy", { 1, 1 }, "action:boughtCardFromShop,card:X,cost:1")
RLOG.record("sell", { 4, 2 }, "action:soldCard,card:Y")
local carbon_hash = RLOG.end_run({ result = "stop" })

local f = assert(io.open(CARBON_FILE, "r"), "carbon file not written")
local content = f:read("*a")
f:close()

-- Reconstruct the carbon (A-line) stream in order -- this is the hash domain.
local A_full = {}
local chk_carbon
for line in content:gmatch("[^\n]+") do
	if line:match("^A ") then
		A_full[#A_full + 1] = line
	end
	chk_carbon = line:match("^CHK v1 carbon=(%x+)") or chk_carbon
end

local original = table.concat(A_full, "\n")
assert(chk_carbon == carbon_hash, "CHK trailer carbon hash != end_run return")
assert(MP.UTILS.joker_hash(original) == carbon_hash, "CHK carbon hash must equal hash of the A-line stream")

-- Tamper: buying slot 1 instead becomes slot 2. The hash must change.
local tampered = original:gsub("buy 1 1", "buy 1 2", 1)
assert(tampered ~= original, "tamper precondition failed (pattern not found)")
assert(MP.UTILS.joker_hash(tampered) ~= carbon_hash, "tampered stream must not match the stored hash")

os.remove(CARBON_FILE)
print("test_rlog_checksum: OK")
