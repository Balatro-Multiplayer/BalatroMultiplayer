--[[
  LOG_PARSER.carbon_to_replay round-trip test.

  Feeds a small array of {t, opcode, args} events (the shape a downloaded,
  JSON-decoded matchRunLogs block would have -- see lib/replay_log.lua's
  carbon opcode vocabulary and pvp_api/net.lua's hand_result recording) and
  asserts the resulting replay table matches exactly what ghost_replay.lua
  actually reads (see its consumption contract): ante_snapshots keyed by ante
  int, each with a hands[] array of {side, score, hands_left}.

  Run from the repo root:
    luajit tests/test_log_parser_carbon.lua
]]

local LOG_PARSER = dofile("lib/log_parser.lua")

-- ─── A two-ante run, single side ("enemy" -- as if downloaded to watch a peer) ─

local events = {
	{ t = 0, opcode = "manifest", args = { seed = "ABCD", ruleset = "ruleset_mp_blitz", gamemode = "gamemode_mp_attrition", deck = "Red Deck", stake = 2 } },
	{ t = 10, opcode = "select_blind", args = 0 },
	{ t = 20, opcode = "set_ante_key", args = "bl_small" },
	{ t = 100, opcode = "hand_result", args = { "12345", 3 } },
	{ t = 200, opcode = "hand_result", args = { "67890", 2 } },
	{ t = 300, opcode = "set_ante_key", args = "bl_big" },
	{ t = 400, opcode = "hand_result", args = { "111", 3 } },
	{ t = 500, opcode = "end", args = { result = "win" } },
}

local replay = LOG_PARSER.carbon_to_replay(events, { lobby_code = "ABCDE", nemesis_name = "Bob" }, "enemy")

assert(replay.seed == "ABCD", "seed=" .. tostring(replay.seed))
assert(replay.ruleset == "ruleset_mp_blitz", "ruleset=" .. tostring(replay.ruleset))
assert(replay.gamemode == "gamemode_mp_attrition", "gamemode=" .. tostring(replay.gamemode))
assert(replay.deck == "Red Deck", "deck=" .. tostring(replay.deck))
assert(replay.stake == 2, "stake=" .. tostring(replay.stake))
assert(replay.winner == "win", "winner=" .. tostring(replay.winner))
assert(replay.lobby_code == "ABCDE", "lobby_code=" .. tostring(replay.lobby_code))
assert(replay.nemesis_name == "Bob", "nemesis_name=" .. tostring(replay.nemesis_name))
assert(replay.final_ante == 2, "final_ante=" .. tostring(replay.final_ante))

local ante1 = replay.ante_snapshots[1]
assert(ante1, "missing ante 1 snapshot")
assert(#ante1.hands == 2, "expected 2 hands in ante 1, got " .. #ante1.hands)
assert(ante1.hands[1].side == "enemy" and ante1.hands[1].score == "12345" and ante1.hands[1].hands_left == 3, "ante1 hand 1 mismatch")
assert(ante1.hands[2].side == "enemy" and ante1.hands[2].score == "67890" and ante1.hands[2].hands_left == 2, "ante1 hand 2 mismatch")

local ante2 = replay.ante_snapshots[2]
assert(ante2, "missing ante 2 snapshot")
assert(#ante2.hands == 1, "expected 1 hand in ante 2, got " .. #ante2.hands)
assert(ante2.hands[1].score == "111" and ante2.hands[1].hands_left == 3, "ante2 hand mismatch")

assert(replay.ante_snapshots[3] == nil, "unexpected ante 3 snapshot")

-- ─── hand_result events before any set_ante_key are dropped, not mis-attributed ─

local no_ante_events = {
	{ t = 0, opcode = "manifest", args = { seed = "S", ruleset = "r", gamemode = "g", deck = "d", stake = 1 } },
	{ t = 5, opcode = "hand_result", args = { "999", 4 } },
}
local no_ante_replay = LOG_PARSER.carbon_to_replay(no_ante_events, nil, "player")
assert(next(no_ante_replay.ante_snapshots) == nil, "hand_result before any set_ante_key should not create a snapshot")
assert(no_ante_replay.final_ante == 1, "final_ante should default to 1 when no ante was ever entered")

-- ─── missing manifest/end frames fall back to the same defaults as to_replay ──

local bare_replay = LOG_PARSER.carbon_to_replay({}, nil, "player")
assert(bare_replay.seed == "UNKNOWN", "seed default=" .. tostring(bare_replay.seed))
assert(bare_replay.winner == "unknown", "winner default=" .. tostring(bare_replay.winner))
assert(bare_replay.deck == "Red Deck", "deck default=" .. tostring(bare_replay.deck))
assert(bare_replay.stake == 1, "stake default=" .. tostring(bare_replay.stake))

print("test_log_parser_carbon: OK")
