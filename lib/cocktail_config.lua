-- Pure decision logic for the Cocktail Deck (objects/decks/ZZ_cocktail.lua).
--
-- Kept separate from ZZ_cocktail.lua (which is all impure shell: SMODS
-- registration, G.P_CENTERS enumeration, UI overlays) so the actual decisions --
-- which decks are in/forced/out for a given cfg string, and which cfg string is
-- authoritative -- are plain-data-in/plain-data-out and unit-testable without
-- any game globals.
MP.CocktailConfig = MP.CocktailConfig or {}

-- Partition an ordered list of candidate deck keys against a position-encoded
-- cfg string: one character per key, by position ("1" = included in the pool,
-- "2" = forced to always appear, anything else/missing = excluded).
-- Mirrors the encoding written by MP.cocktail_cfg_edit.
function MP.CocktailConfig.select(keys, cfg_str)
	cfg_str = cfg_str or ""
	local included, forced = {}, {}
	for i, key in ipairs(keys) do
		local c = cfg_str:sub(i, i)
		if c == "1" then
			included[#included + 1] = key
		elseif c == "2" then
			forced[#forced + 1] = key
		end
	end
	return included, forced
end

-- Cocktail cfg strings are truthy in Lua even when "" -- and "" specifically
-- means "never seeded" (the reset_lobby_config default), not a deliberate
-- all-decks-off choice. Treat "" (and nil) as unset and fall back.
-- Used both to resolve which cfg string governs deck application in a lobby
-- (MP.cocktail_cfg_get) and to seed a host's lobby metadata at lobby-create
-- time from their own saved preference (MP.pvp_lobby_metadata).
function MP.CocktailConfig.resolve(value, fallback)
	if value and value ~= "" then
		return value
	end
	return fallback
end

return MP.CocktailConfig
