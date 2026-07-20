# Tests

## Ruleset Shape Snapshot

`test_ruleset_shape.lua` guards the data shape of every ruleset against accidental drift during refactors. It stubs minimal game globals, loads all ruleset files, and diffs each ruleset's ban lists, rework lists, scalars, and function hook presence against a checked-in baseline (`ruleset_shape.snapshot.lua`).

The snapshot is **committed to the repo** — treat it like a lock file. Regenerate it only when you intentionally change ruleset structure (adding a ruleset, changing a ban list, etc.). If the test fails and you didn't mean to change anything, something broke.

Requires Lua 5.4+ (or LuaJIT). Run from the repo root.

### Workflow

```bash
# Run the test — exits 0 if shapes match, 1 with a diff on mismatch
lua tests/test_ruleset_shape.lua test

# Regenerate the snapshot after intentional structural changes
lua tests/test_ruleset_shape.lua capture
```

After `capture`, review the diff in `tests/ruleset_snapshot.lua` before committing — it should reflect exactly the changes you intended and nothing else.

### What it checks

- All `banned_*` and `reworked_*` arrays (sorted for stable comparison)
- Scalars: `key`, `multiplayer_content`, `standard`, `forced_gamemode`, `forced_lobby_options`
- Presence of function hooks: `create_info_menu`, `force_lobby_options`, `is_disabled`
- Missing or unexpected rulesets

### What it does not check

- Function bodies (only whether a function is defined)
- Runtime behavior (ApplyBans hook chains, smallworld cull logic, speedlatro timer)
- Rework center definitions (`MP.ReworkCenter` calls)

## Replay Log (MP.RLOG)

`test_rlog_roundtrip.lua`, `test_rlog_checksum.lua`, and `test_rlog_stream.lua`
exercise the dual-stream replay logger (`lib/replay_log.lua`). They stub the
game globals, capture the lines it emits to the Lovely log, and assert on them
— no files are written.

Live transport: every event (manifest, actions, END, CHK) is also broadcast in
real time via the `game_log_event` MPAPI ActionType (`pvp_api/replay_log_actions.lua`),
one broadcast per event — no batching, so a server-side buffer or spectator
sees each line as it happens. This replaced the old TCP-era `streamLogLines`/
`submitLogHashes` actions, which had already gone dead (silently dropped by
`pvp_api/net.lua`'s router) once PvP moved onto MPAPI.

Both streams live in the ordinary Lovely log, distinguished by prefix:
- **Carbon (positional/replay):** `MP_RLOG:` — e.g. `MP_RLOG: 5123 buy 1 2`
  (`5123` = ms elapsed since the run began, not a bare sequence number), plus
  `MP_RLOG: MANIFEST {...}` (now also carrying `schema_version`, `api_version`,
  `start_epoch_ms`) and the `MP_RLOG: CHK v1 carbon=… human=… bytes=…` trailer.
- **Human-readable:** `Client sent message:` — the existing website-parser
  format, e.g. `Client sent message: action:boughtCardFromShop,card:Blueprint,cost:4`.

```bash
luajit tests/test_rlog_roundtrip.lua   # local log streams well-formed + hashes round-trip
luajit tests/test_rlog_checksum.lua    # editing one opcode changes the stored hash
luajit tests/test_rlog_stream.lua      # every carbon line broadcasts live, one-for-one, no batching
```

`test_rlog_roundtrip.lua` asserts: `MP_RLOG: MANIFEST` header (with the new
version/epoch fields) + `END`/`CHK` trailer; carbon action lines tagged with
`t` (elapsed ms — gapless/monotonic in the test's default scenario, since no
`love.timer` is stubbed there and `t` falls back to a plain incrementing
counter; a second scenario stubs `love.timer.getTime` to confirm the real
elapsed-ms math against a known clock); positional args including ordered
index-lists (e.g. `play 1.3.5.7.8`, `use 1 2.4`) intact; a paired `Client sent
message:` line per action; and `CHK` per-stream hashes that equal a recompute
over the captured lines. (This test is local-log-only; the live broadcast side
is `test_rlog_stream.lua`'s job.)

`test_rlog_stream.lua` stubs `RLOG.broadcast_event` directly (the hook
`pvp_api/replay_log_actions.lua` installs in the real mod) and asserts every
carbon-stream event — including the manifest/END/CHK frames, using the
reserved opcodes `"manifest"`/`"end"`/`"chk"` — triggers exactly one broadcast,
in order, with the real `(t, opcode, args)` payload, and that `t` is
monotonically non-decreasing across the whole run.

`test_rlog_checksum.lua` confirms the `CHK` carbon hash equals a hash of the
carbon stream (re-extracted by prefix) and that tampering with one opcode
changes it.

### Manual end-to-end check

Play one real multiplayer match, then open the Lovely log. Filter the `MP_RLOG:`
(positional) and `Client sent message:` (human) lines and confirm they mirror
each action event-for-event.

## Carbon Replay Parser (LOG_PARSER.carbon_to_replay)

`test_log_parser_carbon.lua` exercises `lib/log_parser.lua`'s carbon-driven
replay builder (Phase 6 of the compact action-log design): given a downloaded
`matchRunLogs` block's events (already JSON-decoded to `{t, opcode, args}`
tables), it reconstructs the same replay shape `LOG_PARSER.to_replay()`
produces from a parsed Lovely log, so `lib/ghost_replay.lua`'s playback code
needs no changes to consume either source.

A single carbon log is one player's own actions, so the function takes a
`side` ("player"/"enemy") to tag that log's `hand_result` events in the
output; combining both players' downloaded logs into one two-sided replay is
the caller's job. `hand_result` is a new opcode (`pvp_api/net.lua`'s
`playHand`/`skip` routes) carrying `{score, hands_left}` -- the only
score-bearing carbon event, needed because the rest of the action vocabulary
(`play`, `discard`, `buy`, ...) intentionally has no score fields.

```bash
luajit tests/test_log_parser_carbon.lua
```

Asserts: manifest fields (`seed`/`ruleset`/`gamemode`/`deck`/`stake`) and the
`end` frame's `result` map onto the replay's top-level fields with the same
defaults `to_replay()` uses when a field is missing; `set_ante_key` events
open a new int-keyed `ante_snapshots` entry; `hand_result` events append to
the current ante's `hands[]` with the given `side`; a `hand_result` before any
`set_ante_key` is dropped rather than mis-attributed to ante 1.

## Trap card utilities (lib/trap_utils.lua)

`test_trap_utils.lua` covers the pure-logic pieces of the Trap framework that
don't need the live game engine: `MP.TRAP.decrease_rank`'s suit/rank-key
arithmetic (mirrors Strength's own rank+1 pattern, inverted, floored at 2) and
`MP.TRAP.notify_owner`'s payload shape.

```bash
luajit tests/test_trap_utils.lua
```

### What it does not check

The plant → disguise → reveal → notify-owner flow itself (network round-trip,
`G.consumeables` placement, `facing`/reveal animation, the per-card `calculate`/
`receive` trigger conditions) needs a running Balatro + Integration (BInt)
instance — see the root `CLAUDE.md`'s `bint run` workflow — and isn't covered by
this static harness.
