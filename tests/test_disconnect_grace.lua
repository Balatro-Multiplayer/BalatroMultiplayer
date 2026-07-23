--[[
  Disconnect-grace routing test.

  Covers the bug: "opponent leaves -> instant win screen" for ANY departure,
  including a transient network drop. Exercises:

   1. The pure decision core (pvp_api/disconnect_grace.lua):
      MP.decide_departure_action(event, state) -> "ignore" | "start_grace" | "cancel_grace"
      MP.disconnect_grace_expired(remaining, countdown) -> bool (single-fire guard)

   2. A RED control: the OLD pre-fix routing (PLAYER_LEFT -> instant
      on_player_forfeit whenever G.STAGE == RUN, no grace distinction) run
      through the same network-drop scenario, proving it forfeits
      immediately -- the exact bug -- while the new decision core does not.

   3. The shell wiring (pvp_api/lobby_bridge.lua): a fake MPAPI lobby drives
      PLAYER_DISCONNECTED / PLAYER_LEFT / PLAYER_RECONNECTED through the real
      `lobby:on` handlers registered by MP.setup_lobby_mirror, with a fake
      MP.dispatch_action that mimics the real enemyDisconnected/enemyReconnected
      handlers just enough to track countdown state -- asserting only ONE
      "enemyDisconnected" dispatch happens per outage (idempotent while grace
      is active) and that a reconnect cancels it.

  Run from the repo root:
    luajit tests/test_disconnect_grace.lua
]]

local failures = 0
local function check(name, cond)
	if cond then
		print("ok   - " .. name)
	else
		failures = failures + 1
		print("FAIL - " .. name)
	end
end

-- ─── 1. Pure decision core ───────────────────────────────────────────────────

MP = {}
dofile("pvp_api/disconnect_grace.lua")

local function state(overrides)
	local s = { is_opponent = true, in_run = true, grace_active = false }
	for k, v in pairs(overrides or {}) do
		s[k] = v
	end
	return s
end

check(
	"not-opponent events are ignored",
	MP.decide_departure_action("player_disconnected", state({ is_opponent = false })) == "ignore"
)
check("out-of-run events are ignored", MP.decide_departure_action("player_disconnected", state({ in_run = false })) == "ignore")
check(
	"first player_disconnected starts grace",
	MP.decide_departure_action("player_disconnected", state({ grace_active = false })) == "start_grace"
)
check(
	"player_disconnected while grace already active is a no-op",
	MP.decide_departure_action("player_disconnected", state({ grace_active = true })) == "ignore"
)
check(
	"player_reconnected while grace active cancels it",
	MP.decide_departure_action("player_reconnected", state({ grace_active = true })) == "cancel_grace"
)
check(
	"player_reconnected with no active grace is a no-op",
	MP.decide_departure_action("player_reconnected", state({ grace_active = false })) == "ignore"
)
-- The core fix: player_left (which the API can also fire for an ungraceful
-- LWT-driven drop, not just a deliberate leave) starts grace instead of an
-- instant forfeit.
check(
	"player_left with no active grace starts grace (never an instant forfeit)",
	MP.decide_departure_action("player_left", state({ grace_active = false })) == "start_grace"
)
check(
	"player_left while grace already active is a no-op (avoids double-resolution)",
	MP.decide_departure_action("player_left", state({ grace_active = true })) == "ignore"
)
check("unknown event is ignored", MP.decide_departure_action("something_else", state()) == "ignore")

-- Expiry single-fire guard.
check("expired countdown (remaining<=0, unresolved) resolves", MP.disconnect_grace_expired(0, { resolved = false }) == true)
check("not-yet-expired countdown does not resolve", MP.disconnect_grace_expired(5, { resolved = false }) == false)
check("already-resolved countdown never resolves again", MP.disconnect_grace_expired(0, { resolved = true }) == false)
check("nil countdown never resolves", MP.disconnect_grace_expired(0, nil) == false)

-- ─── 2. RED control: the old pre-fix routing, run through the same scenario ──

-- This mirrors the exact logic that shipped before this fix
-- (pvp_api/lobby_bridge.lua's PLAYER_LEFT handler, pre-fix):
--   if gm and gm.on_player_forfeit and G.STAGE == G.STAGES.RUN then
--       gm:on_player_forfeit(player_id)
--   end
-- with no distinction between a deliberate leave and a network drop, and no
-- subscription to PLAYER_DISCONNECTED/PLAYER_RECONNECTED at all.
local function old_pre_fix_on_player_left(in_run)
	if in_run then
		return "forfeit_now" -- <- the bug: instant win/lose on ANY departure
	end
	return "ignore"
end

-- Scenario: opponent's connection drops mid-run. The API fires `player_left`
-- (e.g. via the LWT-cleared players/<id>/info topic) with no prior
-- `player_disconnected` ever observed -- exactly the ambiguous case described
-- in disconnect_grace.lua's header comment.
local dropped_mid_run = { is_opponent = true, in_run = true, grace_active = false }

check(
	"RED: old pre-fix logic forfeits instantly on a mid-run network drop (the bug)",
	old_pre_fix_on_player_left(dropped_mid_run.in_run) == "forfeit_now"
)
check(
	"GREEN: new decision core pauses instead of forfeiting on the same drop",
	MP.decide_departure_action("player_left", dropped_mid_run) == "start_grace"
)

-- ─── 3. Shell wiring: pvp_api/lobby_bridge.lua ───────────────────────────────

-- Fresh global MP/MPAPI/G stubs for the shell-level test so nothing leaks
-- from the pure-core section above.
local dispatch_log = {}
local exit_overlay_calls = 0

G = { STAGE = "RUN", STAGES = { RUN = "RUN", MAIN_MENU = "MAIN_MENU" } }
G.FUNCS = { exit_overlay_menu = function() exit_overlay_calls = exit_overlay_calls + 1 end }

MP = {
	LOBBY = { config = {}, deck = {} },
	reset_game_states = function() end,
	enemy_disconnect_countdown = nil,
	dispatch_action = function(name, params)
		dispatch_log[#dispatch_log + 1] = { name = name, params = params }
		-- Mimic just enough of the real handlers (networking/action_handlers.lua)
		-- to drive MP.enemy_disconnect_countdown for the idempotency assertions.
		if name == "enemyDisconnected" then
			MP.enemy_disconnect_countdown = { player_id = params.player_id }
		elseif name == "enemyReconnected" then
			MP.enemy_disconnect_countdown = nil
		end
	end,
}

MPAPI = {
	LobbyEvent = {
		CONNECTED = "connected",
		DISCONNECTED = "disconnected",
		ERROR = "error",
		PLAYER_JOINED = "player_joined",
		PLAYER_LEFT = "player_left",
		PLAYER_DISCONNECTED = "player_disconnected",
		PLAYER_RECONNECTED = "player_reconnected",
		METADATA_CHANGED = "metadata_changed",
		HOST_CHANGED = "host_changed",
	},
	get_current_lobby = function() return nil end,
	create_lobby_ui = function() return {} end,
	refresh_current_view = function() end,
}

-- Minimal fake lobby: records `on(event, cb)` handlers and lets the test fire them.
local function make_fake_lobby()
	local handlers = {}
	local lobby
	lobby = {
		code = "TEST",
		is_host = true,
		player_id = "me",
		on = function(_self, event, cb)
			handlers[event] = handlers[event] or {}
			table.insert(handlers[event], cb)
		end,
		get_players = function() return { { id = "me" }, { id = "opp" } } end,
		get_metadata = function() return {} end,
		fire = function(_self, event, ...)
			for _, cb in ipairs(handlers[event] or {}) do
				cb(...)
			end
		end,
	}
	return lobby
end

dofile("pvp_api/disconnect_grace.lua") -- MP.decide_departure_action / MP.disconnect_grace_expired
dofile("pvp_api/lobby_bridge.lua")

local lobby = make_fake_lobby()
MP.setup_lobby_mirror(lobby)

-- Opponent's connection drops mid-run: PLAYER_DISCONNECTED fires.
lobby:fire(MPAPI.LobbyEvent.PLAYER_DISCONNECTED, "opp")
check("PLAYER_DISCONNECTED dispatches enemyDisconnected exactly once", #dispatch_log == 1 and dispatch_log[1].name == "enemyDisconnected")
check("grace countdown is now active", MP.enemy_disconnect_countdown ~= nil)

-- A duplicate PLAYER_DISCONNECTED (e.g. redelivered) must not re-dispatch or
-- restart the countdown (idempotent while grace is already active).
lobby:fire(MPAPI.LobbyEvent.PLAYER_DISCONNECTED, "opp")
check("duplicate PLAYER_DISCONNECTED does not re-dispatch", #dispatch_log == 1)

-- Reconnect before expiry cancels the grace period.
lobby:fire(MPAPI.LobbyEvent.PLAYER_RECONNECTED, "opp")
check("PLAYER_RECONNECTED dispatches enemyReconnected", #dispatch_log == 2 and dispatch_log[2].name == "enemyReconnected")
check("grace countdown cleared on reconnect", MP.enemy_disconnect_countdown == nil)

-- A fresh outage that goes all the way to a `player_left` (no disconnected
-- event ever seen for it) also pauses -- the core fix -- rather than
-- forfeiting on the spot.
lobby:fire(MPAPI.LobbyEvent.PLAYER_LEFT, "opp")
check("PLAYER_LEFT with no prior grace starts a fresh grace period", #dispatch_log == 3 and dispatch_log[3].name == "enemyDisconnected")
check("no forfeit call was made synchronously from the event handler", exit_overlay_calls == 0)

-- Self departures (player_id == lobby.player_id) must never be routed as an
-- opponent departure.
local dispatch_count_before_self = #dispatch_log
MP.enemy_disconnect_countdown = nil
lobby:fire(MPAPI.LobbyEvent.PLAYER_DISCONNECTED, "me")
check("self player_id is never treated as the opponent departing", #dispatch_log == dispatch_count_before_self)

if failures > 0 then
	error(failures .. " check(s) failed")
end
print("\nAll disconnect-grace checks passed.")
