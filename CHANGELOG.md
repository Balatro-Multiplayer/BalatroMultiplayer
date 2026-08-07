# Changelog

## Blind Raiser Experimental Ruleset

- Added **Experimental (Blind Raiser)** to the Experimental ruleset tab.
- Uses the full **Standard Ranked** ruleset configuration.
- Adds **Upgrade Blind** to every Stake: claim the current Small/Big Blind's Skip Tag and replace that slot with a random non-Showdown Boss Blind without skipping it.
- Blind Raiser boss rolls use separate bookkeeping so choosing an upgrade does not alter future normal Boss rolls in Multiplayer.
- Escalating score requirement: the Nth Blind upgraded this run uses the physical slot's regular score multiplied by **2^N**.
- Ruleset-only Tag reworks are listed under **Reworks → Other**: Investment scales with upgraded Blinds, Negative targets the next base-edition Common shop Joker, and Rare creates a free Rare Joker that empties your money when bought (and cannot roll in Ante 1).

## Ranked Update 0.4.0

### Standard Ranked

#### Jokers

- **To Do List** — Reworked. Now pays $5 (up from $4). Target poker hand is chosen from all hands, not just discovered ones.
- **Golden Ticket** — Reverted payout nerf, now earns $4 (up from $3)
- **Speedrun** — Out of rotation.
- **Ouija** and **Ectoplasm** — Now cost $4 (bug fix).

#### Consumables

- **Justice** — Back in rotation.

#### Economy & Enhancements

- **Gold Card** (Enhancement) — Payout increased from $3 to $4.
- **Comeback Gold** — Now awarded on any life loss again, not just PvP boss losses. Payout amounts ($4, or $2 on higher stakes) are unchanged.

### Quality of Life

- **Balanced Sticker** — Now shows a tooltip explaining what was changed on the card it's attached to.
- **Hotkeys — Menu Shortcuts** — Hold Tab in the menu to see context-sensitive shortcuts. Main menu: **C** creates a lobby, **V** joins from clipboard. In a lobby: **C** copies the code, **L** leaves, **D** picks deck. Disconnected: **R** reconnects.
- **Timer and score preview rework** - TODO
- **Match Replays (Practice Mode)** — Practice against a ghost opponent replayed from a past match. Drop a Lovely log (`.log`) or exported `.json` into the `replays/` folder and it shows up in the replay picker. Accessed via Practice → Ruleset → Replay Picker. Flip perspective to play as either side.

### Legacy Ranked

#### Jokers

- **Hanging Chad** — Reworked. Retriggers first 2 cards instead of first card twice.

## Ranked Update 0.3.0

### Jokers

- **Seltzer** — Lasts 8 hands instead of 10.
- **Turtle Bean** — Grants +4 hand size instead of +5.
- **Golden Ticket** — Earns $3 instead of $4. No longer requires Gold cards in deck. Now Uncommon rarity.
- **Speedrun** — Can now activate for both players if the second player joins within 30 seconds.

### Consumables

- **Ouija** — Destroys 3 cards instead of converting all cards to a single suit and reducing hand size.
- **Judgment** — Now draws from its own queue (vanilla behavior) on Orange Stake and above. Still uses the shop queue on lower stakes.
