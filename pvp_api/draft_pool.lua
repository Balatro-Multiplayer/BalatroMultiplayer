-- Client-side draft-pool support.
--
-- The draft pool is SERVER-AUTHORITATIVE (idempotent per match, curated per
-- queue -- see the server's features/draft/). The draft only ever runs inside
-- matchmaking, and every matchmaking queue has a server draft policy, so there
-- is no local generator and no fallback pool: a fetch failure aborts the draft
-- instead of fabricating one. This file provides:
--   * MP.validate_server_pool -- crash-guard against an unusable server pool
--                                 (wrong size, unknown deck keys, out-of-cap
--                                 stakes, duplicate pairs)
--   * MP.fetch_draft_pool     -- host-side: ask the server for this match's pool
--   * MP.decorate_cocktail_items -- adds PvP's Cocktail display wording
--   * MP.set_match_cocktail   -- derives the match-scoped cocktail from the pick

-- Validate a server-issued pool against what THIS client can actually run:
-- exact expected size (the draft schedule is fixed), every key resolvable in
-- G.P_CENTERS (an unknown key would crash tile construction on BOTH clients),
-- stakes within the compat cap, no duplicate (key, stake) pairs. Anything off
-- means the pool is unusable -- the caller must abort the draft rather than
-- start it, since there is no local-generation fallback to degrade into.
function MP.validate_server_pool(pool, expected_count)
	if type(pool) ~= 'table' or #pool ~= expected_count then
		return false
	end
	local cap = (MP.DECK and MP.DECK.MAX_STAKE and MP.DECK.MAX_STAKE > 0) and MP.DECK.MAX_STAKE or 8
	local seen = {}
	for _, item in ipairs(pool) do
		if type(item) ~= 'table' or type(item.key) ~= 'string' or not G.P_CENTERS[item.key] then
			return false
		end
		if type(item.stake) ~= 'number' or item.stake < 1 or item.stake > cap or item.stake % 1 ~= 0 then
			return false
		end
		local id = item.key .. '@' .. item.stake
		if seen[id] then
			return false
		end
		seen[id] = true
	end
	return true
end

-- Host-side: fetch this match's server-generated pool. callback(pool) with an
-- array of { key, stake }, or callback(nil) on any failure (no connection, no
-- match id, transport error) -- the caller must abort the draft on nil, never
-- fabricate a pool.
function MP.fetch_draft_pool(callback)
	local match_id = MP._match_handle and MP._match_handle.match_id
	if not match_id or not MPAPI.matchmaking.fetch_draft_pool then
		callback(nil)
		return
	end
	MPAPI.matchmaking.fetch_draft_pool(match_id, callback)
end

-- Match-scoped cocktail composition, derived from the PICKED draft item -- which
-- rides the host's state broadcast, so host and guest provably agree (each
-- client's private weekly stash is only ever the HOST's tagging source).
-- Set at draft completion, cleared on lobby teardown.
function MP.set_match_cocktail(picked)
	if
		type(picked) == 'table'
		and picked.key == 'b_mp_cocktail'
		and type(picked.decks) == 'table'
		and #picked.decks > 0
	then
		MP._match_cocktail = { name = picked.name, decks = picked.decks }
	else
		MP._match_cocktail = nil
	end
end

-- PvP owns the "Cocktail" wording. The server delivers the composition ON the
-- cocktail pool item (item.decks + a bare item.name like "Casjb"); this adds
-- the localized display strings the composite-agnostic engine renders verbatim
-- -- item.name becomes "Casjb Cocktail", item.subtitle the mix line. Items
-- without a decks list (e.g. a plain deck, or a non-weekly cocktail roll) pass
-- through untouched -- they render as a plain deck.
function MP.decorate_cocktail_items(pool)
	if not pool then
		return pool
	end
	for _, item in ipairs(pool) do
		if type(item) == 'table' and item.key == 'b_mp_cocktail' and type(item.decks) == 'table' and #item.decks > 0 then
			local suffix = localize('k_cocktail_suffix')
			item.name = (item.name and (tostring(item.name) .. ' ') or '') .. suffix
			item.subtitle = localize('k_banpick_weekly_mix')
		end
	end
	return pool
end
