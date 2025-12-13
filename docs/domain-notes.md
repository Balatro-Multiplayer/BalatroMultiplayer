# Balatro Multiplayer Domain Notes

## Rulesets
- `MP.Ruleset` (`rulesets/_rulesets.lua`) wraps `SMODS.GameObject`, enforces required fields (bans, reworks, lobby hooks) and injects each ruleset into `G.P_CENTER_POOLS.Ruleset`.
- `MP.ApplyBans` merges bans from the active ruleset, the forced gamemode, and deck-level compatibility bans before every run; silent bans hide vanilla counterparts that were replaced.
- `MP.ReworkCenter` stores per-ruleset overrides (config, loc text, logic) on each `G.P_CENTERS` entry; `MP.LoadReworks` copies the `mp_<ruleset>_*` values onto the live center when lobbies or runs load.
- Sandbox ruleset config (`rulesets/sandbox.lua`) centralizes reworked Joker availability in `MP.SANDBOX.joker_mappings`, bans vanilla versions via `get_vanilla_bans`, and exposes `MP.SANDBOX.is_joker_allowed` to gate card pools.
- Sandbox forces deterministic lobby options (Preview off, The Order on, 4 lives) and overrides idol availability each run via `select_random_idol` seeded on the lobby code.
- UI uses each ruleset’s `reworked_*` lists to populate the Ruleset Info dialog; sandbox also injects placeholder “error” Jokers so the panel stays full even when few reworks are active.

## Dependencies and Cross-Mod Hooks
- Core mod stack: Steamodded (`SMODS`) supplies mod lifecycle (`SMODS.current_mod`, asset loading, atlas registration) and object helpers (`SMODS.Joker`, `SMODS.GameObject`); Lovely Injector applies `.toml` patches that tweak base `card.lua`, UI definitions, and HUD behavior.
- Filesystem helpers rely on Love2D namespaces: `NFS` (Steamodded shim for love.filesystem) drives `MP.load_mp_dir`, `love.system` handles clipboard access, and `love.thread` runs the socket worker defined in `networking/socket.lua`.
- Networking uses LuaSocket’s TCP API with a background thread that relays packets over two Love2D channels (`uiToNetwork`, `networkToUi`); client-side actions live in `networking/action_handlers.lua`.
- `core.lua` hard-bans incompatible mods via `MP.BANNED_MODS` and exposes integrations (e.g., Preview) through `MP.INTEGRATIONS` so other mods can opt in/out without hard dependencies.
- The `compatibility` tree contains targeted shims for popular mods (`Pokermon`, `StrangePencil`, `TooManyJokers`, `AntePreview`, etc.); each shim can push additional bans through `MP.DECK.ban_*` helpers or inject UI/logic so shared content cooperates.
- Vanilla reference data lives in `Balatro___Jokers.md`, providing the canonical ability list that sandbox reworks cite when recreating or altering cards.

## Joker Implementation Model
- Every new Joker registers optional art via `SMODS.Atlas` (if custom sprite) and then calls `SMODS.Joker` with metadata (rarity, cost, compatibility flags) plus `config.extra` to seed per-card state.
- `loc_txt` holds name/description templates; `loc_vars` returns the dynamic numbers and color tags injected into that text.
- Runtime behavior is driven through `calculate`, which inspects the context table (`context.joker_main`, `context.individual`, `context.end_of_round`, etc.) and may return chip/mult/xmult values or UI messages; other hooks like `add_to_deck`, `remove_from_deck`, and `mp_include` manage lifecycle and pool gating.
- Multiplayer-only cards lean on `MP.LOBBY` toggles (e.g., `multiplayer_jokers`) and `MP.UTILS.is_standard_ruleset()` so they never leak into unsupported rulesets; sandbox variants additionally call `MP.SANDBOX.is_joker_allowed`.
- Balanced sticker support is automated via Lovely patches—any card flagged as reworked for the active ruleset (or with `mp_sticker_balanced` in its config) gains the sticker during `Card` initialization.
- Sandbox rotation: `MP.SANDBOX.joker_mappings` links every sandbox card key to its vanilla ancestor, controls whether it is active, and silently bans the vanilla version whenever the sandbox ruleset is live.

## Sandbox Mystic Summit Rework
- Implemented via `MP.ReworkCenter` (`objects/jokers/sandbox/mystic_summit.lua`); sandbox replaces the vanilla “all discards spent” trigger with a scaling reward for banking unused discards.
- `config.extra` tracks `current_per_discard`, `base_per_discard`, growth per unused discard (`growth_per_discard`), and an upper cap (`max_per_discard`).
- During scoring the Joker adds `unused_discards * current_per_discard` Mult; finishing a round with unused discards permanently increases the per-discard value (capped), while spending every discard snaps it back to the base value.
- Custom localization text documents the new loop, and the ruleset UI now lists `j_mystic_summit` alongside bespoke sandbox Jokers so players immediately see the rework when hosting a sandbox lobby.
