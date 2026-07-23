--[[
  Client-side draft-pool support test.

  The draft pool is server-authoritative -- there is no local generator. This
  covers what remains client-side: validate_server_pool (crash-guard against
  an unusable server pool), decorate_cocktail_items (PvP's display wording),
  set_match_cocktail (match-scoped composition derivation), and the fetch
  wrapper degrading to nil without a match handle.

  Run from the repo root:
    luajit tests/test_draft_pool.lua
]]

-- ── Stubs to load the real module ───────────────────────────────────────────
MP = { DECK = {} }
MPAPI = { matchmaking = {} }
-- decorate_cocktail_items localizes the display wording; map keys to the en-us
-- values so the test asserts the real composed strings.
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

-- ── weekly cocktail tagging ─────────────────────────────────────────────────
print()
print('-- decorate_cocktail_items: PvP display wording on server-composed items --')
-- The server delivers the composition ON the item (decks + a bare name);
-- PvP adds the localized display strings the engine renders verbatim.
local decorated = MP.decorate_cocktail_items({
	{ key = 'b_red', stake = 1 },
	{ key = 'b_mp_cocktail', stake = 4, decks = { 'b_green', 'b_black', 'b_mp_orange' }, name = 'Casjb' },
	{ key = 'b_mp_cocktail', stake = 8, decks = { 'b_green', 'b_black', 'b_mp_orange' }, name = 'Casjb' },
})
check(decorated[1].name == nil and decorated[1].subtitle == nil, 'non-cocktail tiles untouched')
check(decorated[2].name == 'Casjb Cocktail', 'PvP appends the Cocktail suffix to the server name')
check(decorated[2].subtitle == 'A rotating 3-deck mix', 'subtitle line set')
check(type(decorated[2].decks) == 'table' and #decorated[2].decks == 3, 'server-provided decks preserved')
check(decorated[3].name == 'Casjb Cocktail', 'every cocktail tile is decorated (twin stakes too)')
-- A cocktail item with NO decks (a non-weekly random cocktail roll) passes
-- through untouched -- it renders as a plain deck.
local plain = MP.decorate_cocktail_items({ { key = 'b_mp_cocktail', stake = 1 } })
check(plain[1].name == nil, 'no decks on the item -> pass through untouched')

-- ── server pool validation gate ─────────────────────────────────────────────
print()
print('-- validate_server_pool: gate against unusable server pools --')
G = G or {}
G.P_CENTERS = { b_red = {}, b_blue = {}, b_green = {} }
local good = { { key = 'b_red', stake = 1 }, { key = 'b_blue', stake = 8 }, { key = 'b_red', stake = 8 } }
check(MP.validate_server_pool(good, 3) == true, 'well-formed pool of the right size passes')
check(MP.validate_server_pool(good, 9) == false, 'wrong size rejected (fixed draft schedule)')
check(MP.validate_server_pool({ { key = 'b_nope', stake = 1 }, { key = 'b_red', stake = 1 }, { key = 'b_blue', stake = 1 } }, 3) == false,
	'unknown deck key rejected (would crash tile construction)')
check(MP.validate_server_pool({ { key = 'b_red', stake = 9 }, { key = 'b_blue', stake = 1 }, { key = 'b_green', stake = 1 } }, 3) == false,
	'out-of-range stake rejected')
check(MP.validate_server_pool({ { key = 'b_red', stake = 1 }, { key = 'b_red', stake = 1 }, { key = 'b_blue', stake = 1 } }, 3) == false,
	'duplicate (key, stake) pair rejected')
check(MP.validate_server_pool({}, 0) == true and MP.validate_server_pool({}, 9) == false,
	'empty pool only valid when nothing is expected')
MP.DECK.MAX_STAKE = 4
check(MP.validate_server_pool({ { key = 'b_red', stake = 8 }, { key = 'b_blue', stake = 1 }, { key = 'b_green', stake = 1 } }, 3) == false,
	'stake above the compat cap rejected')
MP.DECK.MAX_STAKE = nil
G.P_CENTERS = nil

-- ── match cocktail derivation (from the picked broadcast item) ──────────────
print()
print('-- set_match_cocktail: composition comes from the picked item --')
MP.set_match_cocktail({ key = 'b_mp_cocktail', decks = { 'b_green', 'b_black' }, name = 'Casjb Cocktail' })
check(MP._match_cocktail ~= nil and #MP._match_cocktail.decks == 2 and MP._match_cocktail.name == 'Casjb Cocktail',
	'picked cocktail with composition sets the match stash')
MP.set_match_cocktail({ key = 'b_red', stake = 1 })
check(MP._match_cocktail == nil, 'picking a non-cocktail clears the stash')
MP.set_match_cocktail({ key = 'b_mp_cocktail', stake = 1 })
check(MP._match_cocktail == nil, 'cocktail WITHOUT composition metadata clears it (random cocktail path)')

-- ── fetch wrapper degrades to nil without a match ───────────────────────────
print()
print('-- wrappers without a match handle --')
local got = 'unset'
MP.fetch_draft_pool(function(pool) got = pool end)
check(got == nil, 'fetch_draft_pool hands back nil (caller must abort the draft) with no match')

-- ── Summary ─────────────────────────────────────────────────────────────────
print()
if failures == 0 then
	print('ALL TESTS PASSED')
	os.exit(0)
else
	print(failures .. ' TEST(S) FAILED')
	os.exit(1)
end
