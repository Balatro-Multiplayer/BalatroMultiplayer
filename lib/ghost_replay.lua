-- Ghost Replay: load and play back ghost replays from log files.

function PVP.is_mp_or_ghost()
	return PVP.LOBBY.code or PVP.GHOST.is_active() or PVP.is_practice_mode()
end

PVP.GHOST = { active = false, replay = nil, flipped = false, gamemode = nil }

-- Per-ante playback state
PVP.GHOST._hands = {}
PVP.GHOST._hand_idx = 0
PVP.GHOST._advancing = false

function PVP.GHOST.load(replay)
	PVP.GHOST.active = true
	PVP.GHOST.replay = replay
	PVP.GHOST.flipped = false
	PVP.GHOST.gamemode = replay and replay.gamemode or nil
	PVP.GHOST._hands = {}
	PVP.GHOST._hand_idx = 0
	PVP.GHOST._advancing = false
end

function PVP.GHOST.clear()
	PVP.GHOST.active = false
	PVP.GHOST.replay = nil
	PVP.GHOST.flipped = false
	PVP.GHOST.gamemode = nil
	PVP.GHOST._hands = {}
	PVP.GHOST._hand_idx = 0
	PVP.GHOST._advancing = false
end

function PVP.GHOST.flip()
	PVP.GHOST.flipped = not PVP.GHOST.flipped
end

function PVP.GHOST.get_enemy_hands(ante)
	if not PVP.GHOST.replay or not PVP.GHOST.replay.ante_snapshots then return {} end
	local snapshot = PVP.GHOST.replay.ante_snapshots[ante] or PVP.GHOST.replay.ante_snapshots[tostring(ante)]
	if not snapshot or not snapshot.hands then return {} end
	local enemy_side = PVP.GHOST.flipped and "player" or "enemy"
	local out = {}
	for _, h in ipairs(snapshot.hands) do
		if h.side == enemy_side then
			out[#out + 1] = h
		end
	end
	return out
end

function PVP.GHOST.init_playback(ante)
	local hands = PVP.GHOST.get_enemy_hands(ante)
	PVP.GHOST._hands = hands
	PVP.GHOST._hand_idx = 0
	PVP.GHOST._advancing = false
	if #hands > 0 then
		PVP.GHOST._hand_idx = 1
		local score = PVP.INSANE_INT.from_string(hands[1].score)
		PVP.GAME.enemy.score = score
		PVP.GAME.enemy.real_score = score
		PVP.GAME.enemy.score_text = PVP.INSANE_INT.to_string(score)
		PVP.GAME.enemy.hands = hands[1].hands_left or 0
		PVP.GAME.enemy.info_received = true
		return true
	end
	return false
end

function PVP.GHOST.advance_hand()
	if PVP.GHOST._hand_idx >= #PVP.GHOST._hands then return false end
	PVP.GHOST._hand_idx = PVP.GHOST._hand_idx + 1
	local entry = PVP.GHOST._hands[PVP.GHOST._hand_idx]
	local score = PVP.INSANE_INT.from_string(entry.score)

	G.E_MANAGER:add_event(Event({
		blockable = false, blocking = false,
		trigger = "ease", delay = 0.5,
		ref_table = PVP.GAME.enemy.score,
		ref_value = "e_count",
		ease_to = score.e_count,
		func = function(t) return math.floor(t) end,
	}))
	G.E_MANAGER:add_event(Event({
		blockable = false, blocking = false,
		trigger = "ease", delay = 0.5,
		ref_table = PVP.GAME.enemy.score,
		ref_value = "coeffiocient",
		ease_to = score.coeffiocient,
		func = function(t) return math.floor(t) end,
	}))
	G.E_MANAGER:add_event(Event({
		blockable = false, blocking = false,
		trigger = "ease", delay = 0.5,
		ref_table = PVP.GAME.enemy.score,
		ref_value = "exponent",
		ease_to = score.exponent,
		func = function(t) return math.floor(t) end,
	}))

    PVP.GAME.enemy.real_score = score
	PVP.GAME.enemy.hands = entry.hands_left or 0
	PVP.GAME.enemy.info_received = true
	if PVP.UI.juice_up_pvp_hud then PVP.UI.juice_up_pvp_hud() end
	return true
end

function PVP.GHOST.playback_exhausted()
	return #PVP.GHOST._hands == 0 or PVP.GHOST._hand_idx >= #PVP.GHOST._hands
end

function PVP.GHOST.has_hand_data()
	return #PVP.GHOST._hands > 0
end

-- Reads target from hands array directly, bypassing the eased score table.
function PVP.GHOST.current_target_big()
	if PVP.GHOST._hand_idx < 1 or PVP.GHOST._hand_idx > #PVP.GHOST._hands then return to_big(0) end
	local entry = PVP.GHOST._hands[PVP.GHOST._hand_idx]
	local score = PVP.INSANE_INT.from_string(entry.score)
	return to_big(score.coeffiocient * (10 ^ score.exponent))
end

function PVP.GHOST.get_nemesis_name()
	if not PVP.GHOST.replay then return nil end
	if PVP.GHOST.flipped then
		return PVP.GHOST.replay.player_name or localize("k_ghost")
	else
		return PVP.GHOST.replay.nemesis_name or localize("k_ghost")
	end
end

-- Returns a UI string table for the PvP blind name.
-- Uses a static { string = ... } entry (ghost name is fixed for the run),
-- unlike live PVP which uses { ref_table, ref_value } for reactive updates.
function PVP.GHOST.get_blind_name_ui()
	return { { string = PVP.GHOST.get_nemesis_name() } }
end

-- Resolve the end of a PvP round when the player has no hands left.
-- Returns "won", "game_over", or "continue".
function PVP.GHOST.resolve_pvp_hands_exhausted(chips)
	local beat_current = to_big(chips) >= PVP.GHOST.current_target_big()
	local all_exhausted = PVP.GHOST.playback_exhausted()

	if beat_current and all_exhausted then
		PVP.GAME.enemy.lives = PVP.GAME.enemy.lives - 1
		if PVP.GAME.enemy.lives <= 0 then
			PVP.GAME.won = true
			return "won"
		end
	else
		if PVP.LOBBY.config.gold_on_life_loss then
			PVP.GAME.comeback_bonus_given = false
			PVP.GAME.comeback_bonus = PVP.GAME.comeback_bonus + 1
		end
		PVP.GAME.lives = PVP.GAME.lives - 1
		PVP.UI.ease_lives(-1)
		if PVP.LOBBY.config.no_gold_on_round_loss and G.GAME.blind and G.GAME.blind.dollars then
			G.GAME.blind.dollars = 0
		end
		if PVP.GAME.lives <= 0 then
			return "game_over"
		end
	end
	PVP.GAME.end_pvp = true
	return "continue"
end

-- Resolve mid-hand state when the player still has hands remaining.
-- Checks whether the player has already beaten all ghost hands; if so, takes
-- an enemy life. If the ghost has more hands, kicks off the advance animation.
-- Returns true if the PvP round ended (win or end_pvp set).
function PVP.GHOST.resolve_pvp_mid_hand(chips)
	if not PVP.GHOST.has_hand_data() then return false end

	local beat_current = to_big(chips) >= PVP.GHOST.current_target_big()

	if beat_current and PVP.GHOST.playback_exhausted() then
		PVP.GAME.enemy.lives = PVP.GAME.enemy.lives - 1
		if PVP.GAME.enemy.lives <= 0 then
			PVP.GAME.won = true
			win_game()
			return true
		end
		PVP.GAME.end_pvp = true
		return true
	elseif beat_current and not PVP.GHOST.playback_exhausted() and not PVP.GHOST._advancing then
		PVP.GHOST._start_advance_sequence()
	end
	return false
end

-- Animate advancing through remaining ghost hands until the player's score
-- no longer beats the ghost, or all ghost hands are exhausted.
function PVP.GHOST._start_advance_sequence()
	PVP.GHOST._advancing = true
	local function step()
		PVP.GHOST.advance_hand()
		G.E_MANAGER:add_event(Event({
			blockable = false,
			blocking = false,
			trigger = "after",
			delay = 0.6,
			func = function()
				if to_big(G.GAME.chips) >= PVP.GHOST.current_target_big() and not PVP.GHOST.playback_exhausted() then
					step()
				else
					if to_big(G.GAME.chips) >= PVP.GHOST.current_target_big() and PVP.GHOST.playback_exhausted() then
						PVP.GAME.enemy.lives = PVP.GAME.enemy.lives - 1
						if PVP.GAME.enemy.lives <= 0 then
							PVP.GAME.won = true
							win_game()
							PVP.GHOST._advancing = false
							return true
						end
						PVP.GAME.end_pvp = true
					end
					PVP.GHOST._advancing = false
				end
				return true
			end,
		}))
	end
	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "after",
		delay = 0.5,
		func = function()
			step()
			return true
		end,
	}))
end

-- Handle life loss when the player fails a non-PvP round in ghost mode.
-- Returns "game_over" or nil.
function PVP.GHOST.resolve_round_fail()
	if PVP.LOBBY.config.death_on_round_loss and G.GAME.current_round.hands_played > 0 then
		PVP.GAME.lives = PVP.GAME.lives - 1
		PVP.UI.ease_lives(-1)
		if PVP.LOBBY.config.no_gold_on_round_loss and G.GAME.blind and G.GAME.blind.dollars then
			G.GAME.blind.dollars = 0
		end
		if PVP.GAME.lives <= 0 then
			return "game_over"
		end
	end
	return nil
end

function PVP.GHOST.is_active()
	return PVP.GHOST.active and PVP.GHOST.replay ~= nil
end

function PVP.GHOST.is_ruleset_supported(replay)
	if not replay or not replay.ruleset then return true end
	return PVP.Rulesets[replay.ruleset] ~= nil
end

function PVP.GHOST.format_score(s)
	local n = tonumber(s)
	if not n then return tostring(s) end
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(n)
end

function PVP.GHOST.build_label(r)
	local result_text = (r.winner == "player") and "W" or "L"
	local player_display = r.player_name or "?"
	local nemesis_display = r.nemesis_name or "?"
	local ante_display = tostring(r.final_ante or "?")

	local timestamp_display = ""
	if r.timestamp then timestamp_display = os.date("%m/%d", r.timestamp) end

	local game_tag = ""
	if r._game_index and r._game_count and r._game_count > 1 then
		game_tag = string.format(" [%d/%d]", r._game_index, r._game_count)
	end

	return string.format(
		"%s %s v %s A%s %s%s",
		result_text,
		player_display,
		nemesis_display,
		ante_display,
		timestamp_display,
		game_tag
	)
end

local function load_json_replay(filepath, filename)
	local json = require("json")
	local content = NFS.read(filepath)
	if not content then return nil end

	local ok, replay = pcall(json.decode, content)
	if not ok or not replay or not replay.ante_snapshots then
		sendWarnMessage("Failed to parse replay: " .. filename, "MULTIPLAYER")
		return nil
	end

	local fixed = {}
	for k, v in pairs(replay.ante_snapshots) do
		fixed[tonumber(k) or k] = v
	end
	replay.ante_snapshots = fixed
	replay._source = "file"
	replay._filename = filename
	return replay
end

local function parse_log_into_replays(log_parser, content, filename, source)
	local out = {}
	if not (content and log_parser) then return out end
	local ok, game_records = pcall(log_parser.process_log, content)
	if not (ok and game_records) then
		sendWarnMessage("Failed to parse log: " .. filename, "MULTIPLAYER")
		return out
	end
	local total = #game_records
	for idx, game in ipairs(game_records) do
		local ok2, replay = pcall(log_parser.to_replay, game)
		if ok2 and replay and replay.ante_snapshots and next(replay.ante_snapshots) then
			replay._source = source
			replay._filename = filename
			replay._game_index = idx
			replay._game_count = total
			out[#out + 1] = replay
		end
	end
	return out
end

function PVP.GHOST.load_folder_replays()
	local log_parser = PVP.load_mp_file("lib/log_parser.lua")
	local replays_dir = PVP.path .. "/replays"
	local dir_info = NFS.getInfo(replays_dir)
	if not dir_info or dir_info.type ~= "directory" then return {} end

	local items = NFS.getDirectoryItemsInfo(replays_dir)
	local results = {}

	for _, item in ipairs(items) do
		if item.type == "file" and item.name:match("%.log$") then
			local content = NFS.read(replays_dir .. "/" .. item.name)
			for _, replay in ipairs(parse_log_into_replays(log_parser, content, item.name, "file")) do
				results[#results + 1] = replay
			end
		elseif item.type == "file" and item.name:match("%.json$") then
			local replay = load_json_replay(replays_dir .. "/" .. item.name, item.name)
			if replay then table.insert(results, replay) end
		end
	end

	table.sort(results, function(a, b)
		return (a.timestamp or 0) > (b.timestamp or 0)
	end)

	return results
end

-- NFS is nativefs — accepts absolute paths directly, no sandboxing.
local function lovely_log_dir()
	local ok, lovely = pcall(require, "lovely")
	if not (ok and lovely and lovely.log_path) then return nil end
	local dir = lovely.log_path:match("(.*)[/\\]")
	if not dir or dir == "" then return nil end
	return dir
end

-- A single .log file can contain multiple games; parse newest-first and stop once we hit `limit`.
function PVP.GHOST.load_lovely_log_replays(limit)
	limit = limit or 10
	local dir = lovely_log_dir()
	if not dir then return {} end

	local items = NFS.getDirectoryItemsInfo(dir)
	if not items then return {} end
	local logs = {}
	for _, item in ipairs(items) do
		if item.type == "file" and item.name:match("%.log$") then
			logs[#logs + 1] = item
		end
	end
	table.sort(logs, function(a, b)
		return (a.modtime or 0) > (b.modtime or 0)
	end)

	local log_parser = PVP.load_mp_file("lib/log_parser.lua")
	local results = {}
	for _, item in ipairs(logs) do
		local content = NFS.read(dir .. "/" .. item.name)
		for _, replay in ipairs(parse_log_into_replays(log_parser, content, item.name, "lovely_log")) do
			results[#results + 1] = replay
		end
		if #results >= limit then break end
	end

	table.sort(results, function(a, b)
		return (a.timestamp or 0) > (b.timestamp or 0)
	end)

	while #results > limit do
		results[#results] = nil
	end
	return results
end
