-- Replay Log (MP.RLOG): dual-stream, deterministic, fully-recreatable action log.
--
-- Two streams are emitted from the SAME instrumentation points so they stay
-- event-for-event aligned (shared monotonic sequence number). Both go into the
-- ordinary Lovely log, distinguished only by a line prefix so parsers know what
-- to read -- there is no separate file.
--
--   1. Carbon-copy (replay) stream  -- prefix "MP_RLOG:". Positional, no names:
--      "MP_RLOG: 5 buy 1 2" means "buy shop area 1, slot 2". Indiscriminate, so
--      modded content is just "slot N" and replays across mods for free. This is
--      the only truly replayable stream. The block is framed by a MANIFEST
--      header and an END + CHK trailer (also under the MP_RLOG: prefix).
--
--   2. Human-readable stream  -- prefix "Client sent message:" (the existing
--      format the website parser already reads). "Client sent message: action:
--      boughtCardFromShop,card:Blueprint,cost:4".
--
-- record() is the single emitter for both lines, so the per-action overrides no
-- longer log the human line themselves -- they pass the payload to record().
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

-- Required manifest keys; begin_run warns if any are missing.
RLOG.REQUIRED_MANIFEST_KEYS = { "seed", "ruleset", "gamemode", "deck", "stake" }

RLOG._seq = 0
RLOG._carbon_buffer = {} -- the action "MP_RLOG: <seq> ..." lines, hashed at end
RLOG._human_buffer = {} -- the "Client sent message: ..." lines, hashed at end
RLOG._run_active = false
RLOG._manifest = nil
RLOG._force_active = false -- test hook: bypass the lobby gate

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

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

-- Record one state-affecting action. Emits the carbon (positional) line and,
-- when a human payload is provided, the mirrored human line -- both into the
-- Lovely log with the same sequence number.
--   opcode : string, e.g. "buy"
--   args   : nil | scalar | list of tokens (scalar or sub-list); see fmt_args
--   human  : nil | string payload in the existing "action:key,..." format
function RLOG.record(opcode, args, human)
	if not RLOG.is_active() or not RLOG._run_active then return end

	RLOG._seq = RLOG._seq + 1
	local seq = RLOG._seq

	local argstr = fmt_args(args)
	local cline = RLOG.CARBON_PREFIX .. " " .. seq .. " " .. opcode .. (argstr ~= "" and (" " .. argstr) or "")
	RLOG._carbon_buffer[#RLOG._carbon_buffer + 1] = cline
	emit(cline)

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

	RLOG._seq = 0
	RLOG._carbon_buffer = {}
	RLOG._human_buffer = {}
	RLOG._manifest = manifest
	RLOG._run_active = true

	local json = require("json")
	emit(RLOG.CARBON_PREFIX .. " MANIFEST " .. json.encode(manifest))
end

-- Close the current game's block: emit the END line, hash each stream, emit the
-- CHK trailer, and submit both hashes to the server.
function RLOG.end_run(outcome)
	if not RLOG._run_active then return end

	local json = require("json")
	emit(RLOG.CARBON_PREFIX .. " END " .. json.encode(outcome or {}))

	local carbon_str = table.concat(RLOG._carbon_buffer, "\n")
	local human_str = table.concat(RLOG._human_buffer, "\n")
	local carbon_hash = MP.UTILS.joker_hash(carbon_str)
	local human_hash = MP.UTILS.joker_hash(human_str)
	local bytes = #carbon_str + #human_str

	emit(string.format("%s CHK v1 carbon=%s human=%s bytes=%d", RLOG.CARBON_PREFIX, carbon_hash, human_hash, bytes))

	if MP.ACTIONS and MP.ACTIONS.submit_log_hashes then
		MP.ACTIONS.submit_log_hashes(carbon_hash, human_hash, RLOG._manifest and RLOG._manifest.seed)
	end

	RLOG._run_active = false
	return carbon_hash, human_hash
end
