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
	if not config then return end
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
end

function MP.STATS.get_joker_wins(joker_key)
	local config = SMODS.Mods["Multiplayer"].config
	return config and config.joker_stats[joker_key] or 0
end
