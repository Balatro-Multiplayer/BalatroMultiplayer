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
	-- Don't save ghost practice games as new replays
	if MP.is_practice_mode() then return end

	MP.MATCH_RECORD.winner = won and "player" or "nemesis"
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

-- Ghost Replay playback state
-- Loads a stored match record and provides enemy scores for PvP blinds
-- so practice mode can simulate playing against a past opponent.

MP.GHOST = { active = false, replay = nil }

function MP.GHOST.load(replay)
	MP.GHOST.active = true
	MP.GHOST.replay = replay
end

function MP.GHOST.clear()
	MP.GHOST.active = false
	MP.GHOST.replay = nil
end

function MP.GHOST.get_enemy_score(ante)
	if not MP.GHOST.replay or not MP.GHOST.replay.ante_snapshots then return nil end
	local snapshot = MP.GHOST.replay.ante_snapshots[ante] or MP.GHOST.replay.ante_snapshots[tostring(ante)]
	if snapshot and snapshot.enemy_score then return snapshot.enemy_score end
	return nil
end

function MP.GHOST.is_active()
	return MP.GHOST.active and MP.GHOST.replay ~= nil
end

-- DEBUG: Generate a fake ghost replay for testing. Remove before release.
function MP.GHOST.generate_test_replay()
	local config = SMODS.Mods["Multiplayer"].config
	config.ghost_replays = config.ghost_replays or {}

	local fake = {
		seed = "TESTGHOST",
		ruleset = "ruleset_mp_blitz",
		gamemode = "gamemode_mp_attrition",
		deck = "Red Deck",
		stake = 1,
		winner = "nemesis",
		final_ante = 6,
		timestamp = os.time(),
		ante_snapshots = {
			[1] = { enemy_score = "0", player_score = "0", player_lives = 4, enemy_lives = 4, result = "win" },
			[2] = { enemy_score = "8000", player_score = "5000", player_lives = 4, enemy_lives = 4, result = "win" },
			[3] = { enemy_score = "45000", player_score = "30000", player_lives = 4, enemy_lives = 3, result = "loss" },
			[4] = { enemy_score = "200000", player_score = "150000", player_lives = 3, enemy_lives = 3, result = "win" },
			[5] = {
				enemy_score = "1200000",
				player_score = "800000",
				player_lives = 3,
				enemy_lives = 2,
				result = "loss",
			},
			[6] = {
				enemy_score = "5000000",
				player_score = "3000000",
				player_lives = 2,
				enemy_lives = 2,
				result = "loss",
			},
			[7] = {
				enemy_score = "25000000",
				player_score = "15000000",
				player_lives = 1,
				enemy_lives = 2,
				result = "loss",
			},
			[8] = {
				enemy_score = "100000000",
				player_score = "50000000",
				player_lives = 1,
				enemy_lives = 2,
				result = "loss",
			},
		},
	}

	table.insert(config.ghost_replays, fake)
	SMODS.save_mod_config(SMODS.Mods["Multiplayer"])
	sendDebugMessage("Test ghost replay generated", "MULTIPLAYER")
end
