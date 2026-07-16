-- Replay Log (MP.RLOG): dual-stream, deterministic, fully-recreatable action log.
--
-- Two streams are emitted from the SAME instrumentation points so they stay
-- event-for-event aligned (shared elapsed-ms timestamp). Both go into the
-- ordinary Lovely log, distinguished only by a line prefix so parsers know what
-- to read -- there is no separate file.
--
--   1. Carbon-copy (replay) stream  -- prefix "MP_RLOG:". Positional, no names:
--      "MP_RLOG: 5123 buy 1 2" means "at 5.123s into the run, buy shop area 1,
--      slot 2". Indiscriminate, so modded content is just "slot N" and replays
--      across mods for free. This is the only truly replayable stream. The
--      block is framed by a MANIFEST header and an END + CHK trailer (also
--      under the MP_RLOG: prefix).
--
--   2. Human-readable stream  -- prefix "Client sent message:" (the existing
--      format the website parser already reads). "Client sent message: action:
--      boughtCardFromShop,card:Blueprint,cost:4".
--
-- record() is the single emitter for both lines, so the per-action overrides no
-- longer log the human line themselves -- they pass the payload to record().
--
-- Timestamps: each event's leading field is `t`, milliseconds elapsed since the
-- manifest's `start_epoch_ms` (captured once, via a monotonic clock) -- not a
-- bare sequence counter. This keeps per-event numbers small (a few digits for a
-- multi-minute match, instead of repeating a 13-digit absolute epoch stamp on
-- every line) while still being monotonically non-decreasing, so it doubles as
-- the same ordering key a sequence number would give, and additionally carries
-- the real elapsed-time information anti-cheat plausibility checks and
-- reconnect tail-requests both need. Matches the MQTT design doc's own §26.1
-- `t` field convention (ms since match start), so this format and the server's
-- eventual event schema agree instead of diverging.
--
-- At end_run both streams are hashed and the hashes are sent to the server, so
-- tamper-checking later is a cheap hash comparison instead of a line-by-line
-- diff. The carbon stream re-derives cleanly from the log by its prefix. NOTE:
-- MP.UTILS.joker_hash (Adler-style) catches casual edits but is NOT collision-
-- resistant -- a motivated forger could edit and fix the hash. The robust
-- defenses (server sees the lines live, or full re-simulation) are future work;
-- this hash is the intended cheap first pass.

local RLOG = {}
MP.RLOG = RLOG

RLOG.CARBON_PREFIX = "MP_RLOG:" -- positional / replay stream
RLOG.HUMAN_PREFIX = "Client sent message:" -- human-readable stream (website-compatible)

-- Schema version of the MANIFEST/event format itself (bump on breaking changes
-- to what the server/replay-parser needs to understand, independent of mod_version).
RLOG.SCHEMA_VERSION = 1

-- Required manifest keys; begin_run warns if any are missing. api_version/
-- mod_version/start_epoch_ms are stamped by begin_run itself (see below), not
-- required from the caller.
RLOG.REQUIRED_MANIFEST_KEYS = { "seed", "ruleset", "gamemode", "deck", "stake" }

RLOG._start_ms = nil -- monotonic-clock ms at begin_run, source of truth for each event's `t`
RLOG._fallback_seq = 0 -- ms-surrogate counter when no monotonic clock is available (e.g. tests)
RLOG._carbon_buffer = {} -- the action "MP_RLOG: <t> ..." lines, hashed at end
RLOG._carbon_full = {} -- the full carbon block (manifest + actions + END + CHK), sent to the server
RLOG._human_buffer = {} -- the "Client sent message: ..." lines, hashed at end
RLOG._run_active = false
RLOG._manifest = nil
RLOG._force_active = false -- test hook: bypass the lobby gate

-- Live streaming: carbon lines are pushed to the server in batches as the game
-- plays, so a crashed/abandoned game still leaves a partial record server-side.
-- On a clean end the server swaps that partial for the full hashed package.
RLOG._game_id = nil -- per-game grouping key, generated in begin_run
RLOG._pending = {} -- carbon lines buffered since the last flush
RLOG._last_flush = 0 -- love.timer.getTime() of the last flush (0 if unavailable)
RLOG.STREAM_FLUSH_LINES = 25 -- flush once this many lines are buffered, or...
RLOG.STREAM_FLUSH_SECS = 2 -- ...this many seconds have passed since the last flush

-------------------------------------------------------------------------------
-- Gate
-------------------------------------------------------------------------------

-- Only real multiplayer games log. Ghost playback, practice, and the preview
-- simulation have no lobby code, so they never emit.
function RLOG.is_active()
	if RLOG._force_active then return true end
	if not (MP.LOBBY and MP.LOBBY.code) then return false end
	if MP.GHOST and MP.GHOST.is_active and MP.GHOST.is_active() then return false end
	return true
end

-------------------------------------------------------------------------------
-- Internal helpers
-------------------------------------------------------------------------------

-- Format an opcode's args into the positional arg string.
-- Each token is either a scalar -> "1" or a list -> dot-joined "1.3.5".
-- A bare scalar/string is treated as a single token.
local function fmt_args(args)
	if args == nil then return "" end
	if type(args) ~= "table" then return tostring(args) end
	local parts = {}
	for _, tok in ipairs(args) do
		if type(tok) == "table" then
			local sub = {}
			for _, v in ipairs(tok) do
				sub[#sub + 1] = tostring(v)
			end
			parts[#parts + 1] = table.concat(sub, ".")
		else
			parts[#parts + 1] = tostring(tok)
		end
	end
	return table.concat(parts, " ")
end

local function emit(msg)
	sendTraceMessage(msg, "MULTIPLAYER")
end

-- Per-game grouping key for the live stream. Lets the server group a game's
-- streamed lines and delete them once the final package lands.
local function new_game_id(manifest)
	local lobby = (manifest and manifest.lobby_code) or "nolobby"
	local who = (manifest and manifest.player) or "?"
	return string.format("%s-%s-%d-%d", tostring(lobby), tostring(who), os.time(), math.random(100000, 999999))
end

-- Best-effort wall clock for flush pacing; 0 when love.timer is unavailable
-- (e.g. under the headless test harness), in which case flushing falls back to
-- the line-count trigger plus the end-of-run flush.
local function stream_now()
	if love and love.timer and love.timer.getTime then return love.timer.getTime() end
	return 0
end

-- Milliseconds elapsed since begin_run, for each event's `t`. Falls back to a
-- plain incrementing counter (behaving like the old sequence number) when
-- love.timer isn't available, e.g. under the headless test harness -- so
-- `t` is still monotonically non-decreasing even without a real clock.
local function elapsed_ms()
	if RLOG._start_ms == nil then
		RLOG._fallback_seq = RLOG._fallback_seq + 1
		return RLOG._fallback_seq
	end
	return math.floor(love.timer.getTime() * 1000 - RLOG._start_ms + 0.5)
end

-- Send any buffered carbon lines to the server as one batch. No-ops cleanly if
-- there's no transport yet (e.g. tests) -- the lines are still kept in the full
-- carbon block submitted at end_run.
function RLOG.flush()
	if #RLOG._pending == 0 then return end
	if not (RLOG._game_id and MP.ACTIONS and MP.ACTIONS.stream_log_lines) then return end
	local batch = RLOG._pending
	RLOG._pending = {}
	RLOG._last_flush = stream_now()
	MP.ACTIONS.stream_log_lines(RLOG._game_id, batch)
end

-- Flush once the batch is big enough or enough time has elapsed since the last.
local function maybe_flush()
	if #RLOG._pending >= RLOG.STREAM_FLUSH_LINES then
		RLOG.flush()
	elseif (stream_now() - RLOG._last_flush) >= RLOG.STREAM_FLUSH_SECS then
		RLOG.flush()
	end
end

-- Emit a carbon-stream line: tee to the Lovely log, accumulate it into the full
-- block we ship to the server at end_run, AND queue it for live streaming.
local function emit_carbon(msg)
	RLOG._carbon_full[#RLOG._carbon_full + 1] = msg
	RLOG._pending[#RLOG._pending + 1] = msg
	sendTraceMessage(msg, "MULTIPLAYER")
	maybe_flush()
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

-- Record one state-affecting action. Emits the carbon (positional) line and,
-- when a human payload is provided, the mirrored human line -- both into the
-- Lovely log tagged with the same elapsed-ms timestamp `t`.
--   opcode : string, e.g. "buy"
--   args   : nil | scalar | list of tokens (scalar or sub-list); see fmt_args
--   human  : nil | string payload in the existing "action:key,..." format
function RLOG.record(opcode, args, human)
	if not RLOG.is_active() or not RLOG._run_active then return end

	local t = elapsed_ms()

	local argstr = fmt_args(args)
	local cline = RLOG.CARBON_PREFIX .. " " .. t .. " " .. opcode .. (argstr ~= "" and (" " .. argstr) or "")
	RLOG._carbon_buffer[#RLOG._carbon_buffer + 1] = cline
	emit_carbon(cline)

	if human ~= nil and human ~= "" then
		local hline = RLOG.HUMAN_PREFIX .. " " .. human
		RLOG._human_buffer[#RLOG._human_buffer + 1] = hline
		emit(hline)
	end
end

-- Start a new game's block: reset counters/buffers and emit the manifest header.
function RLOG.begin_run(manifest)
	manifest = manifest or {}

	for _, key in ipairs(RLOG.REQUIRED_MANIFEST_KEYS) do
		if manifest[key] == nil then
			sendWarnMessage("RLOG: manifest missing required key '" .. key .. "'", "MULTIPLAYER")
		end
	end

	-- Stamped here, not required from the caller: schema/mod versions (for a
	-- server/parser to know how to read this block) and the wall-clock epoch
	-- each event's elapsed-ms `t` is relative to. os.time() is second-precision
	-- (fine for a "when did this match start" record) -- per-event elapsed time
	-- itself comes from the monotonic love.timer clock captured just below, not
	-- from this coarser epoch stamp.
	manifest.schema_version = manifest.schema_version or RLOG.SCHEMA_VERSION
	if manifest.api_version == nil and SMODS and SMODS.Mods and SMODS.Mods["MultiplayerAPI"] then
		manifest.api_version = SMODS.Mods["MultiplayerAPI"].version
	end
	manifest.start_epoch_ms = manifest.start_epoch_ms or (os.time() * 1000)

	RLOG._start_ms = (love and love.timer and love.timer.getTime) and (love.timer.getTime() * 1000) or nil
	RLOG._fallback_seq = 0
	RLOG._carbon_buffer = {}
	RLOG._carbon_full = {}
	RLOG._human_buffer = {}
	RLOG._manifest = manifest
	RLOG._run_active = true

	-- Open the live stream for this game: fresh id + empty batch buffer.
	RLOG._game_id = new_game_id(manifest)
	manifest.game_id = RLOG._game_id
	RLOG._pending = {}
	RLOG._last_flush = stream_now()

	local json = require("json")
	emit_carbon(RLOG.CARBON_PREFIX .. " MANIFEST " .. json.encode(manifest))
end

-- Close the current game's block: emit the END line, hash each stream, emit the
-- CHK trailer, and submit the hashes plus the full carbon block to the server.
function RLOG.end_run(outcome)
	if not RLOG._run_active then return end

	local json = require("json")
	emit_carbon(RLOG.CARBON_PREFIX .. " END " .. json.encode(outcome or {}))

	local carbon_str = table.concat(RLOG._carbon_buffer, "\n")
	local human_str = table.concat(RLOG._human_buffer, "\n")
	local carbon_hash = MP.UTILS.joker_hash(carbon_str)
	local human_hash = MP.UTILS.joker_hash(human_str)
	local bytes = #carbon_str + #human_str

	emit_carbon(string.format("%s CHK v1 carbon=%s human=%s bytes=%d", RLOG.CARBON_PREFIX, carbon_hash, human_hash, bytes))

	-- Push any remaining streamed lines (incl. END + CHK) before the final
	-- package, so an oversized/rejected package still leaves a complete stream.
	RLOG.flush()

	if MP.ACTIONS and MP.ACTIONS.submit_log_hashes then
		-- The full carbon block (manifest + actions + END + CHK) so the server
		-- keeps the complete viewable/replayable log, not just its hash. The
		-- game_id lets the server drop this game's live stream in favour of it.
		local carbon_log = table.concat(RLOG._carbon_full, "\n")
		MP.ACTIONS.submit_log_hashes(carbon_hash, human_hash, RLOG._manifest and RLOG._manifest.seed, carbon_log, RLOG._game_id)
	end

	RLOG._run_active = false
	return carbon_hash, human_hash
end
