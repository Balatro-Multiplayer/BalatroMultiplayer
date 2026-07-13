--[[
  Lobby create/join queue-guard test (consumer side).

  Feature: you should not be able to create or join a lobby while in
  matchmaking. The API exposes MPAPI.matchmaking.guard_queued(replay) (shows a
  "Leave Queue & Continue" overlay and stashes `replay` to run after leaving);
  the PvP mod calls it at its lobby entry points.

  Bug this guards against: the guard must replay the CONSUMER entry point
  (MP.pvp_join_lobby / MP.pvp_create_private_lobby), NOT the API primitive
  (MPAPI.join_lobby / MPAPI.create_lobby). Those consumer functions call
  MP.setup_lobby_mirror(lobby) after obtaining the lobby -- that mirror builds
  the lobby UI and wires the CONNECTED handler that transitions the client into
  the lobby. Replaying the API primitive alone joins/creates server-side (the
  other player sees you) but skips setup_lobby_mirror, stranding the client on
  the PvP main menu. This test pins that: the replay runs setup_lobby_mirror.

  Run from the repo root:
    luajit tests/test_lobby_guard_while_queued.lua
]]

-- ── Stubs to load pvp_api/flow.lua ─────────────────────────────────────────
MP = { id = "pvp" }
G = { FUNCS = {} }
function sendWarnMessage(_msg, _cat) end

-- Controllable guard mirroring MPAPI.matchmaking.guard_queued's contract.
local searching = false
local stashed = nil
local overlay_shown = 0
MPAPI = {
	id = "pvp",
	GameModes = {},
	LobbyEvent = { CONNECTED = "connected" },
	refresh_current_view = function() end,
	matchmaking = {
		guard_queued = function(replay)
			if searching then
				stashed = replay
				overlay_shown = overlay_shown + 1
				return true
			end
			return false
		end,
	},
}

-- Fake lobby + API primitives, with call counters.
local api_join_calls, api_create_calls, mirror_calls = 0, 0, 0
local function fake_lobby()
	return { code = "ABC123", is_host = true, on = function() end }
end
MPAPI.join_lobby = function(_mod, _code) api_join_calls = api_join_calls + 1; return fake_lobby() end
MPAPI.create_lobby = function(_mod, _opts) api_create_calls = api_create_calls + 1; return fake_lobby() end

-- Load the REAL consumer entry points, then stub the mod-side collaborators the
-- guarded functions call (defined after dofile so they aren't clobbered).
dofile("pvp_api/flow.lua")
MP.setup_lobby_mirror = function(_lobby) mirror_calls = mirror_calls + 1 end
MP.pvp_lobby_metadata = function() return {} end

-- ── Harness ────────────────────────────────────────────────────────────────
local failures = 0
local function check(cond, msg)
	if cond then print("PASS: " .. msg) else failures = failures + 1; print("FAIL: " .. msg) end
end
local function reset() searching, stashed, overlay_shown = false, nil, 0; api_join_calls, api_create_calls, mirror_calls = 0, 0, 0 end

-- ── join: blocked while searching ───────────────────────────────────────────
print()
print("-- join: blocked while searching --")
reset(); searching = true
MP.pvp_join_lobby("ABC123")
check(api_join_calls == 0, "join: MPAPI.join_lobby NOT called while searching")
check(mirror_calls == 0, "join: setup_lobby_mirror NOT called while searching")
check(overlay_shown == 1 and type(stashed) == "function", "join: overlay shown and a replay closure stashed")

-- ── join: Leave Queue & Continue replays the FULL consumer flow ─────────────
print()
print("-- join: leave queue & continue runs the full consumer setup --")
searching = false
stashed() -- the overlay's replay
check(api_join_calls == 1, "join replay: MPAPI.join_lobby called after leaving")
check(mirror_calls == 1, "join replay: setup_lobby_mirror ran (client transitions into the lobby)")

-- ── join: proceeds normally when not searching ──────────────────────────────
print()
print("-- join: not searching -> proceeds --")
reset()
MP.pvp_join_lobby("ABC123")
check(api_join_calls == 1 and mirror_calls == 1, "join: joins and mirrors when not searching")
check(overlay_shown == 0, "join: no overlay when not searching")

-- ── create: blocked while searching, replay runs full setup ─────────────────
print()
print("-- create: blocked while searching; replay runs full setup --")
reset(); searching = true
MP.pvp_create_private_lobby("pvp_standard")
check(api_create_calls == 0 and mirror_calls == 0, "create: nothing allocated while searching")
check(overlay_shown == 1 and type(stashed) == "function", "create: overlay shown and replay stashed")
searching = false
stashed()
check(api_create_calls == 1 and mirror_calls == 1, "create replay: create_lobby + setup_lobby_mirror both ran")

-- ── RED control: replaying the API primitive strands the client ─────────────
-- Reproduces the original bug -- the stashed replay called MPAPI.join_lobby
-- directly, so setup_lobby_mirror never ran and the client stayed on the menu.
print()
print("-- control: replaying the API primitive skips setup (reproduces the bug) --")
reset()
local pre_fix_replay = function() return MPAPI.join_lobby(MP.id, "ABC123") end
pre_fix_replay()
check(api_join_calls == 1, "control: server-side join happened (other player sees you)")
check(mirror_calls == 0, "control: setup_lobby_mirror NEVER ran -- client stranded on the menu")

-- ── Summary ─────────────────────────────────────────────────────────────────
print()
if failures == 0 then
	print("ALL TESTS PASSED")
	os.exit(0)
else
	print(failures .. " TEST(S) FAILED")
	os.exit(1)
end
