--[[
  "Continue in singleplayer" resume decision.

  Bug: the end-of-match "Continue in singleplayer" handler
  (G.FUNCS:continue_in_singleplayer, ui/game/functions.lua) used to call
  save_run() then immediately read save.jkr back off disk and hand that to
  G:start_run(). Vanilla save_run() only synchronously fills in
  G.ARGS.save_run -- the actual disk write is dispatched to the async
  SAVE_MANAGER worker thread on a later Game:update tick. Reading the file
  back immediately raced that write, and because G.F_NO_SAVING is true for
  the whole MP match there was no prior save on disk to fall back on either,
  so the read reliably came back nil and G:start_run silently began a brand
  new run instead of resuming.

  The fix (lib/continue_singleplayer.lua) captures G.ARGS.save_run in memory
  right after save_run() returns and skips the disk round trip entirely.
  MP.UTILS.decide_continue_singleplayer is the pure "what do we do with the
  captured snapshot" decision extracted out of that handler: given a captured
  save table (or nil), decide whether to continue with it or abort rather
  than silently starting a fresh run.

  This test asserts the new decision function's behavior (green), and -- since
  the function is newly extracted and has no pre-fix equivalent to run
  unmodified -- also runs an inlined reproduction of the OLD racy-disk-read
  logic through the same assertion to demonstrate it fails for the documented
  reason (red control).

  Run from the repo root:
    luajit tests/test_continue_singleplayer.lua
]]

MP = { UTILS = {} }

dofile("lib/continue_singleplayer.lua")
local decide = assert(MP.UTILS.decide_continue_singleplayer, "MP.UTILS.decide_continue_singleplayer not defined after load")

-- ─── New (fixed) logic: table in vs continue-with-that-table out ───────────

do
	local savetext = { GAME = { dollars = 4 }, BLIND = { name = "Small Blind" } }
	local decision = decide(savetext)
	assert(decision.action == "continue", "expected continue, got " .. tostring(decision.action))
	assert(decision.savetext == savetext, "decision must carry through the exact captured table")
end

-- ─── New (fixed) logic: nil guard -- abort, never silently start fresh ─────

do
	local decision = decide(nil)
	assert(decision.action == "abort", "expected abort for nil savetext, got " .. tostring(decision.action))
	assert(type(decision.reason) == "string" and #decision.reason > 0, "abort must carry a non-empty reason")
	assert(decision.savetext == nil, "abort must not carry a savetext to start_run with")
end

-- ─── New (fixed) logic: non-table savetext also aborts (defensive) ─────────

do
	local decision = decide(false)
	assert(decision.action == "abort", "expected abort for non-table savetext, got " .. tostring(decision.action))
end

print("continue_singleplayer (fixed): all assertions passed")

-- ─── Regression control: the OLD racy-disk-read logic, inlined ────────────
--
-- Mirrors the removed handler body exactly:
--   G.SAVED_GAME = get_compressed(save_path)
--   if G.SAVED_GAME ~= nil then G.SAVED_GAME = STR_UNPACK(G.SAVED_GAME) end
--   G:start_run({ savetext = G.SAVED_GAME })
--
-- It always proceeds to start_run (no abort path existed), with whatever the
-- disk read produced. disk_read_result models get_compressed()+STR_UNPACK():
-- nil when the async save.jkr write from THIS run hasn't landed yet -- which,
-- per the bug, is every time, since G.F_NO_SAVING held for the entire MP
-- match and there's no earlier save.jkr to fall back on.
local function decide_continue_singleplayer_OLD(disk_read_result)
	return { action = "continue", savetext = disk_read_result }
end

do
	local ok, err = pcall(function()
		local disk_read_result = nil -- the async write hasn't flushed; no prior save.jkr exists either
		local decision = decide_continue_singleplayer_OLD(disk_read_result)
		assert(decision.savetext ~= nil, "BUG: continuing with a nil savetext starts a brand-new run instead of resuming")
	end)
	assert(not ok, "control: OLD logic was expected to fail this assertion (nil savetext -> fresh run bug), but it passed")
	assert(
		tostring(err):find("BUG: continuing with a nil savetext starts a brand-new run instead of resuming", 1, true),
		"control failed for the wrong reason: " .. tostring(err)
	)
	print("continue_singleplayer (OLD, control): failed as expected -- " .. tostring(err))
end

print("continue_singleplayer: all checks complete (fix green, pre-fix control red)")
