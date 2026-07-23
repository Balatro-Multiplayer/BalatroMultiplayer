--[[
  CONTRACT: this pool shape is produced by the server -- keep in sync with
  server apps/server/src/tests/services/draft-contract.test.ts

  Canonical wire shape (exact JSON issueDraftPool returns): an array of items --
    plain item:    { key = <non-empty string>, stake = <integer> }  (no other fields)
    cocktail item: { key = 'b_mp_cocktail', stake = <integer>,
                      decks = { <string>, ... }, name = <string, no "Cocktail" suffix> }

  This test pins that the client ACCEPTS exactly what the server emits
  (validate_server_pool) and decorates it as expected (decorate_cocktail_items),
  and that each contract violation the parse layer relies on is rejected.

  Run from the repo root:
    luajit tests/test_pool_contract.lua
]]

-- ── Stubs to load the real module ───────────────────────────────────────────
MP = { DECK = {} }
MPAPI = { matchmaking = {} }
local _loc = { k_cocktail_suffix = 'Cocktail', k_banpick_weekly_mix = 'A rotating 3-deck mix' }
function localize(k)
	return _loc[k] or k
end

dofile('pvp_api/draft_pool.lua')

-- ── Harness ────────────────────────────────────────────────────────────────
local failures = 0
local function check(cond, msg)
	if cond then print('PASS: ' .. msg) else failures = failures + 1; print('FAIL: ' .. msg) end
end

G = G or {}
G.P_CENTERS = { b_red = {}, b_blue = {}, b_green = {}, b_black = {}, b_mp_orange = {}, b_mp_cocktail = {} }

-- Canonical server pool (returns a fresh copy every call -- decorate_cocktail_items
-- mutates its argument in place, and the negative cases build their own tables).
local function canonical_pool()
	return {
		{ key = 'b_red', stake = 1 },
		{ key = 'b_blue', stake = 8 },
		{ key = 'b_mp_cocktail', stake = 4, decks = { 'b_green', 'b_black', 'b_mp_orange' }, name = 'Casjb' },
	}
end

-- ── the client accepts exactly what the server emits ────────────────────────
print()
print('-- validate_server_pool: accepts the canonical server pool verbatim --')
local pool = canonical_pool()
check(MP.validate_server_pool(pool, #pool) == true, 'canonical server pool (plain + cocktail items) passes')

-- ── decoration matches the contract ──────────────────────────────────────────
print()
print('-- decorate_cocktail_items: applied to the canonical server pool --')
local decorated = MP.decorate_cocktail_items(canonical_pool())
check(decorated[1].name == nil and decorated[1].subtitle == nil, 'plain item name untouched')
check(decorated[2].name == nil and decorated[2].subtitle == nil, 'plain item subtitle untouched')
check(decorated[3].name == 'Casjb Cocktail', 'bare server name gets the localized Cocktail suffix')
check(decorated[3].subtitle == 'A rotating 3-deck mix', 'subtitle set from the localized weekly-mix string')
check(type(decorated[3].decks) == 'table' and #decorated[3].decks == 3, 'decks length preserved')
check(
	decorated[3].decks[1] == 'b_green' and decorated[3].decks[2] == 'b_black' and decorated[3].decks[3] == 'b_mp_orange',
	'decks contents preserved in order'
)

-- ── negative contract cases: each violation is rejected ─────────────────────
print()
print('-- validate_server_pool: contract violations are rejected --')

local missing_stake = { { key = 'b_red' }, { key = 'b_blue', stake = 8 }, { key = 'b_green', stake = 1 } }
check(MP.validate_server_pool(missing_stake, 3) == false, 'item missing stake is rejected')

local unknown_key = { { key = 'b_totally_unknown', stake = 1 }, { key = 'b_blue', stake = 8 }, { key = 'b_green', stake = 1 } }
check(MP.validate_server_pool(unknown_key, 3) == false, "item whose key isn't in G.P_CENTERS is rejected")

local duplicate_pair = { { key = 'b_red', stake = 1 }, { key = 'b_red', stake = 1 }, { key = 'b_green', stake = 1 } }
check(MP.validate_server_pool(duplicate_pair, 3) == false, 'duplicate (key, stake) pair is rejected')

-- ── Summary ─────────────────────────────────────────────────────────────────
print()
if failures == 0 then
	print('ALL TESTS PASSED')
	os.exit(0)
else
	print(failures .. ' TEST(S) FAILED')
	os.exit(1)
end
