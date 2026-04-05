-- Log Parser: parse Lovely log files into ghost replay tables.
-- Lua port of tools/log_to_ghost_replay.py

local LOG_PARSER = {}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function parse_timestamp(line)
	return line:match("(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d)")
end

local function parse_sent_json(line)
	local raw = line:match("Client sent message: ({.*})%s*$")
	if not raw then return nil end
	local json = require("json")
	local ok, obj = pcall(json.decode, raw)
	if ok and type(obj) == "table" then return obj end
	return nil
end

local function parse_sent_kv(line)
	local raw = line:match("Client sent message: (action:%w+.-)%s*$")
	if not raw then return nil end
	local pairs_t = {}
	for part in raw:gmatch("[^,]+") do
		local k, v = part:match("^%s*(.-):%s*(.-)%s*$")
		if k then pairs_t[k] = v end
	end
	return pairs_t
end

local function parse_got_kv(line)
	local action, kv_str = line:match("Client got (%w+) message:%s*(.-)%s*$")
	if not action then return nil end
	local pairs_t = {}
	for key, val in kv_str:gmatch("%((%w+):%s*([^)]*)%)") do
		val = val:match("^%s*(.-)%s*$")
		if val == "true" then
			pairs_t[key] = true
		elseif val == "false" then
			pairs_t[key] = false
		elseif val:match("^%-?%d+%.%d+$") then
			pairs_t[key] = tonumber(val)
		elseif val:match("^%-?%d+$") then
			pairs_t[key] = tonumber(val)
		else
			pairs_t[key] = val
		end
	end
	return action, pairs_t
end

local function parse_joker_list_full(raw)
	local jokers = {}
	for entry in raw:gmatch("[^;]+") do
		entry = entry:match("^%s*(.-)%s*$")
		if entry ~= "" then
			local parts = {}
			for p in entry:gmatch("[^%-]+") do parts[#parts + 1] = p end
			local joker = { key = parts[1] }
			if parts[2] and parts[2] ~= "none" then joker.edition = parts[2] end
			if parts[3] and parts[3] ~= "none" then joker.sticker1 = parts[3] end
			if parts[4] and parts[4] ~= "none" then joker.sticker2 = parts[4] end
			jokers[#jokers + 1] = joker
		end
	end
	return jokers
end

-------------------------------------------------------------------------------
-- Game record (fresh state)
-------------------------------------------------------------------------------

local function new_game()
	return {
		seed = nil,
		ruleset = nil,
		gamemode = nil,
		deck = nil,
		stake = nil,
		player_name = nil,
		nemesis_name = nil,
		starting_lives = 4,
		is_host = nil,
		lobby_code = nil,
		ante_snapshots = {},
		winner = nil,
		final_ante = 1,
		current_ante = 0,
		player_lives = 4,
		enemy_lives = 4,
		-- PvP round tracking (transient)
		pvp_player_score = "0",
		pvp_enemy_score = "0",
		pvp_hands = {},
		in_pvp = false,
		-- End-game data
		player_jokers = {},
		nemesis_jokers = {},
		player_stats = {},
		nemesis_stats = {},
		-- Per-ante shop spending
		shop_spending = {},
		-- Non-PvP round failures
		failed_rounds = {},
		-- Timing
		game_start_ts = nil,
		game_end_ts = nil,
		-- Card activity
		cards_bought = {},
		cards_sold = {},
		cards_used = {},
	}
end

-------------------------------------------------------------------------------
-- Duration helper
-------------------------------------------------------------------------------

local function ts_to_epoch(ts_str)
	local y, mo, d, h, mi, s = ts_str:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
	if not y then return nil end
	return os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d),
	                  hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) })
end

local function format_duration(start_ts, end_ts)
	local t0 = ts_to_epoch(start_ts)
	local t1 = ts_to_epoch(end_ts)
	if not t0 or not t1 then return nil end
	local secs = t1 - t0
	if secs < 0 then return nil end
	local mins = math.floor(secs / 60)
	local s = secs % 60
	return string.format("%dm%02ds", mins, s)
end

-------------------------------------------------------------------------------
-- Core parser
-------------------------------------------------------------------------------

function LOG_PARSER.process_log(content)
	local games = {}
	local game = new_game()
	local last_lobby_options = nil
	local in_game = false

	for line in content:gmatch("[^\r\n]+") do
		if line:find("MULTIPLAYER", 1, true) then
			local ts = parse_timestamp(line)

			-- Direct log messages (not Client sent/got)
			if line:find("Sending end game jokers:", 1, true) then
				local raw = line:match("Sending end game jokers:%s*(.-)%s*$")
				if raw then game.player_jokers = parse_joker_list_full(raw) end
				goto continue
			end

			if line:find("Received end game jokers:", 1, true) then
				local raw = line:match("Received end game jokers:%s*(.-)%s*$")
				if raw then game.nemesis_jokers = parse_joker_list_full(raw) end
				goto continue
			end

			-- Sent messages (JSON)
			local sent = parse_sent_json(line)
			if sent then
				local action = sent.action

				if action == "username" then
					game.player_name = sent.username

				elseif action == "lobbyOptions" then
					last_lobby_options = sent

				elseif action == "setAnte" then
					local ante = sent.ante or 0
					game.current_ante = ante
					if ante > game.final_ante then game.final_ante = ante end

				elseif action == "playHand" then
					local score = tostring(sent.score or "0")
					local hands_left = sent.handsLeft or 0
					if game.in_pvp then
						game.pvp_player_score = score
						game.pvp_hands[#game.pvp_hands + 1] = {
							score = score,
							hands_left = hands_left,
							side = "player",
						}
					end

				elseif action == "setLocation" then
					local loc = sent.location or ""
					if loc:find("bl_mp_nemesis", 1, true) then
						game.in_pvp = true
					end

				elseif action == "failRound" then
					game.failed_rounds[#game.failed_rounds + 1] = game.current_ante

				elseif action == "spentLastShop" then
					local amount = sent.amount or 0
					game.shop_spending[game.current_ante] =
						(game.shop_spending[game.current_ante] or 0) + amount

				elseif action == "nemesisEndGameStats" then
					local stats = {}
					for k, v in pairs(sent) do
						if k ~= "action" then stats[k] = v end
					end
					game.player_stats = stats

				elseif action == "startGame" then
					if ts then game.game_start_ts = game.game_start_ts or ts end
				end

				goto continue
			end

			-- Sent messages (key:value format — card activity)
			local sent_kv = parse_sent_kv(line)
			if sent_kv then
				local action = sent_kv.action
				if action == "boughtCardFromShop" then
					game.cards_bought[#game.cards_bought + 1] = {
						card = sent_kv.card or "",
						cost = tonumber(sent_kv.cost) or 0,
						ante = game.current_ante,
					}
				elseif action == "soldCard" then
					game.cards_sold[#game.cards_sold + 1] = {
						card = sent_kv.card or "",
						ante = game.current_ante,
					}
				elseif action == "usedCard" then
					game.cards_used[#game.cards_used + 1] = {
						card = sent_kv.card or "",
						ante = game.current_ante,
					}
				end
				goto continue
			end

			-- Received messages (key-value)
			local action, kv = parse_got_kv(line)
			if not action then goto continue end

			if action == "joinedLobby" then
				if kv.code then game.lobby_code = tostring(kv.code) end

			elseif action == "lobbyInfo" then
				if kv.isHost ~= nil then game.is_host = kv.isHost end
				if game.is_host == true and kv.guest then
					game.nemesis_name = tostring(kv.guest)
				elseif game.is_host == false and kv.host then
					game.nemesis_name = tostring(kv.host)
				end

			elseif action == "startGame" then
				in_game = true
				if ts then game.game_start_ts = game.game_start_ts or ts end
				if last_lobby_options then
					game.ruleset = last_lobby_options.ruleset
					game.gamemode = last_lobby_options.gamemode
					game.deck = last_lobby_options.back or "Red Deck"
					game.stake = last_lobby_options.stake or 1
					game.starting_lives = last_lobby_options.starting_lives or 4
					game.player_lives = game.starting_lives
					game.enemy_lives = game.starting_lives
				end

			elseif action == "playerInfo" then
				if kv.lives then game.player_lives = kv.lives end

			elseif action == "enemyInfo" then
				if kv.lives then game.enemy_lives = kv.lives end
				if kv.score then
					local score_str = tostring(kv.score)
					if game.in_pvp then
						game.pvp_enemy_score = score_str
						game.pvp_hands[#game.pvp_hands + 1] = {
							score = score_str,
							hands_left = kv.handsLeft or 0,
							side = "enemy",
						}
					end
				end

			elseif action == "enemyLocation" then
				local loc = kv.location or ""
				if tostring(loc):find("bl_mp_nemesis", 1, true) then
					game.in_pvp = true
				end

			elseif action == "endPvP" then
				local lost = kv.lost
				local result = lost and "loss" or "win"

				-- Clean up hand progression
				local cleaned = {}
				local seen_final = {}
				for _, h in ipairs(game.pvp_hands) do
					if h.score == "0" and h.hands_left >= 4 then
						-- skip initial zero-score entries
					elseif #cleaned > 0
						and cleaned[#cleaned].score == h.score
						and cleaned[#cleaned].side == h.side then
						-- deduplicate consecutive same-score same-side
					elseif seen_final[h.side] and h.score == seen_final[h.side] then
						-- skip re-broadcast of final score
					else
						if h.hands_left == 0 then
							seen_final[h.side] = h.score
						end
						cleaned[#cleaned + 1] = h
					end
				end

				game.ante_snapshots[game.current_ante] = {
					ante = game.current_ante,
					player_score = game.pvp_player_score,
					enemy_score = game.pvp_enemy_score,
					player_lives = game.player_lives,
					enemy_lives = game.enemy_lives,
					result = result,
					hands = cleaned,
				}

				-- Reset PvP tracking
				game.in_pvp = false
				game.pvp_player_score = "0"
				game.pvp_enemy_score = "0"
				game.pvp_hands = {}

			elseif action == "winGame" then
				game.winner = "player"

			elseif action == "loseGame" then
				game.winner = "nemesis"

			elseif action == "nemesisEndGameStats" then
				local stats = {}
				for k, v in pairs(kv) do
					if k ~= "action" then stats[k] = v end
				end
				game.nemesis_stats = stats

			elseif action == "stopGame" then
				if kv.seed then game.seed = tostring(kv.seed) end
				if ts then game.game_end_ts = ts end
				if in_game then
					games[#games + 1] = game
				end
				in_game = false
				local prev_name = game.player_name
				game = new_game()
				game.player_name = prev_name
				last_lobby_options = nil
			end

			::continue::
		end
	end

	-- Capture mid-game record if log ends without stopGame
	if in_game and game.winner then
		games[#games + 1] = game
	end

	return games
end

-------------------------------------------------------------------------------
-- Convert a parsed game record to a replay table (same shape as JSON replays)
-------------------------------------------------------------------------------

function LOG_PARSER.to_replay(game)
	local snapshots = {}
	for ante, snap in pairs(game.ante_snapshots) do
		local snap_t = {
			player_score = snap.player_score,
			enemy_score = snap.enemy_score,
			player_lives = snap.player_lives,
			enemy_lives = snap.enemy_lives,
			result = snap.result,
		}
		if snap.hands and #snap.hands > 0 then
			snap_t.hands = {}
			for _, h in ipairs(snap.hands) do
				snap_t.hands[#snap_t.hands + 1] = {
					score = h.score,
					hands_left = h.hands_left,
					side = h.side,
				}
			end
		end
		snapshots[ante] = snap_t
	end

	local replay = {
		gamemode = game.gamemode or "gamemode_mp_attrition",
		final_ante = game.final_ante,
		ante_snapshots = snapshots,
		winner = game.winner or "unknown",
		timestamp = os.time(),
		ruleset = game.ruleset or "ruleset_mp_blitz",
		seed = game.seed or "UNKNOWN",
		deck = game.deck or "Red Deck",
		stake = game.stake or 1,
	}
	if game.player_name then replay.player_name = game.player_name end
	if game.nemesis_name then replay.nemesis_name = game.nemesis_name end
	if game.lobby_code then replay.lobby_code = game.lobby_code end

	if game.game_start_ts and game.game_end_ts then
		local dur = format_duration(game.game_start_ts, game.game_end_ts)
		if dur then replay.duration = dur end
	end

	if #game.player_jokers > 0 then replay.player_jokers = game.player_jokers end
	if #game.nemesis_jokers > 0 then replay.nemesis_jokers = game.nemesis_jokers end
	if next(game.player_stats) then replay.player_stats = game.player_stats end
	if next(game.nemesis_stats) then replay.nemesis_stats = game.nemesis_stats end
	if next(game.shop_spending) then replay.shop_spending = game.shop_spending end
	if #game.failed_rounds > 0 then replay.failed_rounds = game.failed_rounds end
	if #game.cards_bought > 0 then replay.cards_bought = game.cards_bought end
	if #game.cards_sold > 0 then replay.cards_sold = game.cards_sold end
	if #game.cards_used > 0 then replay.cards_used = game.cards_used end

	return replay
end

return LOG_PARSER
