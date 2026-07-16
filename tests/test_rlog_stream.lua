--[[
  Replay-log (MP.RLOG) live-transport test.

  Verifies the live transport layer: every carbon-stream event (manifest,
  actions, END, CHK) triggers exactly one RLOG.broadcast_event call, in order,
  with matching (t, opcode, args) -- no batching, one broadcast per event, so a
  server-side buffer or spectator sees each line as it happens. In the real
  mod this hook is installed by pvp_api/replay_log_actions.lua (loaded after
  lib/replay_log.lua); this test stubs it directly to isolate RLOG's own side
  of the contract.

  Run from the repo root:
    lua tests/test_rlog_stream.lua
]]

package.loaded["json"] = {
	encode = function()
		return "{}"
	end,
}

local traced = {}
function sendTraceMessage(msg)
	traced[#traced + 1] = msg
end
function sendWarnMessage() end

local broadcasts = {} -- { {t=, opcode=, args=}, ... } in call order
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

-- Stub what pvp_api/replay_log_actions.lua would normally install.
function RLOG.broadcast_event(t, opcode, args)
	broadcasts[#broadcasts + 1] = { t = t, opcode = opcode, args = args }
end

RLOG.begin_run({ seed = "S", ruleset = "r", gamemode = "g", deck = "d", stake = 1 })
RLOG.record("buy", { 1, 1 }, "action:boughtCardFromShop,card:X,cost:1")
RLOG.record("sell", { 4, 2 }, "action:soldCard,card:Y")
RLOG.record("reroll", nil, "action:rerollShop,cost:5")
RLOG.end_run({ result = "stop" })

-- ── One broadcast per carbon line, no batching ───────────────────────────────
local carbon_traced = {}
for _, m in ipairs(traced) do
	if m:match("^MP_RLOG:") then carbon_traced[#carbon_traced + 1] = m end
end
assert(
	#broadcasts == #carbon_traced,
	string.format("expected one broadcast per carbon line: %d broadcasts, %d lines", #broadcasts, #carbon_traced)
)

-- ── Framing events use the reserved opcodes, in order, with real payloads ───
assert(broadcasts[1].opcode == "manifest", "first broadcast must be the manifest frame")
assert(broadcasts[1].t == 0, "manifest frame should broadcast at t=0")
assert(type(broadcasts[1].args) == "table" and broadcasts[1].args.seed == "S", "manifest args must be the real manifest table")

assert(broadcasts[#broadcasts].opcode == "chk", "last broadcast must be the CHK frame")
assert(type(broadcasts[#broadcasts].args) == "table" and broadcasts[#broadcasts].args.carbon, "chk args must carry the hash")

assert(broadcasts[#broadcasts - 1].opcode == "end", "second-to-last broadcast must be the END frame")
assert(broadcasts[#broadcasts - 1].args.result == "stop", "end args must be the real outcome table")

-- ── Ordinary actions broadcast with their real opcode/args, `t` non-decreasing ─
assert(broadcasts[2].opcode == "buy" and broadcasts[2].args[1] == 1 and broadcasts[2].args[2] == 1, "buy broadcast mismatch")
assert(broadcasts[3].opcode == "sell", "sell broadcast mismatch")
assert(broadcasts[4].opcode == "reroll" and broadcasts[4].args == nil, "reroll (nil args) broadcast mismatch")

local last_t = -1
for _, b in ipairs(broadcasts) do
	assert(b.t >= last_t, "t must be monotonically non-decreasing across broadcasts")
	last_t = b.t
end

print("test_rlog_stream: OK")
