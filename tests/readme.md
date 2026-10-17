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

## Mutator registry

`test_multiplayer_content.lua` registers the original MP cards and checks native
layer gating, Base/On/Off overrides, and exact pool-slot parity between live,
solo, and practice contexts. It also exercises the lobby checkbox, wire
round-trip, legacy booleans, and recorded pool settings through replay loading.

```bash
luajit tests/test_multiplayer_content.lua
```

`test_mutator_registry.lua` loads every layer and checks the custom editor's
wall (`MP.MUTATORS`, filled by `mutator = {...}` on each layer) against the
layers behind it: known category, label + desc, unique `(category, order)`
slot, live cells whose layer actually does something, every `flag` read
somewhere, variant cells pointing at real layers, Chaos Clock specs
(`at` / `lasts` / `severity`) valid and present on every switchable cell, the
clock pool skipping On cells, and on state plus the clock preset surviving the `modifier_layers`
sync string.

```bash
luajit tests/test_mutator_registry.lua
```

## RNG determinism

`test_rng_determinism.lua` simulates two clients on one seed that do different
amounts of unrelated RNG work and query in a different order, and asserts that
`MP.rng` rolls and the Chaos Clock schedule (ante and per-blind rolls) all
agree. Also checks each preset's per-severity rate, and that Calm never draws
severity 3. LuaJIT only — vanilla
`pseudorandom` seeds `math.random` with a fraction.

```bash
luajit tests/test_rng_determinism.lua
```

## Round deltas

`test_round_deltas.lua` covers layer `round_deltas` through Glass Cannon's -2
hands: stacking with the deck (Black Deck 3 -> 1), the 1-hand floor, and the
Chaos Clock drawing it per ante: applied once, restored when not drawn, moving
the live round's `hands_left`, and leaving an On cell alone.

```bash
luajit tests/test_round_deltas.lua
```

`_stubs.lua` holds the hook-target globals layer files wrap at load time; the
shape test and the tests above load it.

## In-game scenarios

`scenarios/_runner.lua` is loaded by `core.lua` only when `MP_SCENARIO` is set.
A scenario (`scenarios/<name>.lua`) is a list of timed steps that drive the
game, log `MP_SCENARIO PASS|FAIL ...` lines to the Lovely log and save
screenshots to `.context/scenarios/<name>/`.

```bash
bash scripts/run_scenario.sh custom_wall   # editor wall: states, counts, idol, Mystery Mix
bash scripts/run_scenario.sh chaos_run     # practice run: Chaos Clock on Mayhem, On cell skipped, sandbox groups
bash scripts/run_scenario.sh glass_cannon  # Black Deck + Glass Cannon: 1 hand
```

macOS only, needs the `Mods/BalatroMultiplayer` symlink pointing at the
checkout and an unlocked screen (LÖVE blocks in `present()` behind the lock
screen and never leaves the loading screen).

## Chaos Clock forecast

`test_chaos_forecast.lua` runs the clock over 8 antes for 30 seeds on Mayhem
(plus one on Normal) as two clients: one plays every blind, one skips every
Small. It checks that what goes live at a blind is exactly that slot's forecast,
that a skipped blind's draw never goes live, that both clients get the same
forecast every ante, that a run-long pick is never drawn twice, and that
instants show as `?`. A test-only severity 3 blind window (`test_storm`) makes
the skip checks bite: the live pool has none.

```bash
luajit tests/test_chaos_forecast.lua
```
