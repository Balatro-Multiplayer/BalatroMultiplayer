# Tests

Run commands from the repository root. Headless tests use stubbed game globals;
they do not require Balatro. Use LuaJIT unless a command below specifies `lua`.
Shared stubs are in `_stubs.lua`.

## Headless tests

| Command | Coverage |
| --- | --- |
| `luajit tests/test_mutator_registry.lua` | Mutator metadata, category/order uniqueness, layer flags, variants, and Chaos Clock eligibility. |
| `luajit tests/test_multiplayer_content.lua` | MP card pool gating; Base/On/Off overrides; pool-slot parity across multiplayer, solo, and practice; lobby options; modifier encoding; replay pool reconstruction. |
| `luajit tests/test_custom_multiplayer.lua` | Custom editor navigation, lobby creation, variant labels, host/guest rule readouts, and live overlay updates. Also runs the multiplayer-content tests. |
| `luajit tests/test_rng_determinism.lua` | Seeded RNG and Chaos Clock schedules across clients with different query orders and unrelated RNG work; preset severity rates. |
| `luajit tests/test_round_deltas.lua` | Glass Cannon hand-count changes, deck stacking, the one-hand minimum, and application/restoration of temporary clock effects. |
| `luajit tests/test_chaos_forecast.lua` | Forecast/application agreement across seeds and antes, divergent blind skips, run-long effects, and hidden instant effects. |
| `lua tests/test_rlog_roundtrip.lua` | Replay-log framing, action sequence, positional arguments, paired human-readable lines, and checksum round-trip. |
| `lua tests/test_rlog_checksum.lua` | Carbon-stream checksum recomputation and detection of edited opcodes. |
| `lua tests/test_rlog_stream.lua` | Replay-log batching, complete delivery, and consistent game IDs across streamed lines and final hash submission. |
| `lua tests/test_serialization_guard.lua` | Reject oversized or non-string payloads before decoding; round-trip a small payload with stubbed codecs. |

The multiplayer tests exercise the client sender and guest dispatcher with
mocked transport. Modifier tests simulate the relay's 64-character field limit,
including selections taken from truncated lobby messages. They do not connect
to a server or start a game.

The RNG test requires LuaJIT because vanilla `pseudorandom` seeds `math.random`
with a fraction.

### Ruleset snapshot

```bash
lua tests/test_ruleset_shape.lua test
```

Compares ruleset ban/rework lists, scalar fields, and function-hook presence
against `tests/ruleset_shape.snapshot.lua`. It does not compare function bodies,
run hooks, or check `MP.ReworkCenter` definitions.

The snapshot currently has known failures from stale expectations and the
loader not finding nested ruleset files. Do not regenerate it merely to clear
those failures.

After an intentional ruleset structure change:

```bash
lua tests/test_ruleset_shape.lua capture
```

Review the diff in `tests/ruleset_shape.snapshot.lua` before committing.

## In-game scenarios

Requirements:

- macOS with Balatro, Lovely, and the mod's dependencies installed.
- `Mods/BalatroMultiplayer` points to the checkout being tested.
- Balatro is closed before starting a scenario.
- The screen stays unlocked and awake; LÖVE can block in `present()` otherwise.

```bash
bash scripts/run_scenario.sh custom_wall
bash scripts/run_scenario.sh custom_multiplayer
bash scripts/run_scenario.sh chaos_run
bash scripts/run_scenario.sh glass_cannon
bash scripts/run_scenario.sh mp_content
```

| Scenario | Coverage |
| --- | --- |
| `custom_wall` | Editor states, selection counts, Idol variants, and Mystery Mix. |
| `custom_multiplayer` | Multiplayer editor, gamemode Back navigation, and rules overlay updates/layout. Does not create a network lobby. |
| `chaos_run` | Mayhem clock in practice, exclusion of already-selected effects, and sandbox groups. |
| `glass_cannon` | Black Deck plus Glass Cannon reaching the one-hand minimum. |
| `mp_content` | MP Jokers Base/On/Off pools in practice and MP Jokers through a solo round. |

The script launches the game, waits for it to exit, and reports `MP_SCENARIO`
lines from the Lovely log. Exit status is zero only when the scenario reports
`DONE` with no failures. Screenshots are saved to `.context/scenarios/<name>/`.

Set `BALATRO_DIR` to override the Steam game directory or `SCENARIO_TIMEOUT`
to override the default 120-second timeout.

Scenarios live in `tests/scenarios/`. `core.lua` loads `_runner.lua` only when
`MP_SCENARIO` is set. The runner suppresses the development-warning modal for
that process without changing `.env`.

## Manual multiplayer checks

Use two clients running the same mod revision.

1. Create Lobby → Custom. Select a base, MP Jokers setting, timer/glass
   variants, several modifiers, and a Chaos Clock preset.
2. Go Next → Back and check that selections are preserved. Create the lobby
   with the chosen gamemode. Also check Experimental's forced Attrition route.
3. Join with the second client. Compare View Rules on both clients, including
   a selection whose comma-separated names would exceed 64 characters.
4. Leave View Rules open on the guest. Toggle MP Jokers in the host's Lobby
   Options and check that the guest readout updates.
5. Start a seeded match. Compare forecasts, take different skip paths, and
   check that future forecasts agree and selected effects run.
6. Create and start a preset lobby. Check that View Rules is also available
   for locked rulesets without Lobby Options.

### Replay logs

After a match, compare the action streams in the Lovely log:

- Positional: `MP_RLOG:`, including the `MANIFEST` header and `END`/`CHK` trailer.
- Human-readable: `Client sent message:`, for example
  `action:boughtCardFromShop,card:Blueprint,cost:4`.

Each recorded action should have a corresponding entry in both streams.
