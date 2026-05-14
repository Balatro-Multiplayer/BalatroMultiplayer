# PvP timer refactor

Tasklist for `stephenkirk/refactor-pvp-timer` (squashed from #420).

- [x] Remove the Experimental (No Balance) ruleset
- [x] Allow enabling modifiers on any ruleset that doesn't force lobby settings
- [x] Add Small World to the modifier pane
- [x] Split "Modifiers..." out from "Create Lobby" — show both buttons instead of replacing
- [ ] Clean up / investigate ice_cream + seltzer overrides — make sure they aren't always overriding
- [ ] Remove or fold `is_any_layer_active` into `is_layer_active` (overload? variadic?)
