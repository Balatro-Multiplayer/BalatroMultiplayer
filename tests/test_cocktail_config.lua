--[[
  Cocktail Deck config resolution + selection tests.

  Covers the pure decision logic behind the "cocktail just doesn't work" bug:
  MP.CocktailConfig.select (cull/forced partitioning from a position-encoded cfg
  string) and MP.CocktailConfig.resolve (lobby-vs-saved cfg fallback, treating ""
  as unset -- Lua's "" is truthy, which is exactly how an unseeded lobby cocktail
  config silently culled every deck to zero). Also exercises MP.pvp_lobby_metadata
  (pvp_api/flow.lua) to confirm the lobby-creation metadata snapshot ships a real
  cocktail value (plus sleeve/challenge) instead of the reset_lobby_config "" default.

  Run from the repo root:
    luajit tests/test_cocktail_config.lua
]]

local failures = 0
local function check(name, cond)
	if cond then
		print("ok   - " .. name)
	else
		failures = failures + 1
		print("FAIL - " .. name)
	end
end

-- ─── MP.CocktailConfig.select ────────────────────────────────────────────────

MP = {}
dofile("lib/cocktail_config.lua")

local keys = { "b_red", "b_blue", "b_yellow", "b_green" }

do
	local included, forced = MP.CocktailConfig.select(keys, "1010")
	check("select: '1' at pos 1 includes b_red", included[1] == "b_red")
	check("select: '1' at pos 3 includes b_yellow", included[2] == "b_yellow")
	check("select: '0' positions excluded from both lists", #included == 2 and #forced == 0)
end

do
	local included, forced = MP.CocktailConfig.select(keys, "2110")
	check("select: '2' forces b_red instead of including it", forced[1] == "b_red" and #forced == 1)
	check("select: '1' still includes b_blue/b_yellow", included[1] == "b_blue" and included[2] == "b_yellow")
	check("select: forced decks are not duplicated into included", #included == 2)
end

do
	local included, forced = MP.CocktailConfig.select(keys, "0000")
	check("select: all-zero cfg string excludes every deck", #included == 0 and #forced == 0)
end

do
	-- Regression: this is the exact shape of the bug -- an unseeded lobby's cocktail
	-- cfg ("") culled every deck to zero, so the cocktail Back's apply() loop ran 0
	-- iterations and mixed in nothing.
	local included_empty, forced_empty = MP.CocktailConfig.select(keys, "")
	check("select: empty cfg string behaves like all-zero (regression: unseeded lobby)", #included_empty == 0 and #forced_empty == 0)
	local included_nil, forced_nil = MP.CocktailConfig.select(keys, nil)
	check("select: nil cfg string also behaves like all-zero", #included_nil == 0 and #forced_nil == 0)
end

-- ─── MP.CocktailConfig.resolve ───────────────────────────────────────────────

do
	check("resolve: non-empty lobby value wins over fallback", MP.CocktailConfig.resolve("1111H", "0000H") == "1111H")
	check("resolve: empty-string lobby value falls back (the bug)", MP.CocktailConfig.resolve("", "1111H") == "1111H")
	check("resolve: nil lobby value falls back", MP.CocktailConfig.resolve(nil, "1111H") == "1111H")
	check("resolve: false (not-in-lobby / no-deck) falls back", MP.CocktailConfig.resolve(false, "1111H") == "1111H")
end

-- Scenario table mirroring MP.cocktail_cfg_get's actual call shape:
--   resolve(lobby_code and lobby_deck_cocktail, MP.config.cocktail)
local get_cases = {
	{ name = "solo (no lobby): uses saved config", lobby_code = nil, lobby_cocktail = nil, saved = "1111H", expect = "1111H" },
	{ name = "lobby, seeded cocktail: uses lobby value", lobby_code = "ABCD", lobby_cocktail = "1010H", saved = "1111H", expect = "1010H" },
	{ name = 'lobby, unseeded ("") cocktail: falls back to saved (the bug)', lobby_code = "ABCD", lobby_cocktail = "", saved = "1111H", expect = "1111H" },
	{ name = "lobby, deck table not populated yet: falls back to saved", lobby_code = "ABCD", lobby_cocktail = nil, saved = "1111H", expect = "1111H" },
}
for _, c in ipairs(get_cases) do
	local lobby_value = c.lobby_code and c.lobby_cocktail
	local got = MP.CocktailConfig.resolve(lobby_value, c.saved)
	check("cocktail_cfg_get shape: " .. c.name, got == c.expect)
end

-- ─── MP.pvp_lobby_metadata ships a real cocktail value ──────────────────────

MP = {
	id = "MultiplayerPvP",
	LOBBY = {
		config = {
			back = "Cocktail Deck",
			stake = 1,
			starting_lives = 4,
			pvp_start_round = 2,
			cocktail = "", -- reset_lobby_config default: never touched the edit overlay
			sleeve = "sleeve_casl_none",
			challenge = "",
		},
	},
	config = { cocktail = "1111H" }, -- the host's saved mod-config preference
	LobbyKind = {},
	PVP_GAMEMODES = { pvp_standard = { ruleset = "ruleset_mp_blitz" } },
}
G = { FUNCS = {} }
dofile("lib/cocktail_config.lua")
dofile("pvp_api/flow.lua")

local meta = MP.pvp_lobby_metadata("pvp_standard", "private")
check("lobby metadata carries a non-empty cocktail value", meta.cocktail == "1111H")
check("lobby metadata cocktail is not the unseeded default", meta.cocktail ~= "")
check("lobby metadata carries sleeve", meta.sleeve == "sleeve_casl_none")
check("lobby metadata carries challenge (empty string is a legit value here)", meta.challenge == "")

-- Regression: once a lobby's own config.cocktail has actually been set (e.g. via
-- the edit overlay before create-lobby), metadata must ship THAT value, not
-- silently keep re-deriving from the saved config.
MP.LOBBY.config.cocktail = "2110H"
local meta2 = MP.pvp_lobby_metadata("pvp_standard", "private")
check("lobby metadata prefers an already-set lobby cocktail over the saved default", meta2.cocktail == "2110H")

if failures > 0 then
	error(failures .. " check(s) failed")
end
print("\nAll cocktail config checks passed.")
