-- Ghost Replay: load and play back ghost replays from log files.

function MP.is_mp_or_ghost()
	return MP.LOBBY.code or MP.GHOST.is_active()
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

-- Load ghost replays from .log and .json files in the replays/ folder.
-- Files are read once when the picker is opened; drop a Lovely log or
-- a .json file into replays/ and it shows up in the ghost replay picker.

-- Load a .json replay file — useful for verifying log parser output or
-- loading replays exported from external tools.
local function load_json_replay(filepath, filename)
	local json = require("json")
	local content = NFS.read(filepath)
	if not content then return nil end

	local ok, replay = pcall(json.decode, content)
	if not ok or not replay or not replay.ante_snapshots then
		sendWarnMessage("Failed to parse replay: " .. filename, "MULTIPLAYER")
		return nil
	end

	-- Convert string ante keys to numbers for consistency
	local fixed = {}
	for k, v in pairs(replay.ante_snapshots) do
		fixed[tonumber(k) or k] = v
	end
	replay.ante_snapshots = fixed
	replay._source = "file"
	replay._filename = filename
	return replay
end

function MP.GHOST.load_folder_replays()
	local log_parser = MP.load_mp_file("lib/log_parser.lua")
	local replays_dir = MP.path .. "/replays"
	local dir_info = NFS.getInfo(replays_dir)
	if not dir_info or dir_info.type ~= "directory" then return {} end

	local items = NFS.getDirectoryItemsInfo(replays_dir)
	local results = {}

	for _, item in ipairs(items) do
		if item.type == "file" and item.name:match("%.log$") then
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
		elseif item.type == "file" and item.name:match("%.json$") then
			local replay = load_json_replay(replays_dir .. "/" .. item.name, item.name)
			if replay then table.insert(results, replay) end
		end
	end

	-- Sort by timestamp descending (newest first)
	table.sort(results, function(a, b)
		return (a.timestamp or 0) > (b.timestamp or 0)
	end)

	return results
end
