local A = MP._pvp_action_helpers.A
local relay = MP._pvp_action_helpers.relay

A("pvp_start_game", function(_at, from, params)
	if MP.stop_ready_resync then
		MP.stop_ready_resync()
	end
	if MP.reset_ready_state then
		MP.reset_ready_state()
	end

	local lobby = MPAPI.get_current_lobby()
	local meta = (lobby and lobby:get_metadata()) or {}
	local gm_def = meta.queue_mode and MPAPI.GameModes[meta.queue_mode]

	-- Ban-pick survivors are center KEYS (e.g. 'b_red'); MP's run start wants a deck
	-- NAME. Resolve either form to a name, and pin it as the lobby deck so MP's
	-- copy_host_deck (config.back -> deck.back) doesn't clobber the drafted deck.
	local function apply_deck(ref)
		if not ref then
			return
		end
		local center = G.P_CENTERS[ref]
		local name = (center and center.name) or ref
		MP.LOBBY.config.back = name
		MP.LOBBY.deck.back = name
	end

	-- picked is a { key, stake } item (deck+stake draft), a plain deck key/name, or nil.
	local function proceed(picked)
		local deck_ref, stake
		if type(picked) == "table" then
			deck_ref, stake = picked.key, picked.stake
		else
			deck_ref = picked
		end
		apply_deck(deck_ref)
		if stake then
			MP.LOBBY.config.stake = stake
			MP.LOBBY.deck.stake = stake
		end
		if lobby and lobby.is_host then
			MP.referee_reset(MP.LOBBY.config.starting_lives)
		end
		MP.dispatch_action("startGame", { seed = params.seed, stake = stake or params.stake })
	end

	-- Matchmaking (2 players) with a ban_pick config: run the deck+stake draft first, in
	-- lockstep off this same broadcast; the picked deck+stake then starts the run.
	if gm_def and gm_def.ban_pick and MP.is_matchmaking and MP.is_matchmaking() then
		local bp = gm_def.ban_pick
		MPAPI.BanPick.start(lobby, {
			pool_size = bp.pool_size,
			keep = bp.keep,
			schedule = bp.schedule,
			-- 9 distinct random deck backs, each paired with a random stake. The stake
			-- cap mirrors MP's own (ui/lobby/lobby.lua:346): MP.DECK.MAX_STAKE when a
			-- compatibility mod restricts it, else all 8.
			build_pool = function()
				local cap = (MP.DECK and MP.DECK.MAX_STAKE and MP.DECK.MAX_STAKE > 0) and MP.DECK.MAX_STAKE or 8
				local keys = {}
				for _, center in ipairs(G.P_CENTER_POOLS.Back or {}) do
					keys[#keys + 1] = center.key
				end
				for i = #keys, 2, -1 do
					local j = math.random(i)
					keys[i], keys[j] = keys[j], keys[i]
				end
				local pool = {}
				for i = 1, math.min(bp.pool_size, #keys) do
					pool[i] = { key = keys[i], stake = math.random(cap) }
				end
				return pool
			end,
			-- Stamp the stake sticker onto each deck back (see the game's back_sticker DrawStep).
			decorate_tile = function(card, item)
				if type(item) == "table" and item.stake then
					card.sticker = G.sticker_map[SMODS.stake_from_index(item.stake)]
				end
			end,
			state_action = "pvp_ban_pick_state",
			ban_action = "pvp_ban_pick_ban",
			on_refresh = function()
				if MP.lobby and MP.lobby.refresh_mm_status then
					MP.lobby.refresh_mm_status()
				end
			end,
		}, function(survivors)
			proceed(survivors and survivors[1])
		end)
	else
		proceed(meta.deck)
	end
end)

relay("pvp_stop_game", "stopGame")
