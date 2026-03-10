-- Ghost Replay data capture
--
-- Records every match you play: seed, ruleset, gamemode, deck, stake, and
-- per-ante snapshots of both players' scores and lives. Persisted to config
-- so the data survives between sessions (last 20 matches kept).
--
-- What this enables:
--   - Replay any seed you already played in practice mode,
--     with your opponent's scores as ghost data
--   - Practice mode can load a ghost replay and use the recorded enemy scores
--     as the PvP blind target, so you're "playing against" a past opponent
--   - Match history / post-game review: see how scores diverged ante by ante

MP.MATCH_RECORD = {
	seed = nil,
	ruleset = nil,
	gamemode = nil,
	deck = nil,
	ante_snapshots = {},
	winner = nil,
	final_ante = nil,
}

function MP.MATCH_RECORD.reset()
	MP.MATCH_RECORD.seed = nil
	MP.MATCH_RECORD.ruleset = nil
	MP.MATCH_RECORD.gamemode = nil
	MP.MATCH_RECORD.deck = nil
	MP.MATCH_RECORD.ante_snapshots = {}
	MP.MATCH_RECORD.winner = nil
	MP.MATCH_RECORD.final_ante = nil
end

function MP.MATCH_RECORD.init(seed, ruleset, gamemode, deck, stake)
	MP.MATCH_RECORD.reset()
	MP.MATCH_RECORD.seed = seed
	MP.MATCH_RECORD.ruleset = ruleset
	MP.MATCH_RECORD.gamemode = gamemode
	MP.MATCH_RECORD.deck = deck
	MP.MATCH_RECORD.stake = stake
end

function MP.MATCH_RECORD.snapshot_ante(ante, data)
	MP.MATCH_RECORD.ante_snapshots[ante] = {
		player_score = data.player_score,
		enemy_score = data.enemy_score,
		player_lives = data.player_lives,
		enemy_lives = data.enemy_lives,
		blind_key = data.blind_key,
		result = data.result,
	}
end

function MP.MATCH_RECORD.finalize(won)
	MP.MATCH_RECORD.winner = won and "player" or "enemy"
	MP.MATCH_RECORD.final_ante = G.GAME.round_resets and G.GAME.round_resets.ante or 1

	local config = SMODS.Mods["Multiplayer"].config
	config.ghost_replays = config.ghost_replays or {}

	local entry = {
		seed = MP.MATCH_RECORD.seed,
		ruleset = MP.MATCH_RECORD.ruleset,
		gamemode = MP.MATCH_RECORD.gamemode,
		deck = MP.MATCH_RECORD.deck,
		ante_snapshots = MP.MATCH_RECORD.ante_snapshots,
		winner = MP.MATCH_RECORD.winner,
		final_ante = MP.MATCH_RECORD.final_ante,
		timestamp = os.time(),
	}

	table.insert(config.ghost_replays, entry)

	-- Keep only last 20 replays
	while #config.ghost_replays > 20 do
		table.remove(config.ghost_replays, 1)
	end

	SMODS.save_mod_config(SMODS.Mods["Multiplayer"])
end
