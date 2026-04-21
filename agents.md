# Balatro Multiplayer Mod

> This is an `agents.md` — a repo-level orientation doc written for coding agents (Claude Code, Cursor, etc.) but perfectly readable by humans too. It's the "what is this project and how does it fit together" briefing you'd give a new contributor on day one.
>
> **The mod**: head-to-head (and co-op, solo endurance) Balatro. Two players, same seed, same shops, same packs — but at boss blinds you play against the opponent's live chip score. Built as a Steamodded mod with Lovely patches on top of vanilla Balatro. Server is a thin TCP relay; both clients simulate the game locally and only sync opponent scores.

## Stack

- **Balatro** (>=1.0.1o) — LÖVE2D poker roguelike. Vanilla source at `../Balatro-Src/` for reference.
- **Lovely** (>=0.8) — Binary patcher/injector for LÖVE2D games. Patches in `lovely/*.toml` do regex/pattern matching on vanilla Lua source to inject mod code at load time. Can also target SMODS source via `=[SMODS _ "src/..."]`.
- **Steamodded (SMODS)** (>=1.0.0~BETA) — Balatro mod loader/API. Provides `SMODS.GameObject`, `SMODS.Atlas`, `SMODS.load_file`, `SMODS.calculate_context`, `SMODS.current_mod`, center pool injection, loc_text processing. **Gotcha**: `SMODS.GameObject` validates `required_params` during the constructor (`__call`), *not* during `inject()`. Any fields that must pass validation need to exist on the init table before construction — they cannot be deferred to `inject()`.

## Entry Point

`Multiplayer.json` — SMODS mod manifest (id: `Multiplayer`, prefix: `mp`). Loads `core.lua` as main file.

`core.lua` initializes the global `MP` table (= `SMODS.current_mod`) and loads everything via `MP.load_mp_file` / `MP.load_mp_dir` (wraps `SMODS.load_file`). Load order: `lib/` → `overrides/` → `compatibility/` → `networking/` → `gamemodes/` → `layers/` → `rulesets/` → `ui/` → `objects/`.

## Key Globals

- `MP` — Mod root. Contains `LOBBY`, `GAME`, `UI`, `ACTIONS`, `UTILS`, `INSANE_INT`, `EXPERIMENTAL`, `SANDBOX`, etc.
- `MP.LOBBY` — Lobby state (code, config, host/guest, deck selection, ruleset, gamemode).
- `MP.GAME` — In-game state (lives, enemy state, timer, scores, stats).
- `MP.ACTIONS` — Network action handlers (send/receive).
- `Client.send({action = "...", ...})` — Send message to server.
- `G` — Balatro's global game state (vanilla).

## Hooking Patterns

Three layers of hooks, from deepest to highest-level:

1. **Lovely patches** (`lovely/*.toml`): Pattern-match vanilla source strings and inject code at/before/after match points. Used for deep hooks into game state (round eval, dollar calculation, blind selection, shop flow, card initialization for sticker support).
2. **Lua overrides** (`overrides/`): Store function reference (`local fn_ref = SomeFunc`), redefine, call original inside. Used for wrapping vanilla/global functions with MP-specific behavior. Hooks: `ease_dollars`, `Card:sell_card`, `G.FUNCS.reroll_shop`, `G.FUNCS.buy_from_shop`, `G.FUNCS.use_card`, `G.FUNCS.evaluate_round`.
3. **SMODS APIs**: `SMODS.calculate_context` for joker/card evaluation hooks. `SMODS.GameObject:extend` for custom object types (Gamemode, Ruleset).

## Networking

TCP socket via `love.socket` running on a separate LÖVE thread (`love.thread.newThread`). Communication via `love.thread.getChannel` — two channels: `uiToNetwork` (client→server) and `networkToUi` (server→client). JSON-encoded messages. Server at configurable URL (default: `balatro.virtualized.dev:8788`).

`Client.send()` pushes JSON to the outbound channel. `MP.ACTIONS.*` functions in `networking/action_handlers.lua` handle inbound server messages.

## Gameplay Loop

A match follows vanilla Balatro's ante structure (small blind → big blind → boss blind → shop), but with a life system and PvP blinds layered on top. Both players play simultaneously from the same seed.

### Ante Structure & PvP Blinds

- **Ante 1** is always vanilla blinds (no PvP). Players build their decks independently.
- **Ante 2+** (Attrition): the boss blind slot is replaced by `bl_mp_nemesis` — the PvP blind. Small and big blinds remain vanilla.
- **Ante 3+** (Showdown): *all three* blind slots become `bl_mp_nemesis`.
- **Survival**: no PvP blinds ever — pure solo endurance with 1 life.

During a PvP blind, the score target is the **opponent's actual score**, received over the network in real-time. A 3-second countdown precedes each PvP blind. Players play hands to beat the opponent's chip total before running out of hands.

### Life System

- **Default starting lives: 4** (Survival forces 1, Sandbox forces 4).
- Failing a PvP blind (chips < opponent's score when hands run out) costs **1 life**.
- On life loss, the player receives **4 gold** compensation (2 gold at Stake 6+; Sandbox scales as `3 × (ante - 1)`).
- **Game over** when lives reach 0 — server sends `loseGame`/`winGame` to the respective players.

### Timer

- Active during PvP blinds only. Default **150 seconds** per ante (MajorLeague: 180s, MinorLeague: 210s).
- On timeout: if `timer_forgiveness > 0`, one free pass; otherwise the round auto-fails.

### Network Messages During Play

The server is a relay, not an authority. Key messages:
- `playHand(score, handsLeft)` — sent after each hand played.
- `enemyInfo(score, handsLeft, skips, lives)` — server broadcasts opponent state to both clients every ~3 seconds.
- `endPvP` — server signals both clients that the PvP round is over.
- `loseGame` / `winGame` — terminal state.

## Sync Model

Both players run the **same game locally from the same seed** — there is no authoritative server simulating the game. The lobby seed is set by the host and shared at game start. All RNG (shop offerings, pack contents, boss blind selection, tags, joker pool order) is derived deterministically from that seed on each client independently. Both players see the same shops, same packs, same blinds.

Because Balatro's RNG uses per-slot pseudorandom queues (not a single sequential stream), player choices (buying vs skipping a joker, picking different cards) do **not** desync the RNG state — both clients stay in sync regardless of divergent play decisions.

The **only networked gameplay data** is the opponent's score during PvP blinds. Everything else (cards dealt, joker effects, shop contents) remains locally deterministic.

## Gamemodes

`MP.Gamemode` (`gamemodes/_gamemodes.lua`) extends `SMODS.GameObject`, stored in `MP.Gamemodes[]` and `G.P_CENTER_POOLS.Gamemode`. Each gamemode defines `get_blinds_by_ante(ante)` → `(small, big, boss)` override keys (or `nil` for vanilla), its own ban lists, and a `create_info_menu()` for UI.

### Attrition
The standard head-to-head mode. Normal blinds until `pvp_start_round`, then boss blind becomes `bl_mp_nemesis` (the PvP blind). Bans blind-trivializing jokers (`j_mr_bones`, `j_luchador`, `j_matador`, `j_chicot`), ante-manipulation vouchers (`v_hieroglyph`, `v_petroglyph`, `v_directors_cut`, `v_retcon`), `tag_boss`, and unbalanced PvP blinds (`bl_wall`, `bl_final_vessel`).

### Showdown
Intensive PvP variant. Normal blinds until `showdown_starting_antes`, then *all three* blind slots become `bl_mp_nemesis`. Same bans as Attrition.

### Survival
Solo endurance — 1 life, no PvP blinds at all (all vanilla). Bans adversarial MP jokers (`j_mp_conjoined_joker`, `j_mp_defensive_joker`, `j_mp_penny_pincher`, `j_mp_pizza`, etc.) and `c_mp_asteroid`. Forces `starting_lives = 1` and `disable_live_and_timer_hud = true`.

## Rulesets & Layers

### Overview

`MP.Ruleset` (`rulesets/_rulesets.lua`) extends `SMODS.GameObject`, stored in `MP.Rulesets[]`. Rulesets are now composed from **layers** — reusable bundles of ban lists, rework lists, scalars, and runtime hooks. A ruleset definition is typically 3–5 lines pointing at its layers plus any ruleset-specific overrides.

### Layers

`MP.Layer(name, definition)` (`layers/_layers.lua`) registers a named bundle in `MP.Layers`. Definitions live in `layers/*.lua`.

| Layer | Purpose |
|---|---|
| `standard` | MP jokers enabled, standard bans (hanging chad, ticket, seltzer, turtle bean, bloodstone, ouija, justice) + reworks (glass, hanging chad, etc.) |
| `sandbox` | Parallel joker pool, idol selection, extra credit gating, vanilla-counterpart bans |
| `smallworld` | 75% random ban cull, showman override, tag/voucher/joker replacement logic |
| `speedlatro_timer` | Per-round countdown timer (147s base) replacing the normal PvP timer |
| `ranked` | Version-gated, lobby locked, the_order forced |
| `classic` | Pre-MP-joker-era card pool (multiplayer_content = false, glass rework only) |

### Merge semantics

`MP.resolve_layers(init)` runs **before** SMODS construction (because SMODS validates `required_params` in `__call`, not `inject()`). Left-to-right:
- **Array fields** (`banned_*`, `reworked_*`): concatenated (union of all layers + ruleset additions)
- **Scalar fields**: first layer wins; ruleset-level always overrides
- Missing `banned_*`/`reworked_*` arrays default to `{}`

### Runtime query: `MP.is_layer_active(name)`

Returns true if the active ruleset composes that layer OR if the ruleset's own short name matches. Replaces the old `is_standard_ruleset()` and most `is_ruleset_active()` usage. Use this to gate runtime behavior (e.g., `mp_include` on jokers).

### How to write / modify a ruleset

**Minimal (layer-only):**
```lua
MP.Ruleset({
    key = "blitz",
    layers = { "standard" },
}):inject()
```

**With overrides:**
```lua
MP.Ruleset({
    key = "traditional",
    layers = { "standard" },
    banned_jokers = { "j_mp_speedrun", "j_mp_conjoined_joker" },  -- merged into standard's bans
    force_lobby_options = function(self)
        MP.LOBBY.config.timer = false
        return false  -- false = soft defaults, host can override
    end,
}):inject()
```

**Layerless (standalone):**
```lua
MP.Ruleset({
    key = "vanilla",
    multiplayer_content = false,
    banned_jokers = {}, banned_consumables = {}, banned_vouchers = {},
    banned_enhancements = {}, banned_tags = {}, banned_blinds = {},
    reworked_jokers = {}, reworked_consumables = {}, reworked_vouchers = {},
    reworked_enhancements = {}, reworked_tags = {}, reworked_blinds = {},
}):inject()
```

**Fields that live on the ruleset** (not in layers): `forced_gamemode`, `force_lobby_options` (when ruleset-specific), `forced_lobby_options` (when not from a layer like `ranked`).

**Fields that live in layers** (shared behavior): ban/rework lists, `multiplayer_content`, `on_apply_bans` hooks, `is_disabled`, `standard` flag.

### The Ban System

`MP.ApplyBans()` merges bans from three sources into `G.GAME.banned_keys` at game start:
1. **Ruleset** — `ruleset["banned_" .. category]` (already merged from layers)
2. **Gamemode** — `gamemode["banned_" .. category]`
3. **Deck** — `MP.DECK["BANNED_" .. category]` (deck-specific compat bans)

Then `MP.RunLayerHooks("on_apply_bans")` fires each layer's hook in order. Used by sandbox (idol selection, extra credit gating) and smallworld (75% random cull).

`banned_silent` adds hidden bans not shown in UI (used to hide vanilla counterparts of reworked cards).

### The Rework System

There are **two paths** for reworking a card. They serve different purposes.

#### Path A: Full reimplementation (SMODS.Joker / SMODS.Consumable / etc.)

You write a brand-new card with its own key, logic, and loc_txt. The vanilla card is silently banned; yours takes its place in the pool.

**This is what we use for joker reworks.** `ReworkCenter` mutates center properties on the existing card, which can desync the shop queue — Balatro's RNG pool system has already indexed the original center by the time reworks load, so mutating joker config mid-run risks desyncing the pseudorandom joker ordering between clients. Reimplementing as a new card with a fresh key avoids this entirely.

Steps:
1. Create the new card via `SMODS.Joker({ key = "hanging_chad", ... })`
2. Gate it: `mp_include = function(self) return MP.is_layer_active("standard") and MP.LOBBY.code end`
3. Add the vanilla key to the layer's `banned_silent` (hides it from pool)
4. Add your new key to the layer's `reworked_jokers` (shows it in info panel)

#### Path B: `ReworkCenter` (property patching)

Overrides config, loc text, and/or logic on an existing center without creating a new key. Cleaner API, less boilerplate — good for enhancements, consumables, tags, stakes, blinds, and poker hands.

```lua
MP.ReworkCenter("m_glass", {
    layers = "standard",           -- string or array of strings
    config = { Xmult = 1.5, extra = 4 },
})
```

Registration stores properties as `mp_<layer>_<prop>` on the center. `MP.LoadReworks(ruleset)` resolves in order: **vanilla → layers (in `_layer_order`) → ruleset self-name**. Later layers override earlier ones. Ruleset-specific registrations override everything (escape hatch for one-off rulesets).

**Why not for jokers:** `ReworkCenter` mutates `G.P_CENTERS[key]` properties. Balatro's shop pool generation reads center config during pseudorandom selection. If you change a joker's rarity or config after pool generation has already used the original values, the two clients can diverge. Enhancements/consumables/tags don't go through the same shop queue machinery, so they're safe.

### Wiring gotcha (important!)

A layer's `reworked_jokers` / `reworked_consumables` / etc. arrays are **display metadata only** — they control what shows up in the ruleset info panel. The actual runtime rework is a completely separate system:
- For Path A: the `SMODS.Joker` definition + `mp_include` + `banned_silent` entry
- For Path B: the `MP.ReworkCenter(key, { layers = "..." })` call

You need **both** the display entry in the layer AND the runtime wiring. Neither implies the other.

### Ruleset Details

| Ruleset | Layers | `forced_gamemode` | Lobby locked | Distinct behavior |
|---|---|---|---|---|
| **Ranked** | standard, ranked | Attrition | yes | The Order on, SMODS version-gated |
| **Blitz** | standard | — | no | Default ruleset for new lobbies |
| **Traditional** | standard | — | no | Timer disabled, bans speedrun + conjoined |
| **SmallWorld** | standard, smallworld | — | no | 75% of items pseudorandomly banned per seed |
| **Speedlatro** | standard, speedlatro_timer | Attrition | no | Per-round countdown timer |
| **Chaos** | standard, sandbox, smallworld, speedlatro_timer | — | no | Everything composed together |
| **Sandbox** | sandbox | — | yes | Parallel joker pool, idol selection, preview disabled, The Order on, 4 lives |
| **Legacy Ranked** | classic, ranked | Attrition | yes | Pre-MP-joker card pool, version-gated |
| **Vanilla** | *(none)* | — | no | No bans, no reworks, no MP jokers |
| **Badlatro** | *(none)* | — | no | 37 joker bans, heavy restrictions |
| **MajorLeague** | *(none)* | Attrition | yes | 180s timer, 1 forgiveness, no Order |
| **MinorLeague** | *(none)* | Attrition | yes | 210s timer, 1 forgiveness, The Order on |

### `forced_gamemode` Mechanism

When a ruleset has `forced_gamemode`, the "Next" button in ruleset selection becomes "Create Lobby" and directly sets `MP.LOBBY.config.gamemode`, skipping the gamemode selection screen. Rulesets without it show the gamemode picker.

### `force_lobby_options` and `forced_config`

`G.FUNCS.start_lobby` calls `ruleset.force_lobby_options()`. Returning `true` = fully locked (host can't change settings). Returning `false` = soft defaults applied, host can still override. Result is stored in `MP.LOBBY.config.forced_config`. `multiplayer_content` is also set here to gate the `j_mp_*` pool.

### Sandbox Layer (Detail)

The most complex layer. `MP.SANDBOX` (defined in `layers/sandbox.lua`) manages a parallel joker pool:
- `joker_mappings` links ~35 sandbox joker keys (`j_mp_*_sandbox`) to vanilla counterparts (or `nil` for originals). Tracks active/out-of-rotation status.
- `get_vanilla_bans()` silently bans vanilla versions of active sandbox jokers.
- `is_joker_allowed(key)` gates card pools — checks `is_layer_active("sandbox")` internally.
- `on_apply_bans` hook: idol selection (`select_random_idol` pseudorandomly picks one of two idol variants seeded on lobby code) + extra credit gating (bans sandbox EC jokers if `extracredit` mod is loaded).
- Reworked joker list is Fisher-Yates shuffled at load time for randomized UI panel order.

## Joker Implementation Model

1. Register optional art via `SMODS.Atlas`, then call `SMODS.Joker` with metadata (rarity, cost, compat flags) plus `config.extra` to seed per-card state.
2. `loc_txt` holds name/description templates; `loc_vars` returns dynamic numbers and color tags injected into that text.
3. Runtime behavior via `calculate(context)` — inspects context table (`context.joker_main`, `context.individual`, `context.end_of_round`, etc.) and returns chip/mult/xmult values or UI messages. Other hooks: `add_to_deck`, `remove_from_deck`, `mp_include` (pool gating).
4. MP-only cards gate on `MP.LOBBY.multiplayer_jokers` and `MP.is_layer_active("standard")`. Sandbox variants also call `MP.SANDBOX.is_joker_allowed`.
5. Balanced sticker: Lovely patches auto-apply sticker to any card flagged as reworked for the active ruleset (or with `mp_sticker_balanced` in config) during `Card` initialization.
6. Sandbox rotation: `joker_mappings` links sandbox keys to vanilla ancestors, controls active status, silently bans vanilla when sandbox is live.

## Compatibility

`core.lua` hard-bans incompatible mods via `MP.BANNED_MODS` and exposes integrations (e.g., Preview) through `MP.INTEGRATIONS` for opt-in/out without hard dependencies.

The `compatibility/` tree contains targeted shims for popular mods (Pokermon, StrangePencil, TooManyJokers, AntePreview, etc.). Each shim can push additional bans through `MP.DECK.ban_*` helpers or inject UI/logic so shared content cooperates.

## Config

`config.lua` — User-local settings (username, server URL/port, integrations, match history). Loaded by SMODS.
