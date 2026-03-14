# BMP Cocktail API

**Base URL:** `https://bmp.casjb.co.uk`

## Auth

All endpoints require `x-api-key` header, **except** `GET /cocktails/current`.

---

## Data Model

```
┌─────────────────────────────────┐
│ Cocktail                        │
├─────────────────────────────────┤
│ id        string   PK           │
│ name      string   required     │
│ backs     string[] 1-3 items    │  ← ordered, duplicates allowed
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Current Pointer                 │
├─────────────────────────────────┤
│ cocktail_id   string   FK       │  ← points at one cocktail
└─────────────────────────────────┘

(... or a config table, or whatever)

```

`backs` values are Back center keys:

```
Vanilla:  b_red, b_blue, b_yellow, b_green, b_black, b_magic,
          b_nebula, b_ghost, b_abandoned, b_checkered, b_zodiac,
          b_painted, b_anaglyph, b_plasma, b_erratic

BMP:      b_mp_orange, b_mp_indigo, b_mp_violet, b_mp_white,
          b_mp_oracle, b_mp_gradient, b_mp_heidelberg, b_mp_echodeck
```

No junction table. `backs` is a JSON array column on the cocktail itself.
Duplicates are valid (e.g. `["b_black", "b_black", "b_black"]` for Vantablack).

### Validation rules
- `backs` must have 1-3 entries
- Each entry must be a known Back key (validate against the list above, or skip validation and let the client handle it)
- `id` is unique

---

## Endpoints

### Public

#### `GET /cocktails`
List all cocktails.

```json
// 200
[
  {
    "id": "voidwalker",
    "name": "Voidwalker",
    "backs": ["b_black", "b_nebula", "b_mp_indigo"]
  },
  {
    "id": "vantablack",
    "name": "Vantablack",
    "backs": ["b_black", "b_black", "b_black"]
  }
]
```

### Admin (require `x-api-key`)

#### `POST /cocktails`
Create a cocktail.

```json
// Request
{
  "id": "vantablack",
  "name": "Vantablack",
  "backs": ["b_black", "b_black", "b_black"]
}

// 201
{ "id": "vantablack", "name": "Vantablack", "backs": ["b_black", "b_black", "b_black"] }

// 400
{ "error": "backs must contain 1-3 entries" }
```

#### `GET /cocktails/{id}`
Get a cocktail by ID.

```json
// 200
{ "id": "vantablack", "name": "Vantablack", "backs": ["b_black", "b_black", "b_black"] }

// 404
{ "error": "Not found" }
```

#### `PATCH /cocktails/{id}`
Update a cocktail. All fields optional.

```json
// Request
{ "name": "Triple Black", "backs": ["b_black", "b_black", "b_black"] }

// 200
{ "id": "vantablack", "name": "Triple Black", "backs": ["b_black", "b_black", "b_black"] }
```

#### `DELETE /cocktails/{id}`
Delete a cocktail.

```
// 204 — no body
```

---

## Example: weekly rotation

This is how we'd use it for a "weekly cocktail" feature, but the API itself
is generic - the pointer could be moved for events, testing, whatever.

1. Build a library of cocktails via `POST /cocktails`
2. Each week, `PUT /cocktails/current` with the next cocktail's ID
3. Mod clients call `GET /cocktails/current` and get the backs array

### Public

#### `GET /cocktails/current`
Returns whichever cocktail the pointer is aimed at. 

```json
// 200
{
  "id": "voidwalker",
  "name": "Voidwalker",
  "backs": ["b_black", "b_nebula", "b_mp_indigo"]
}

// 404 — no cocktail is pointed at
{ "error": "No active cocktail" }
```

### Admin (require `x-api-key`)


#### `PUT /cocktails/current`
Move the pointer. Sets which cocktail `GET /cocktails/current` returns.

```json
// Request
{ "id": "vantablack" }

// 200
{ "id": "vantablack", "name": "Vantablack", "backs": ["b_black", "b_black", "b_black"] }

// 404 — cocktail ID doesn't exist
{ "error": "Not found" }
```

To clear the pointer (no active cocktail): `DELETE /cocktails/current` → `204`.

---

## How the mod consumes it

### The important bits

1. Client calls `GET /cocktails/current` (no auth) at lobby creation
2. Response `backs` array is set as `MP.LOBBY.cocktail_override`
3. At game start, `apply()` checks for the override and sets `G.GAME.modifiers.mp_cocktail` directly from the array

### Deep dive

4. The merge loop iterates each Back key, additively merging deck configs
5. During scoring, `calculate()` temporarily `change_to`s each component deck and triggers its effects in sequence
6. Duplicates work — merging `b_black` config three times triples its numeric values

The mod never needs to know about cocktail IDs or admin operations. It just needs the name and the `backs` array from `/cocktails/current`.

---

## Drop the junction table

The `decks` resource and `cocktails/{id}/decks/{deckId}` join endpoints can go.
The `backs` array on the cocktail replaces them entirely. Simpler schema, supports
duplicates, matches exactly how the client consumes the data.
