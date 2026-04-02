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
	player_name = nil,
	nemesis_name = nil,
	ante_snapshots = {},
	winner = nil,
	final_ante = nil,
}

function MP.MATCH_RECORD.reset()
	MP.MATCH_RECORD.seed = nil
	MP.MATCH_RECORD.ruleset = nil
	MP.MATCH_RECORD.gamemode = nil
	MP.MATCH_RECORD.deck = nil
	MP.MATCH_RECORD.player_name = nil
	MP.MATCH_RECORD.nemesis_name = nil
	MP.MATCH_RECORD.ante_snapshots = {}
	MP.MATCH_RECORD.winner = nil
	MP.MATCH_RECORD.final_ante = nil
end

function MP.MATCH_RECORD.init(seed, ruleset, gamemode, deck, stake, player_name, nemesis_name)
	MP.MATCH_RECORD.reset()
	MP.MATCH_RECORD.seed = seed
	MP.MATCH_RECORD.ruleset = ruleset
	MP.MATCH_RECORD.gamemode = gamemode
	MP.MATCH_RECORD.deck = deck
	MP.MATCH_RECORD.stake = stake
	MP.MATCH_RECORD.player_name = player_name
	MP.MATCH_RECORD.nemesis_name = nemesis_name
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
end

MP.GHOST = { active = false, replay = nil, flipped = false, gamemode = nil }

-- Per-ante playback state
MP.GHOST._hands = {}
MP.GHOST._hand_idx = 0
MP.GHOST._advancing = false

function MP.GHOST.load(replay)
	MP.GHOST.active = true
	MP.GHOST.replay = replay
	MP.GHOST.flipped = false
	MP.GHOST.gamemode = replay and replay.gamemode or nil
	MP.GHOST._hands = {}
	MP.GHOST._hand_idx = 0
	MP.GHOST._advancing = false
end

function MP.GHOST.clear()
	MP.GHOST.active = false
	MP.GHOST.replay = nil
	MP.GHOST.flipped = false
	MP.GHOST.gamemode = nil
	MP.GHOST._hands = {}
	MP.GHOST._hand_idx = 0
	MP.GHOST._advancing = false
end

function MP.GHOST.flip()
	MP.GHOST.flipped = not MP.GHOST.flipped
end

function MP.GHOST.get_enemy_hands(ante)
	if not MP.GHOST.replay or not MP.GHOST.replay.ante_snapshots then return {} end
	local snapshot = MP.GHOST.replay.ante_snapshots[ante] or MP.GHOST.replay.ante_snapshots[tostring(ante)]
	if not snapshot or not snapshot.hands then return {} end
	local enemy_side = MP.GHOST.flipped and "player" or "enemy"
	local out = {}
	for _, h in ipairs(snapshot.hands) do
		if h.side == enemy_side then
			out[#out + 1] = h
		end
	end
	return out
end

-- Fallback for replays without hand-level data
function MP.GHOST.get_enemy_score(ante)
	if not MP.GHOST.replay or not MP.GHOST.replay.ante_snapshots then return nil end
	local snapshot = MP.GHOST.replay.ante_snapshots[ante] or MP.GHOST.replay.ante_snapshots[tostring(ante)]
	if not snapshot then return nil end
	local key = MP.GHOST.flipped and "player_score" or "enemy_score"
	return snapshot[key]
end

function MP.GHOST.init_playback(ante)
	local hands = MP.GHOST.get_enemy_hands(ante)
	MP.GHOST._hands = hands
	MP.GHOST._hand_idx = 0
	MP.GHOST._advancing = false
	if #hands > 0 then
		MP.GHOST._hand_idx = 1
		local score = MP.INSANE_INT.from_string(hands[1].score)
		MP.GAME.enemy.score = score
		MP.GAME.enemy.score_text = MP.INSANE_INT.to_string(score)
		MP.GAME.enemy.hands = hands[1].hands_left or 0
		return true
	else
		local score_str = MP.GHOST.get_enemy_score(ante)
		if score_str then
			MP.GAME.enemy.score = MP.INSANE_INT.from_string(score_str)
			MP.GAME.enemy.score_text = MP.INSANE_INT.to_string(MP.GAME.enemy.score)
		end
		return false
	end
end

function MP.GHOST.advance_hand()
	if MP.GHOST._hand_idx >= #MP.GHOST._hands then return false end
	MP.GHOST._hand_idx = MP.GHOST._hand_idx + 1
	local entry = MP.GHOST._hands[MP.GHOST._hand_idx]
	local score = MP.INSANE_INT.from_string(entry.score)

	G.E_MANAGER:add_event(Event({
		blockable = false, blocking = false,
		trigger = "ease", delay = 0.5,
		ref_table = MP.GAME.enemy.score,
		ref_value = "e_count",
		ease_to = score.e_count,
		func = function(t) return math.floor(t) end,
	}))
	G.E_MANAGER:add_event(Event({
		blockable = false, blocking = false,
		trigger = "ease", delay = 0.5,
		ref_table = MP.GAME.enemy.score,
		ref_value = "coeffiocient",
		ease_to = score.coeffiocient,
		func = function(t) return math.floor(t) end,
	}))
	G.E_MANAGER:add_event(Event({
		blockable = false, blocking = false,
		trigger = "ease", delay = 0.5,
		ref_table = MP.GAME.enemy.score,
		ref_value = "exponent",
		ease_to = score.exponent,
		func = function(t) return math.floor(t) end,
	}))

	MP.GAME.enemy.hands = entry.hands_left or 0
	if MP.UI.juice_up_pvp_hud then MP.UI.juice_up_pvp_hud() end
	return true
end

function MP.GHOST.playback_exhausted()
	return #MP.GHOST._hands == 0 or MP.GHOST._hand_idx >= #MP.GHOST._hands
end

function MP.GHOST.has_hand_data()
	return #MP.GHOST._hands > 0
end

-- Reads target from hands array directly, bypassing the eased score table.
function MP.GHOST.current_target_big()
	if MP.GHOST._hand_idx < 1 or MP.GHOST._hand_idx > #MP.GHOST._hands then return to_big(0) end
	local entry = MP.GHOST._hands[MP.GHOST._hand_idx]
	local score = MP.INSANE_INT.from_string(entry.score)
	return to_big(score.coeffiocient * (10 ^ score.exponent))
end

function MP.GHOST.get_nemesis_name()
	if not MP.GHOST.replay then return nil end
	if MP.GHOST.flipped then
		return MP.GHOST.replay.player_name or localize("k_ghost")
	else
		return MP.GHOST.replay.nemesis_name or localize("k_ghost")
	end
end

function MP.GHOST.is_active()
	return MP.GHOST.active and MP.GHOST.replay ~= nil
end

-- Load ghost replays from JSON files in the replays/ folder.
-- Files are read once when the picker is opened; drop a .json file
-- generated by tools/log_to_ghost_replay.py into replays/ and it
-- shows up alongside config-stored replays.

function MP.GHOST.load_folder_replays()
	local json = require("json")
	local log_parser = MP.load_mp_file("lib/log_parser.lua")
	local replays_dir = MP.path .. "/replays"
	local dir_info = NFS.getInfo(replays_dir)
	if not dir_info or dir_info.type ~= "directory" then return {} end

	local items = NFS.getDirectoryItemsInfo(replays_dir)
	local results = {}

	for _, item in ipairs(items) do
		if item.type == "file" and item.name:match("%.json$") then
			local filepath = replays_dir .. "/" .. item.name
			local content = NFS.read(filepath)
			if content then
				local ok, replay = pcall(json.decode, content)
				if ok and replay and replay.ante_snapshots then
					-- Convert string ante keys to numbers for consistency
					local fixed = {}
					for k, v in pairs(replay.ante_snapshots) do
						fixed[tonumber(k) or k] = v
					end
					replay.ante_snapshots = fixed
					replay._source = "file"
					replay._filename = item.name
					table.insert(results, replay)
				else
					sendWarnMessage("Failed to parse replay: " .. item.name, "MULTIPLAYER")
				end
			end
		elseif item.type == "file" and item.name:match("%.log$") then
			local filepath = replays_dir .. "/" .. item.name
			local content = NFS.read(filepath)
			if content and log_parser then
				local ok, game_records = pcall(log_parser.process_log, content)
				if ok and game_records then
					local total = #game_records
					for idx, game in ipairs(game_records) do
						local ok2, replay = pcall(log_parser.to_replay, game)
						if ok2 and replay and replay.ante_snapshots and next(replay.ante_snapshots) then
							replay._source = "file"
							replay._filename = item.name
							replay._game_index = idx
							replay._game_count = total
							table.insert(results, replay)
						end
					end
				else
					sendWarnMessage("Failed to parse log: " .. item.name, "MULTIPLAYER")
				end
			end
		end
	end

	-- Sort by timestamp descending (newest first)
	table.sort(results, function(a, b)
		return (a.timestamp or 0) > (b.timestamp or 0)
	end)

	return results
end
