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
replay logger (`lib/replay_log.lua`). They stub the game globals, write a real
`.carbon` file into `tests/`, parse it back, and clean up after themselves.

```bash
lua tests/test_rlog_roundtrip.lua   # stream is well-formed + hashes round-trip
lua tests/test_rlog_checksum.lua    # editing one opcode changes the stored hash
```

`test_rlog_roundtrip.lua` asserts: manifest header + `END`/`CHK` trailer present;
every `A` (positional) line is paired with an `H` (human) line by a gapless,
monotonic sequence number; positional args including ordered index-lists (e.g.
`play 1.3.5.7.8`, `use 1 2.4`) round-trip exactly; the `CHK` per-stream hashes
equal a recompute over the parsed lines and match what `submit_log_hashes` sends.

`test_rlog_checksum.lua` confirms the `CHK` carbon hash equals a hash of the
carbon stream and that tampering with a single opcode changes it.

### Manual end-to-end check

Play one real multiplayer match, then open the `.carbon` file Lovely wrote next
to its log (same name, `.carbon` extension). Read the `A` (positional) and `H`
(human) lines side by side and confirm they mirror each action event-for-event,
and that the player-facing Lovely log itself is unchanged from before.
