-- Pure decision for G.FUNCS:continue_in_singleplayer (ui/game/functions.lua).
--
-- Context: vanilla save_run() synchronously fills in G.ARGS.save_run, but the
-- actual save.jkr write is dispatched to the async SAVE_MANAGER worker thread
-- on a later Game:update tick. The old "continue in singleplayer" handler read
-- save.jkr back off disk immediately after calling save_run(), racing that
-- write. Because G.F_NO_SAVING is true for an entire MP match, there is also no
-- prior save on disk to fall back on -- the read reliably came back nil and
-- G:start_run silently began a brand-new run instead of resuming the match.
--
-- The fix captures the in-memory snapshot (G.ARGS.save_run, deep-copied before
-- G:delete_run() can mutate the live G.GAME table it still references) instead
-- of round-tripping through disk. This function is the pure "what do we do
-- with the captured snapshot" decision, so it's testable without any I/O.
--
-- savetext: the captured save table, or nil if save_run() didn't produce one.
-- Returns a plain-data command:
--   { action = "continue", savetext = <table> }
--   { action = "abort", reason = <string> }
function MP.UTILS.decide_continue_singleplayer(savetext)
	if type(savetext) ~= "table" then
		return {
			action = "abort",
			reason = "continue_in_singleplayer: no save snapshot captured, aborting to avoid starting a fresh run",
		}
	end
	return { action = "continue", savetext = savetext }
end
