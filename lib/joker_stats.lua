MP.STATS = {}

function MP.STATS.get_player_joker_keys()
	local keys = {}
	if not G.jokers or not G.jokers.cards then return keys end
	for i = 1, #G.jokers.cards do
		local card = G.jokers.cards[i]
		if card.config and card.config.center and card.config.center.key then
			if not card.edition or card.edition.type ~= "mp_phantom" then table.insert(keys, card.config.center.key) end
		end
	end
	return keys
end

function MP.STATS.record_match(won)
	local config = SMODS.Mods["Multiplayer"].config
	config.joker_stats = config.joker_stats or {}
	config.match_history = config.match_history or {}

	local joker_keys = MP.STATS.get_player_joker_keys()

	local entry = {
		won = won,
		joker_keys = joker_keys,
		gamemode = MP.LOBBY.config.gamemode,
		ruleset = MP.LOBBY.config.ruleset,
		timestamp = os.time(),
		ante_reached = G.GAME.round_resets and G.GAME.round_resets.ante or 1,
	}
	table.insert(config.match_history, entry)

	if won then
		for _, key in ipairs(joker_keys) do
			config.joker_stats[key] = (config.joker_stats[key] or 0) + 1
		end
	end

	SMODS.save_mod_config(SMODS.Mods["Multiplayer"])

	-- Send telemetry to server
	local joker_report = MP.STATS.build_joker_report(won)
	if #joker_report > 0 then
		MP.ACTIONS.match_joker_report(won, joker_report)
	end
	MP.STATS.reset_lifecycle()
end

function MP.STATS.get_joker_wins(joker_key)
	local config = SMODS.Mods["Multiplayer"].config
	return config.joker_stats and config.joker_stats[joker_key] or 0
end

-- Joker lifecycle tracking (reset each match)
MP.STATS.joker_lifecycle = {}

--- Call when a joker is added to the player's deck.
--- @param card table       -- the Card object reference (used to match on removal)
--- @param key string       -- e.g. "j_pizza", "j_mp_speedrun"
--- @param edition string   -- e.g. "polychrome", "foil", "none"
--- @param seal string      -- e.g. "eternal", "perishable", "none"
--- @param cost number      -- gold spent (0 if free)
--- @param source string    -- "shop", "booster", "tag", "other"
function MP.STATS.on_joker_acquired(card, key, edition, seal, cost, source)
	if not MP.LOBBY.code then return end -- only track in multiplayer
	table.insert(MP.STATS.joker_lifecycle, {
		card_ref = card,
		key = key,
		edition = edition or "none",
		seal = seal or "none",
		cost = cost or 0,
		source = source or "other",
		ante_acquired = G.GAME.round_resets and G.GAME.round_resets.ante or 1,
		ante_removed = nil,
		removal_reason = nil,
	})
end

--- Call when a joker is removed from the player's deck.
--- Matches by card object reference first, falls back to key match.
--- @param card table       -- the Card object being removed
--- @param reason string    -- "sold", "destroyed", "perishable"
function MP.STATS.on_joker_removed(card, reason)
	if not MP.LOBBY.code then return end
	-- First try exact card reference match
	for i = #MP.STATS.joker_lifecycle, 1, -1 do
		local entry = MP.STATS.joker_lifecycle[i]
		if entry.card_ref == card and entry.ante_removed == nil then
			entry.ante_removed = G.GAME.round_resets and G.GAME.round_resets.ante or 1
			entry.removal_reason = reason
			return
		end
	end
	-- Fallback: match by key (for cases where card ref isn't available)
	local key = card.config and card.config.center and card.config.center.key
	if key then
		for i = #MP.STATS.joker_lifecycle, 1, -1 do
			local entry = MP.STATS.joker_lifecycle[i]
			if entry.key == key and entry.ante_removed == nil then
				entry.ante_removed = G.GAME.round_resets and G.GAME.round_resets.ante or 1
				entry.removal_reason = reason
				return
			end
		end
	end
end

--- Build the match joker report payload.
--- Called from record_match() after the existing local-save logic.
function MP.STATS.build_joker_report(won)
	local report = {}
	local final_ante = G.GAME.round_resets and G.GAME.round_resets.ante or 1
	for _, entry in ipairs(MP.STATS.joker_lifecycle) do
		table.insert(report, {
			key = entry.key,
			edition = entry.edition,
			seal = entry.seal,
			cost = entry.cost,
			source = entry.source,
			ante_acquired = entry.ante_acquired,
			ante_removed = entry.ante_removed,         -- nil if held to end
			removal_reason = entry.removal_reason,     -- nil if held to end
			held_at_end = entry.ante_removed == nil,
			hold_duration_antes = (entry.ante_removed or final_ante) - entry.ante_acquired,
		})
	end
	return report
end

--- Reset lifecycle tracking for a new match.
function MP.STATS.reset_lifecycle()
	MP.STATS.joker_lifecycle = {}
end
