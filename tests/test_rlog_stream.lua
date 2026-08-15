--[[
  Replay-log (MP.RLOG) live-stream test.

  Verifies the in-game streaming layer: carbon lines are flushed to the server
  in batches under a stable per-game id, every carbon line is streamed (manifest
  + actions + END + CHK), and the final submit_log_hashes carries the same
  game id (so the server can swap the live stream for the complete package).

  Uses a tiny flush threshold to force several batches. love.timer is absent, so
  flushing falls back to the line-count trigger plus the end-of-run flush.

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

local streamed = {} -- flat list of every streamed line, in order
local stream_game_ids = {} -- game id seen on each batch
local submitted
MP = {
	LOBBY = { code = "TEST" },
	ACTIONS = {
		stream_log_lines = function(game_id, lines)
			stream_game_ids[#stream_game_ids + 1] = game_id
			for _, l in ipairs(lines) do
				streamed[#streamed + 1] = l
			end
		end,
		submit_log_hashes = function(carbon, human, seed, log, game_id)
			submitted = { carbon = carbon, human = human, seed = seed, log = log, game_id = game_id }
		end,
	},
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
RLOG.STREAM_FLUSH_LINES = 2 -- force a flush every couple of lines
RLOG.STREAM_FLUSH_SECS = 1e9 -- disable the time-based trigger for the test

RLOG.begin_run({ seed = "S", ruleset = "r", gamemode = "g", deck = "d", stake = 1 })
RLOG.record("buy", { 1, 1 }, "action:boughtCardFromShop,card:X,cost:1")
RLOG.record("sell", { 4, 2 }, "action:soldCard,card:Y")
RLOG.record("reroll", nil, "action:rerollShop,cost:5")
RLOG.end_run({ result = "stop" })

-- ── Game id: present, stable across batches, matches the final submit ────────
assert(#stream_game_ids > 0, "no live batches were streamed")
local gid = stream_game_ids[1]
assert(type(gid) == "string" and #gid > 0, "game id missing/empty")
for _, g in ipairs(stream_game_ids) do
	assert(g == gid, "game id changed between batches")
end
assert(submitted, "submit_log_hashes was not called")
assert(submitted.game_id == gid, "final submit did not carry the streamed game id")

-- ── Batching actually happened (threshold of 2 ⇒ multiple flushes) ───────────
assert(#stream_game_ids >= 2, "expected multiple batches with flush-lines=2")

-- ── Every carbon line was streamed, in order (manifest + actions + END + CHK) ─
local carbon_traced = {}
for _, m in ipairs(traced) do
	if m:match("^MP_RLOG:") then
		carbon_traced[#carbon_traced + 1] = m
	end
end
assert(
	#streamed == #carbon_traced,
	string.format("streamed %d lines but carbon block has %d", #streamed, #carbon_traced)
)
for i = 1, #carbon_traced do
	assert(streamed[i] == carbon_traced[i], "streamed line mismatch at index " .. i)
end
assert(carbon_traced[1]:match("^MP_RLOG: MANIFEST "), "first streamed line must be the manifest")
assert(carbon_traced[#carbon_traced]:match("^MP_RLOG: CHK "), "last streamed line must be the CHK trailer")

print("test_rlog_stream: OK")
