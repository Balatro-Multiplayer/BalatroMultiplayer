-- Replay Log (MP.RLOG): dual-stream, deterministic, fully-recreatable action log.
--
-- Two streams are emitted from the SAME instrumentation points so they stay
-- event-for-event aligned (shared monotonic sequence number):
--
--   1. Carbon-copy (replay) stream  -- positional, no names. "A <seq> buy 1 1"
--      means "buy shop-jokers slot 1". Indiscriminate, so modded content is
--      just "slot N" and replays across mods for free. This is the only truly
--      replayable stream. The future replay runner re-runs the game from the
--      manifest seed and feeds these opcodes in order.
--
--   2. Human-readable stream  -- the semantic mirror. "H <seq> action:..." keeps
--      the existing log payload format so the website parser stays compatible.
--
-- BOTH streams live in a dedicated ".carbon" sidecar next to the Lovely log
-- (NOT in the mod folder, so version hotswaps don't disturb it). The .carbon
-- file is the self-contained dev/verification artifact: manifest header, the A
-- and H lines, then a trailer with a separate hash of each stream.
--
-- The player-facing Lovely log is left 100% unchanged: the existing per-action
-- sendTraceMessage calls keep emitting the human lines players read, and the new
-- carbon pipe never touches it. record() therefore does NOT write to the Lovely
-- log -- it only appends to the .carbon file. Pass record() the same human
-- payload those existing log lines use so the carbon H stream mirrors them.
--
-- At end_run both streams are hashed and the hashes are sent to the server, so
-- tamper-checking later is a cheap hash comparison instead of a line-by-line
-- diff. NOTE: MP.UTILS.joker_hash (Adler-style) catches casual edits but is NOT
-- collision-resistant -- a motivated forger could edit and fix the hash. The
-- robust defenses (server sees the lines live, or full re-simulation) are future
-- work; this hash is the intended cheap first pass.

local RLOG = {}
MP.RLOG = RLOG

-- Required manifest keys; begin_run warns if any are missing.
RLOG.REQUIRED_MANIFEST_KEYS = { "seed", "ruleset", "gamemode", "deck", "stake" }

RLOG._seq = 0
RLOG._carbon_buffer = {} -- the "A " lines (positional stream), hashed at end
RLOG._human_buffer = {} -- the "H " lines (human stream), hashed at end
RLOG._pending = {} -- lines awaiting flush to the .carbon file
RLOG._carbon_path = nil
RLOG._run_active = false
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

-- Derive the carbon sidecar path from the Lovely log path by swapping the
-- trailing extension for ".carbon" (same folder, same base name).
local function derive_carbon_path()
	local ok, lovely = pcall(require, "lovely")
	if not ok or not lovely or not lovely.log_path then return nil end
	-- Strip a trailing ".<ext>" on the final path segment only, then append.
	local base = lovely.log_path:gsub("%.[^%.\\/]*$", "")
	return base .. ".carbon"
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

local function push_carbon(line)
	RLOG._carbon_buffer[#RLOG._carbon_buffer + 1] = line
	RLOG._pending[#RLOG._pending + 1] = line
end

local function push_human(line)
	RLOG._human_buffer[#RLOG._human_buffer + 1] = line
	RLOG._pending[#RLOG._pending + 1] = line
end

-- Structural lines (MANIFEST/END/CHK) go to the file but are not part of the
-- per-stream hash buffers.
local function push_raw(line)
	RLOG._pending[#RLOG._pending + 1] = line
end

-------------------------------------------------------------------------------
-- File writing
-------------------------------------------------------------------------------

-- Append any buffered lines to the .carbon file. Append-mode so multiple games
-- in one Lovely session accumulate as sequential blocks. Called on begin_run,
-- once per round, and on end_run to bound data loss on crash.
function RLOG.flush()
	if #RLOG._pending == 0 then return end
	if not RLOG._carbon_path then return end
	local f = io.open(RLOG._carbon_path, "a")
	if not f then
		sendWarnMessage("RLOG: could not open carbon file " .. tostring(RLOG._carbon_path), "MULTIPLAYER")
		return
	end
	f:write(table.concat(RLOG._pending, "\n") .. "\n")
	f:close()
	RLOG._pending = {}
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

-- Record one state-affecting action. Writes the carbon (positional) line and,
-- when a human payload is provided, the mirrored human line -- both into the
-- .carbon file with the same sequence number. Never writes to the Lovely log.
--   opcode : string, e.g. "buy"
--   args   : nil | scalar | list of tokens (scalar or sub-list); see fmt_args
--   human  : nil | string payload in the existing "action:key,..." format
function RLOG.record(opcode, args, human)
	if not RLOG.is_active() or not RLOG._run_active then return end

	RLOG._seq = RLOG._seq + 1
	local seq = RLOG._seq

	local argstr = fmt_args(args)
	push_carbon("A " .. seq .. " " .. opcode .. (argstr ~= "" and (" " .. argstr) or ""))

	if human ~= nil and human ~= "" then push_human("H " .. seq .. " " .. human) end
end

-- Start a new game's block. Resets counters/buffers, resolves the carbon path,
-- writes the manifest header, and flushes it immediately.
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
	RLOG._pending = {}
	RLOG._carbon_path = derive_carbon_path()
	RLOG._manifest = manifest
	RLOG._run_active = true

	local json = require("json")
	push_raw("MANIFEST " .. json.encode(manifest))
	RLOG.flush()
end

-- Close the current game's block: write the END line, hash each stream, write
-- the CHK trailer, flush, and submit both hashes to the server.
function RLOG.end_run(outcome)
	if not RLOG._run_active then return end

	local json = require("json")
	push_raw("END " .. json.encode(outcome or {}))

	local carbon_str = table.concat(RLOG._carbon_buffer, "\n")
	local human_str = table.concat(RLOG._human_buffer, "\n")
	local carbon_hash = MP.UTILS.joker_hash(carbon_str)
	local human_hash = MP.UTILS.joker_hash(human_str)
	local bytes = #carbon_str + #human_str

	push_raw(string.format("CHK v1 carbon=%s human=%s bytes=%d", carbon_hash, human_hash, bytes))
	RLOG.flush()

	if MP.ACTIONS and MP.ACTIONS.submit_log_hashes then
		MP.ACTIONS.submit_log_hashes(carbon_hash, human_hash, RLOG._manifest and RLOG._manifest.seed)
	end

	RLOG._run_active = false
	return carbon_hash, human_hash
end
