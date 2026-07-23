--[[
  Weekly cocktail test.

  In MATCHMAKING, when the server has published a weekly cocktail composition
  (MP._match_cocktail, derived from the PICKED draft item riding the host broadcast), the Cocktail deck's pool is
  replaced outright: every weekly deck is forced, nothing else mixes in.
  Private lobbies (not matchmaking) keep the player/lobby cocktail config path.

  Run from the repo root:
    luajit tests/test_weekly_cocktail.lua
]]

-- ── Stubs to load the real modules ──────────────────────────────────────────
MP = {}
MPAPI = {}
SMODS = {
	Back = function(t) return t end,
	Atlas = function(t) return t end,
	DrawStep = function(t) return t end,
	save_mod_config = function() end,
}
Back = { change_to = function() end }
-- ZZ_cocktail wraps several engine methods at load time; give it inert hosts.
Card = { click = function() end, highlight = function() end }
CardArea = { can_highlight = function() end }
Controller = { queue_R_cursor_press = function() end }
Event = function(t) return t end
G = {
	FUNCS = {},
	E_MANAGER = { add_event = function() end },
	P_CENTERS = {
		b_mp_cocktail = { set = 'Back', order = 99, deck_blacklist = { b_mp_cocktail = true }, mod_whitelist = { MultiplayerPvP = true } },
		b_red = { set = 'Back', order = 1 },
		b_green = { set = 'Back', order = 4 },
		b_black = { set = 'Back', order = 5 },
		b_mp_orange = { set = 'Back', order = 18, mod = { id = 'MultiplayerPvP' } },
	},
}

dofile('lib/cocktail_config.lua')
dofile('objects/decks/ZZ_cocktail.lua')

-- Runtime collaborators the culled path reads.
local matchmaking = false
MP.is_matchmaking = function() return matchmaking end
MP.cocktail_cfg_get = function() return '1212' end -- b_red in, b_green forced, b_black in, b_mp_orange forced

-- ── Harness ────────────────────────────────────────────────────────────────
local failures = 0
local function check(cond, msg)
	if cond then print('PASS: ' .. msg) else failures = failures + 1; print('FAIL: ' .. msg) end
end

-- ── weekly + matchmaking: composition is exactly the weekly ─────────────────
print()
print('-- weekly + matchmaking: forced composition, empty pool --')
matchmaking = true
MP._match_cocktail = { name = "casjb's", decks = { 'b_green', 'b_black', 'b_mp_orange' } }
local included, forced = MP.get_cocktail_decks(true)
check(#included == 0, 'nothing random mixes in')
check(#forced == 3 and forced[1] == 'b_green' and forced[2] == 'b_black' and forced[3] == 'b_mp_orange',
	"forced == casjb's green/black/orange, in order")

-- ── unknown keys are filtered ────────────────────────────────────────────────
print()
print('-- weekly with an unknown key: filtered --')
MP._match_cocktail = { name = 'x', decks = { 'b_green', 'b_not_installed' } }
included, forced = MP.get_cocktail_decks(true)
check(#forced == 1 and forced[1] == 'b_green', 'missing decks are dropped, valid ones kept')

-- ── weekly entirely unresolvable: normal path ────────────────────────────────
print()
print('-- weekly with no resolvable decks: falls back to the config path --')
MP._match_cocktail = { name = 'x', decks = { 'b_nope' } }
included, forced = MP.get_cocktail_decks(true)
check(#included == 2 and #forced == 2, 'config path used (1212 -> 2 included, 2 forced)')

-- ── not matchmaking: private lobbies keep their config ──────────────────────
print()
print('-- weekly set but NOT matchmaking: config path wins --')
matchmaking = false
MP._match_cocktail = { name = "casjb's", decks = { 'b_green', 'b_black', 'b_mp_orange' } }
included, forced = MP.get_cocktail_decks(true)
check(#included == 2 and included[1] == 'b_red' and included[2] == 'b_black', 'included from cfg string')
check(#forced == 2 and forced[1] == 'b_green' and forced[2] == 'b_mp_orange', 'forced from cfg string')

-- ── no weekly at all: unchanged behaviour ────────────────────────────────────
print()
print('-- no weekly: unchanged behaviour --')
matchmaking = true
MP._match_cocktail = nil
included, forced = MP.get_cocktail_decks(true)
check(#included == 2 and #forced == 2, 'config path used when no weekly is stashed')

-- ── uncalled path (cull=false) unaffected ────────────────────────────────────
print()
print('-- cull=false lists candidates, never the weekly --')
local all = MP.get_cocktail_decks(false)
check(#all == 4, 'candidate list built from P_CENTERS (4 eligible)')

-- ── Summary ─────────────────────────────────────────────────────────────────
print()
if failures == 0 then
	print('ALL TESTS PASSED')
	os.exit(0)
else
	print(failures .. ' TEST(S) FAILED')
	os.exit(1)
end
