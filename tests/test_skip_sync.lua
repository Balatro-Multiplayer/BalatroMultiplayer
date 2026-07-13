--[[
  Opponent-skip sync test (pvp_api/net.lua : sync_pvp_blind, objects/blinds/nemesis.lua).

  Bug: the opponent's "skip" SFX (negative + gong) fired on their FIRST HAND of
  the PvP (nemesis) blind instead of at the moment they actually skipped.

  Root cause: the display-sync dispatch resolved the blind to sync through via
  "whatever blind is CURRENTLY ACTIVE" (originally MP.sync_pvp_blind reading
  G.GAME.blind.config.blind directly; after the MPAPI sync/receive rework,
  MPAPI.calculate_blind's identical G.GAME.blind.config.blind lookup in the
  framework's api/gamemode/hooks.lua reproduces the exact same bug). At the
  moment a skip happens, the active blind is the vanilla small/big blind being
  skipped -- bl_mp_nemesis only becomes active once the boss blind starts -- so
  that lookup resolves to a blind with no display-sync calculate, and the sync
  (and its SFX) is silently dropped. G.GAME.enemy.skips then stays stale until
  the opponent's first playHand of the boss blind, whose payload still carries
  the cumulative skip count; receive's stale delta (0 -> N) fires the SFX there
  instead -- one hand late.

  Fix: pvp_api/net.lua's playHand/skip routes dispatch display sync straight to
  the nemesis blind by its stable registered key (G.P_BLINDS["bl_mp_nemesis"])
  instead of through MPAPI.calculate_blind's active-blind resolution, so the
  sync fires at the real skip moment regardless of which blind is active. This
  also makes a LATER playHand echo of the same cumulative skips count a no-op
  reconcile (the delta is already 0), so the SFX plays exactly once per skip.

  Run from the repo root:
    luajit tests/test_skip_sync.lua
]]

-- ─── Stub game/framework globals ───────────────────────────────────────────

local play_sound_calls = {}
function play_sound(name)
	play_sound_calls[#play_sound_calls + 1] = name
end
function sendDebugMessage() end
function Event(t)
	return t
end

SMODS = { Atlas = function() end }

G = {
	C = { MULTIPLAYER = {} },
	P_BLINDS = {},
	E_MANAGER = { add_event = function() end }, -- score easing is cosmetic; not under test
	GAME = {},
}

-- Minimal stand-in for MPAPI.Blind / the MPAPI sync mixin (api/synced/objects.lua +
-- api/synced/core.lua in the BalatroMultiplayerAPI framework): registers the object
-- under its full key and gives it a :calculate(context) method that wraps the
-- consumer's own calculate (captured here as _user_calculate, same as the real
-- mixin) and, if it returns a `send` table, delivers it to the object's own
-- `receive`. In production that delivery is a network broadcast whose self-echo is
-- suppressed, so `receive` only ever runs on the RECEIVING (non-sender) client;
-- calling it directly here is exactly what that receiving peer's client does.
MPAPI = {
	Blind = function(def)
		local key = "bl_mp_" .. def.key
		local obj = { key = key, _user_calculate = def.calculate, receive = def.receive }
		function obj:calculate(context)
			local ret = self._user_calculate and self:_user_calculate(context)
			if type(ret) == "table" and ret.send ~= nil and self.receive then
				self:receive({ from = "opponent", data = ret.send })
			end
			return ret
		end
		G.P_BLINDS[key] = obj
		return obj
	end,
	get_current_lobby = function()
		return nil -- no real lobby; the referee broadcast in net.lua's routes no-ops
	end,
	ActionTypes = {},
}

MP = {
	GAME = {
		enemy = {
			skips = 0,
			highest_score = { v = 0 },
			spent_in_shop = {},
			lives = 4,
			hands = 4,
			info_received = false,
		},
		score = { v = 0 },
		lives = 4,
		timer_started = false,
		nemesis_timer_started = false,
		timer_consumed = false,
	},
	LOBBY = { config = { timer = false, timer_increment_seconds = 0 } },
	UI = {
		restore_timer = function() end,
		juice_up_pvp_hud = function() end,
	},
	INSANE_INT = {
		empty = function()
			return { v = 0 }
		end,
		from_string = function(s)
			return { v = tonumber(s) or 0 }
		end,
		to_string = function(v)
			return tostring(v.v)
		end,
		greater_than = function(a, b)
			return a.v > b.v
		end,
		equal = function(a, b)
			return a.v == b.v
		end,
	},
	is_any_layer_active = function()
		return false
	end,
	is_layer_active = function()
		return false
	end,
	-- Target-candidate gating (pvp_api/lobby_bridge.lua) is orthogonal to the skip-sync
	-- fix under test; no-op it so `receive` always accepts the stubbed sender.
	note_target_candidate = function() end,
	current_target_id = function()
		return nil
	end,
}

dofile("objects/blinds/nemesis.lua")
assert(G.P_BLINDS["bl_mp_nemesis"], "nemesis blind not registered under 'bl_mp_nemesis'")

dofile("pvp_api/net.lua")
assert(MP.net_route, "MP.net_route not defined after load")

local failures = 0
local function check(name, cond)
	if cond then
		print("ok   - " .. name)
	else
		failures = failures + 1
		print("FAIL - " .. name)
	end
end

local function count_sound(name)
	local n = 0
	for _, s in ipairs(play_sound_calls) do
		if s == name then n = n + 1 end
	end
	return n
end

-- ─── Scenario: opponent skips a VANILLA small/big blind (not the nemesis) ───
-- This is the exact bug condition: at skip time the currently active blind is
-- NOT bl_mp_nemesis (it only becomes active once the boss blind starts).
G.GAME.blind = { config = { blind = { key = "bl_small" } } } -- vanilla blind, no display-sync calculate
G.GAME.skips = 1

MP.net_route({ action = "skip", skips = 1 })

check("enemy.skips updated at skip time (not deferred to first hand)", MP.GAME.enemy.skips == 1)
check("skip SFX 'negative' played exactly once", count_sound("negative") == 1)
check("skip SFX 'gong' played exactly once", count_sound("gong") == 1)

local sfx_count_after_first_skip = #play_sound_calls

-- A second skip (still on a vanilla blind, e.g. the big blind) must reconcile
-- and play again -- one real skip, one sound, every time.
G.GAME.blind = { config = { blind = { key = "bl_big" } } }
G.GAME.skips = 2

MP.net_route({ action = "skip", skips = 2 })

check("second skip updates enemy.skips to 2", MP.GAME.enemy.skips == 2)
check("second skip plays its own SFX (2 more sounds)", #play_sound_calls == sfx_count_after_first_skip + 2)

local sfx_count_after_second_skip = #play_sound_calls

-- ─── Scenario: opponent reaches the boss blind and plays their first hand ───
-- playHand's payload still carries the same CUMULATIVE skips count (my_skips(),
-- read from G.GAME.skips, unchanged at 2). Since enemy.skips was already
-- reconciled at skip time, this must be a silent, idempotent reconcile -- no
-- repeat SFX (the double-SFX regression this fix must avoid). Point G.GAME.blind
-- at the REAL registered nemesis object (as production does -- Balatro/SMODS
-- reuse one center object per blind key) so this also faithfully models the
-- active-blind-is-genuinely-nemesis case.
G.GAME.blind = { config = { blind = G.P_BLINDS["bl_mp_nemesis"] } }
G.GAME.current_round = { hands_left = 3 }

MP.net_route({ action = "playHand", score = "300", handsLeft = 3 })

check("enemy.skips unchanged by the playHand echo", MP.GAME.enemy.skips == 2)
check("playHand's stale skips delta plays NO additional SFX", #play_sound_calls == sfx_count_after_second_skip)

if failures > 0 then error(failures .. " check(s) failed") end
print("\nAll skip-sync checks passed.")
