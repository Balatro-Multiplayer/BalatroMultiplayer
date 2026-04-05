# Practice Mode Review Pass

## Progress

- [x] **Step 1** — Remove `MP.MATCH_RECORD` code path *(commit 0243980)*
- [x] **Step 2** — Move `MP.is_mp_or_ghost()` out of UI file *(commit 0607874)*
- [x] **Step 3** — Rename `M` in `log_parser.lua` to `LOG_PARSER` *(commit b677a0e)*
- [x] **Step 4** — Extract JSON loading to local function in `match_history.lua` *(commit e8d976b)*
- [x] **Step 5** — Move data helpers from `ghost_replay_picker.lua` to `lib/match_history.lua` *(commit 2ca08f8)*
- [ ] **Step 6** — Move practice mode logic to its own `lib/` file
- [ ] **Step 7** — Update stale comments

---

## Step 1 — Remove `MP.MATCH_RECORD` code path
**Comment #5** (match_history.lua:49-58)

Snapshot/recording machinery is dead code — written but never read. Replays come from log files.

- Remove `MP.MATCH_RECORD` table, `reset()`, `init()`, `snapshot_ante()`, `finalize()`
- Remove callers in `networking/action_handlers.lua` (init, snapshot_ante, 2x finalize)
- Remove callers in `ui/game/game_state.lua` (5x finalize)
- Update file header comment

**Files:** `lib/match_history.lua`, `networking/action_handlers.lua`, `ui/game/game_state.lua`

---

## Step 2 — Move `MP.is_mp_or_ghost()` out of UI file
**Comment #7** (game_state.lua:4-6)

`MP.is_mp_or_ghost()` is a utility predicate — shouldn't live in a UI file that monkey-patches Game methods.

- Move the function definition to `lib/match_history.lua` (where `MP.GHOST` lives)
- Verify load order: `match_history.lua` must be loaded before `game_state.lua`
- Grep all callers to confirm nothing breaks

**Files:** `ui/game/game_state.lua`, `lib/match_history.lua`

---

## Step 3 — Rename `M` in `log_parser.lua` to MP-namespace
**Comment #1** (log_parser.lua:4)

The log parser uses `local M = {}` as its module table. Should use something in the MP namespace.

- Propose a few name options to the user before changing
- Replace `M` throughout the file once agreed
- Check callers (`MP.load_mp_file("lib/log_parser.lua")` returns the module — callers may not care about the internal name, but verify)

**Files:** `lib/log_parser.lua`

---

## Step 4 — Extract JSON loading to local function in `match_history.lua`
**Comment #4** (match_history.lua:214-266)

The `.log` path should be the main code path. The `.json` path is mostly for verifying the Lua log parser produces the same output as the Python tool.

- Extract the `.json` loading branch into a `local function load_json_replay(filepath, filename)`
- Add a comment explaining it's for verification against the Python tool
- Keep `.log` path as the primary inline code

**Files:** `lib/match_history.lua`

---

## Step 5 — Move data-loading logic from picker to `lib/match_history.lua`
**Comment #8** (ghost_replay_picker.lua:1-3)

Some non-UI logic in the picker should live in the lib layer.

- Identify functions in `ghost_replay_picker.lua` that are data-processing (not UI)
- Move them to `lib/match_history.lua`
- Picker keeps only UI layout and event handlers

**Files:** `ui/main_menu/play_button/ghost_replay_picker.lua`, `lib/match_history.lua`

---

## Step 6 — Move practice mode logic to its own `lib/` file
**Comment #6** (play_button_callbacks.lua:2-6)

`MP.SP`, `MP.is_practice_mode()`, and setup/start logic should live in `lib/practice_mode.lua`, not a UI callbacks file. Also clarify the naming situation (`MP.SP`, `MP.GHOST`, `MP.SP.practice`, `MP.is_practice_mode()`).

- Create `lib/practice_mode.lua`
- Move `MP.SP` table definition + `MP.is_practice_mode()` there
- Move `G.FUNCS.setup_practice_mode()` and `G.FUNCS.start_practice_run()` there
- Move `G.FUNCS.toggle_unlimited_slots()` there
- Wire up in `core.lua` load order
- Consider renaming / documenting the SP/GHOST/practice relationship

**Files:** `lib/practice_mode.lua` (new), `ui/main_menu/play_button/play_button_callbacks.lua`, `core.lua`

---

## Step 7 — Update stale comments
**Comments #2 and #3** (match_history.lua:1-12, match_history.lua:209-212)

After all structural changes, update comments to reflect reality.

- Rewrite file header for `match_history.lua` (no longer about "data capture" / persistence)
- Update the `load_folder_replays` comment (no longer just JSON; log files are primary)

**Files:** `lib/match_history.lua`
