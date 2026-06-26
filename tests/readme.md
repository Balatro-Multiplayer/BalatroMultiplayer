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

`test_rlog_roundtrip.lua` and `test_rlog_checksum.lua` exercise the dual-stream
replay logger (`lib/replay_log.lua`). They stub the game globals, capture the
lines it emits to the Lovely log, and assert on them — no files are written.

Both streams live in the ordinary Lovely log, distinguished by prefix:
- **Carbon (positional/replay):** `MP_RLOG:` — e.g. `MP_RLOG: 5 buy 1 2`, plus
  `MP_RLOG: MANIFEST {...}` and the `MP_RLOG: CHK v1 carbon=… human=… bytes=…`
  trailer.
- **Human-readable:** `Client sent message:` — the existing website-parser
  format, e.g. `Client sent message: action:boughtCardFromShop,card:Blueprint,cost:4`.

```bash
lua tests/test_rlog_roundtrip.lua   # streams well-formed + hashes round-trip
lua tests/test_rlog_checksum.lua    # editing one opcode changes the stored hash
```

`test_rlog_roundtrip.lua` asserts: `MP_RLOG: MANIFEST` header + `END`/`CHK`
trailer; carbon action lines with a gapless, monotonic sequence; positional args
including ordered index-lists (e.g. `play 1.3.5.7.8`, `use 1 2.4`) intact; a
paired `Client sent message:` line per action; and `CHK` per-stream hashes that
equal a recompute over the captured lines and match what `submit_log_hashes`
sends.

`test_rlog_checksum.lua` confirms the `CHK` carbon hash equals a hash of the
carbon stream (re-extracted by prefix) and that tampering with one opcode
changes it.

### Manual end-to-end check

Play one real multiplayer match, then open the Lovely log. Filter the `MP_RLOG:`
(positional) and `Client sent message:` (human) lines and confirm they mirror
each action event-for-event.
