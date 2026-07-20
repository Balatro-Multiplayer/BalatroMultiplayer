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
-- At end_run both streams are hashed and broadcast in the CHK trailer. The
-- carbon stream's hash (carbon_hash) is a real SHA-256 over a canonical JSON
-- re-encoding of its own {t, opcode, args} events (see canonical_hash_input),
-- not over the text lines themselves -- this is what the server independently
-- recomputes from its own buffered events and compares against at match-
-- resolve time (matchmaking.service.ts's evaluateAntiCheat, Phase 8) to flag a
-- tampered log. The human stream's hash (human_hash) stays on the cheap
-- MP.UTILS.joker_hash (Adler-style) -- it's never server-verified, just a
-- local corruption check. Full re-simulation anti-cheat remains future work.
--
-- Live transport: every event (including the MANIFEST/END/CHK framing lines)
-- is ALSO broadcast in real time via the pvp_log_event MPAPI ActionType (see
-- pvp_api/replay_log_actions.lua), one broadcast per event, not batched -- so a
-- server-side buffer (or, eventually, a spectator) sees each line as it
-- happens. This replaces the old Client.send({action="streamLogLines"/
-- "submitLogHashes"}) TCP-era actions, which pvp_api/net.lua's router now
-- silently drops (both are unlisted there). The local carbon/human text lines
-- into the Lovely log are unaffected either way -- broadcasting can silently
-- no-op (no lobby, practice mode, tests) without breaking local logging.

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
-- {t, opcode, args} tuples for gameplay events only -- populated exclusively by
-- RLOG.record, so the MANIFEST/END/CHK framing lines (emitted directly via
-- emit_carbon, bypassing record) are never in here. Used at end_run to compute
-- a canonical SHA-256 hash the server can independently reproduce (see
-- canonical_hash_input below) -- kept separate from _carbon_buffer because that
-- one holds pre-formatted text lines, not the structured values a hash needs.
RLOG._structured_events = {}
RLOG._run_active = false
RLOG._manifest = nil
RLOG._force_active = false -- test hook: bypass the lobby gate

-- Per-run correlation id (embedded in the manifest); not used for batching
-- anymore (see pvp_api/replay_log_actions.lua -- every event broadcasts live,
-- individually), just a friendly local identifier for this run instance.
RLOG._game_id = nil -- generated in begin_run

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

-- Mirrors pvp_api/replay_log_actions.lua's normalize_args (nil stays nil, a
-- table stays a table, a bare scalar becomes a single-element array) --
-- duplicated here rather than shared, since lib/ loads before pvp_api/.
-- Applied when building _structured_events (not to args generally -- fmt_args
-- and the carbon text line still use the original, unwrapped args) so the
-- hash input matches EXACTLY what the wire transport sends and the server
-- buffers. Without this, a bare-scalar opcode (select_blind, skip_blind,
-- pack_skip, ready_blind, set_ante_key) would hash differently locally (raw
-- scalar) than what the server observes (wrapped in a 1-element array by
-- normalize_args before broadcast), so every clean run would spuriously flag
-- as a hash mismatch.
local function normalize_for_hash(args)
	if args == nil then return nil end
	if type(args) == "table" then return args end
	return { args }
end

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

-- Friendly per-run correlation id, embedded in the manifest for local
-- debugging/display -- not load-bearing for the live transport (see
-- RLOG._game_id's declaration above).
local function new_game_id(manifest)
	local lobby = (manifest and manifest.lobby_code) or "nolobby"
	local who = (manifest and manifest.player) or "?"
	return string.format("%s-%s-%d-%d", tostring(lobby), tostring(who), os.time(), math.random(100000, 999999))
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

-- Emit a carbon-stream line: tee to the Lovely log, accumulate it into the full
-- local block, AND broadcast the structured (t, opcode, args) form live over
-- MPAPI (pvp_api/replay_log_actions.lua) -- one event per broadcast, no
-- batching. RLOG.broadcast_event is defined there, loaded after lib/ (see
-- core.lua); it may not exist yet at RLOG's own load time, but always does by
-- the time any of this actually runs, and simply doesn't exist under the
-- headless test harness (which never loads pvp_api/) -- either way, a missing
-- broadcaster just no-ops, local logging is unaffected.
local function emit_carbon(msg, t, opcode, args)
	RLOG._carbon_full[#RLOG._carbon_full + 1] = msg
	sendTraceMessage(msg, "MULTIPLAYER")
	if RLOG.broadcast_event then RLOG.broadcast_event(t, opcode, args) end
end

-- Encodes one {t, opcode, args} tuple as a JSON array literal, built manually
-- rather than via json.encode(ev) on a Lua table -- args is sometimes nil
-- (e.g. reroll, cashout), and a trailing nil in a positional Lua table makes
-- `#`/array-vs-object detection undefined, which a generic table encoder can't
-- be trusted to handle consistently. `t` and `opcode` are scalars (a number
-- and a string), and every args value in this codebase is nil, a bare scalar,
-- or a plain positional array/list (verified against every RLOG.record call
-- site -- never a table with string keys), so nothing here has Lua/JS
-- pairs()-order ambiguity to worry about; only the outer 3-element shape does.
local function encode_event_tuple(ev)
	local json = require("json")
	local args_json = ev.args == nil and "null" or json.encode(ev.args)
	return string.format("[%d,%s,%s]", ev.t, json.encode(ev.opcode), args_json)
end

-- Canonical JSON-array encoding of every gameplay event (see RLOG._structured_events),
-- used as the SHA-256 input for RLOG.end_run's CHK line -- independently
-- reproducible server-side (Node's JSON.stringify over the same tuple shape)
-- without needing to match Lua's dict key-iteration order, since the whole
-- input is array-shaped end to end.
local function canonical_hash_input()
	local parts = {}
	for _, ev in ipairs(RLOG._structured_events) do
		parts[#parts + 1] = encode_event_tuple(ev)
	end
	return "[" .. table.concat(parts, ",") .. "]"
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
	RLOG._structured_events[#RLOG._structured_events + 1] =
		{ t = t, opcode = opcode, args = normalize_for_hash(args) }
	emit_carbon(cline, t, opcode, args)

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
	RLOG._structured_events = {}
	RLOG._manifest = manifest
	RLOG._run_active = true

	-- Friendly local correlation id for this run instance (see the RLOG._game_id
	-- declaration above -- no longer used for batching).
	RLOG._game_id = new_game_id(manifest)
	manifest.game_id = RLOG._game_id

	local json = require("json")
	emit_carbon(RLOG.CARBON_PREFIX .. " MANIFEST " .. json.encode(manifest), 0, "manifest", manifest)
end

-- Close the current game's block: emit the END line, hash each stream, and emit
-- the CHK trailer. The hashes are returned for a future result-report step to
-- submit (see Phase 8/anti-cheat) -- there's no separate "submit the whole
-- block" step, since the server-side buffer already has every event from the
-- live pvp_log_event broadcasts and independently recomputes carbon_hash
-- itself (matchmaking.service.ts's evaluateAntiCheat) for comparison against
-- this value. carbon_hash is a real SHA-256 (love.data.hash) over
-- canonical_hash_input's positional-tuple JSON -- deliberately NOT over
-- carbon_str's text lines, since a byte-identical text re-formatting is much
-- harder to guarantee cross-language than re-encoding the same JSON tuples.
-- human_hash stays on the cheap Adler-style MP.UTILS.joker_hash -- it's never
-- server-verified, purely a local corruption check on the website-compatible
-- stream.
function RLOG.end_run(outcome)
	if not RLOG._run_active then return end

	local json = require("json")
	local t_end = elapsed_ms()
	emit_carbon(RLOG.CARBON_PREFIX .. " END " .. json.encode(outcome or {}), t_end, "end", outcome or {})

	local carbon_str = table.concat(RLOG._carbon_buffer, "\n")
	local human_str = table.concat(RLOG._human_buffer, "\n")
	local carbon_hash = love.data.encode("string", "hex", love.data.hash("sha256", canonical_hash_input()))
	local human_hash = MP.UTILS.joker_hash(human_str)
	local bytes = #carbon_str + #human_str

	local chk_args = { carbon = carbon_hash, human = human_hash, bytes = bytes }
	emit_carbon(
		string.format("%s CHK v1 carbon=%s human=%s bytes=%d", RLOG.CARBON_PREFIX, carbon_hash, human_hash, bytes),
		elapsed_ms(),
		"chk",
		chk_args
	)

	RLOG._run_active = false
	return carbon_hash, human_hash
end
