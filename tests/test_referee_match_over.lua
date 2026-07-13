--[[
  Referee match-over guard test.

  Drives pvp_api/referee.lua with stubbed MPAPI/network seams through: a normal
  round life loss (no match end), a second life loss that brings the loser to
  0 lives (match end, pvp_win must broadcast), then 3+ further stray play_hand
  events (loopback duplicates / play_hand(chips,0) / play_hand(0,0) style
  re-triggers that happen in practice near match end) that must NOT re-broadcast
  pvp_win. Also asserts a fresh MP.referee_reset() clears the match_over flag so
  the next match can broadcast its own single pvp_win.

  Run from the repo root:
    luajit tests/test_referee_match_over.lua
]]

MP = {
	LOBBY = { config = { starting_lives = 2 } },
}

-- Real (pure) InsaneInt module, plus its one MP.UTILS dependency.
MP.UTILS = {
	string_split = function(inputstr, sep)
		if sep == nil then
			sep = "%s"
		end
		local t = {}
		for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
			table.insert(t, str)
		end
		return t
	end,
}
dofile("lib/insane_int.lua")

-- ─── Stub the MQTT lobby/action seam ────────────────────────────────────────

local broadcasts = {} -- { {key=..., params=...}, ... }

MPAPI = {
	ActionTypes = setmetatable({}, {
		__index = function(_, k)
			return k
		end,
	}),
}

local fake_lobby = {
	is_host = true,
	players = { { id = "p1" }, { id = "p2" } },
}
function fake_lobby:get_players()
	return self.players
end
function fake_lobby:action(action_type)
	return {
		broadcast = function(_, params)
			broadcasts[#broadcasts + 1] = { key = action_type, params = params }
		end,
	}
end
function MPAPI.get_current_lobby()
	return fake_lobby
end

dofile("pvp_api/referee.lua")

local function win_broadcasts()
	local n = 0
	for _, b in ipairs(broadcasts) do
		if b.key == "pvp_win" then
			n = n + 1
		end
	end
	return n
end

-- ─── Drive a match ──────────────────────────────────────────────────────────

MP.referee_reset(2)
assert(MP.REF.match_over == false, "match_over should start false after reset")

-- Round 1: p1 falls behind and runs out of hands -> loses a life (2 -> 1),
-- match must NOT be over yet.
MP.referee_on_play_hand("p2", { score = "50", handsLeft = 3 })
MP.referee_on_play_hand("p1", { score = "10", handsLeft = 0 })
assert(MP.REF.players["p1"].lives == 1, "expected p1 lives 2 -> 1 after round 1")
assert(win_broadcasts() == 0, "no pvp_win expected after a non-terminal life loss")
assert(MP.REF.match_over == false, "match_over must still be false after round 1")

MP.referee_on_new_round("p1")

-- Round 2: p1 falls behind again -> lives 1 -> 0 -> match ends, pvp_win fires
-- exactly once.
MP.referee_on_play_hand("p2", { score = "60", handsLeft = 3 })
MP.referee_on_play_hand("p1", { score = "20", handsLeft = 0 })
assert(MP.REF.players["p1"].lives == 0, "expected p1 lives 1 -> 0 after round 2")
assert(win_broadcasts() == 1, "expected exactly one pvp_win broadcast at match end")
assert(MP.REF.match_over == true, "match_over must be true once pvp_win has fired")
assert(broadcasts[#broadcasts].params.winner_id == "p2", "winner should be p2")

-- Several more play_hand events land after the match is already over (the
-- reported bug: per-hand sends, play_hand(chips,0), play_hand(0,0) on deck-out
-- all loop back through referee_on_play_hand). None of these may re-broadcast
-- pvp_win.
MP.referee_on_play_hand("p1", { score = "20", handsLeft = 0 })
MP.referee_on_play_hand("p2", { score = "60", handsLeft = 0 })
MP.referee_on_play_hand("p1", { score = "0", handsLeft = 0 })
MP.referee_on_play_hand("p2", { score = "0", handsLeft = 0 })
assert(win_broadcasts() == 1, "pvp_win must still have broadcast exactly once after stray play_hand events")

-- ─── A fresh match resets the flag and can broadcast its own single win ────

MP.referee_reset(2)
assert(MP.REF.match_over == false, "match_over must reset to false for a new match")

MP.referee_on_play_hand("p2", { score = "50", handsLeft = 3 })
MP.referee_on_play_hand("p1", { score = "10", handsLeft = 0 })
MP.referee_on_new_round("p1")
MP.referee_on_play_hand("p2", { score = "60", handsLeft = 3 })
MP.referee_on_play_hand("p1", { score = "20", handsLeft = 0 })
assert(win_broadcasts() == 2, "expected a second, single pvp_win broadcast for the new match")

-- Stray events after the second match's end must not add a third.
MP.referee_on_play_hand("p1", { score = "20", handsLeft = 0 })
MP.referee_on_play_hand("p2", { score = "60", handsLeft = 0 })
MP.referee_on_play_hand("p1", { score = "0", handsLeft = 0 })
assert(win_broadcasts() == 2, "pvp_win must not fire again after the second match already ended")

print("test_referee_match_over: OK")
