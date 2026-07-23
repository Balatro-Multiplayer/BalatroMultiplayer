--[[
  Enemy hands display reset test.

  Bug: "Enemy hands left" HUD counter showed a wrong value at the start of
  every PvP blind -- action_start_blind reset MP.GAME.enemy.score/info_received
  but never MP.GAME.enemy.hands, so the HUD carried over either the previous
  blind's leftover count or the hardcoded initial default (4) until the
  opponent's first synced action (nemesis.lua's on_sync) landed. The hands
  "?" mask was also only applied when hide_score_until_played was on, so with
  that (default-off on many rulesets) option disabled the stale/default
  number rendered directly instead of being hidden.

  Covers the two pure decisions extracted into lib/blind_utils.lua so the fix
  is testable without loading the full networking/action_handlers.lua (which
  needs love.thread, a live G, json, etc.):

    * MP.UTILS.enemy_hands_reset()  -- what action_start_blind resets to
    * MP.UTILS.enemy_hands_text()   -- what the HUD renders each frame

  and a scenario-level simulation of the actual bug: a stale hands value left
  over from a previous blind, reset by action_start_blind's logic, then
  corrected by a simulated on_sync (mirrors objects/blinds/nemesis.lua).

  Run from the repo root (GREEN -- exercises the fixed logic, must pass):
    luajit tests/test_enemy_hands_reset.lua

  Run in CONTROL mode (RED -- exercises the pre-fix logic transcribed below,
  to prove this test would have caught the original bug):
    ENEMY_HANDS_TEST_MODE=control luajit tests/test_enemy_hands_reset.lua
]]

MP = { UTILS = {} }

dofile("lib/blind_utils.lua") -- provides the FIXED MP.UTILS.enemy_hands_reset / enemy_hands_text

local CONTROL = os.getenv("ENEMY_HANDS_TEST_MODE") == "control"

-- ─── Pre-fix logic, transcribed verbatim from the code before this fix ──────
--
-- action_start_blind (networking/action_handlers.lua) reset enemy.score and
-- enemy.info_received every blind, but had NO line touching enemy.hands /
-- enemy.hands_text at all -- so whatever was already in the table (the
-- previous blind's leftover count, or the "4" hardcoded default from
-- MP.reset_game_states) simply carried forward.
local function pre_fix_hands_reset()
	return nil -- nothing was reset; caller must leave the field untouched
end

-- G.FUNCS.multiplayer_blind_chip_UI_scale (ui/game/blind_hud.lua) only masked
-- the hands text when hide_score_until_played was enabled:
--   if hide_score_until_played and is_pvp_boss and not info_received then "?"
--   else tostring(hands) end
local function pre_fix_hands_text(hands, info_received, is_pvp_boss, hide_score_until_played)
	if hide_score_until_played and is_pvp_boss and not info_received then return "?" end
	return tostring(hands)
end

-- Select which implementation this run exercises. Default (no env var) runs
-- the FIXED logic and must be all-green. CONTROL mode runs the pre-fix logic
-- against the exact same scenarios/expectations to demonstrate they fail.
local reset_fn, text_fn
if CONTROL then
	reset_fn = pre_fix_hands_reset
	text_fn = function(hands, info_received, is_pvp_boss)
		-- hide_score_until_played=false matches the bug report: most rulesets
		-- don't force it on, and that's exactly when the raw stale number leaked.
		return pre_fix_hands_text(hands, info_received, is_pvp_boss, false)
	end
	print("=== CONTROL MODE: exercising PRE-FIX logic (expect FAILures below) ===\n")
else
	reset_fn = MP.UTILS.enemy_hands_reset
	text_fn = MP.UTILS.enemy_hands_text
end

local failures = 0
local function check(name, cond)
	if cond then
		print("ok   - " .. name)
	else
		failures = failures + 1
		print("FAIL - " .. name)
	end
end

-- ─── 1. hands_reset() ────────────────────────────────────────────────────────

local reset = reset_fn() or {}
check("reset hands is a number, not nil", type(reset.hands) == "number")
check("reset hands is not the stale default of 4", reset.hands ~= 4)
check("reset hands_text is the unknown placeholder", reset.hands_text == "?")

-- ─── 2. hands_text() decision table ──────────────────────────────────────────

local cases = {
	{ name = "pvp boss, not yet synced -> masked",             hands = 4,  info_received = false, is_pvp_boss = true,  expect = "?" },
	{ name = "pvp boss, synced -> real count",                  hands = 3,  info_received = true,  is_pvp_boss = true,  expect = "3" },
	{ name = "pvp boss, synced to zero -> real count",          hands = 0,  info_received = true,  is_pvp_boss = true,  expect = "0" },
	{ name = "not pvp boss -> real count regardless of sync",   hands = 4,  info_received = false, is_pvp_boss = false, expect = "4" },
}
for _, c in ipairs(cases) do
	local got = text_fn(c.hands, c.info_received, c.is_pvp_boss)
	check(c.name .. " (got " .. tostring(got) .. ")", got == c.expect)
end

-- ─── 3. Scenario: full reset-then-sync cycle across two PvP blinds ─────────
-- Simulates the actual bug: an `enemy` table left with a stale/mismatched
-- count from a previous blind, action_start_blind's reset logic applied,
-- HUD rendered before any sync, then an on_sync-style update (mirrors
-- objects/blinds/nemesis.lua's on_sync) landing.

local enemy = { hands = 1, hands_text = "1", info_received = true } -- leftover from a blind the opponent nearly lost

-- action_start_blind's reset (mirrors networking/action_handlers.lua):
local function simulate_action_start_blind(enemy)
	enemy.info_received = false
	local hr = reset_fn()
	if hr then
		enemy.hands = hr.hands
		enemy.hands_text = hr.hands_text
	end
	-- pre-fix reset_fn returns nil, i.e. nothing touches enemy.hands -- exactly
	-- reproducing the missing reset line in the pre-fix action_start_blind.
	return enemy
end

-- HUD render (mirrors G.FUNCS.multiplayer_blind_chip_UI_scale in ui/game/blind_hud.lua):
local function render_hands_text(enemy, is_pvp_boss)
	enemy.hands_text = text_fn(enemy.hands, enemy.info_received, is_pvp_boss)
	return enemy.hands_text
end

simulate_action_start_blind(enemy)
check("post-reset hands is not the stale leftover (1)", enemy.hands ~= 1)
check("post-reset, pre-sync HUD text is masked, not stale '1'", render_hands_text(enemy, true) == "?")

-- Opponent's first playHand/skip of the new blind syncs the real count in
-- (mirrors on_sync setting MP.GAME.enemy.hands + info_received):
enemy.hands = 4
enemy.info_received = true
check("post-sync HUD text shows the real count", render_hands_text(enemy, true) == "4")

if failures > 0 then
	if CONTROL then
		print(
			"\n"
				.. failures
				.. " check(s) failed under CONTROL (pre-fix) logic, as expected -- "
				.. "this test would have caught the original bug."
		)
		os.exit(1)
	end
	error(failures .. " check(s) failed")
end
print("\nAll enemy hands reset checks passed.")
