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
- Rework center definitions (`MP.ReworkCenter` calls) — see the rework determinism test below

## Rework Determinism + Desync-Safety

`test_rework_determinism.lua` backstops the part the shape snapshot explicitly skips: the `MP.ReworkCenter` / `MP.ApplyReworks` / `MP.PreviewReworks` center-mutation path. It loads the real `rulesets/_rulesets.lua`, registers the shipped reworks (the multi-layer `m_glass`, the rarity-bumped `j_sixth_sense`), then drives the mechanism through hostile call histories (preview ruleset Y then apply X, apply twice, fake menu cycles) and asserts:

- **D1 — determinism:** a reworked center's effective props are a pure function of the resolved context (ruleset + layers + modifiers), identical regardless of preview/cycle/call-count history.
- **D2 — desync-safety:** the rarity-pool *order* is byte-identical across divergent histories; the membership predicate matches vanilla `game.lua` (`not wip`, `not demo`, `set == 'Joker'`); previews never mutate live centers or pools; the frozen baseline rejects writes.

Like the shape snapshot it is necessary-not-sufficient — it stubs game globals rather than running the real engine — but it exercises the mutation path the shape test cannot.

```bash
lua tests/test_rework_determinism.lua
```
