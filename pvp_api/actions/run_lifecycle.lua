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
		-- Start the draft with the server-issued pool. The draft only ever runs
		-- inside matchmaking, and every matchmaking queue has a server draft
		-- policy, so only the host (below) ever calls this with a real pool --
		-- guard against nil anyway so a stray call can't crash.
		local function start_draft(server_pool)
			MPAPI.BanPick.start(lobby, {
				pool_size = bp.pool_size,
				keep = bp.keep,
				schedule = bp.schedule,
				build_pool = function()
					if not server_pool then
						return {}
					end
					-- Server-provided cocktail items already carry their composition
					-- (item.decks); add PvP's display wording (rides the broadcast).
					return MP.decorate_cocktail_items(server_pool)
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
				local picked = survivors and survivors[1]
				-- The cocktail composition both clients run comes from the PICKED
				-- item (broadcast state) -- one source of truth, never the private
				-- weekly stash.
				if MP.set_match_cocktail then
					MP.set_match_cocktail(picked)
				end
				proceed(picked)
			end)
		end
		-- Only the host builds a pool, so only the host fetches; guests start
		-- straight into the "Selecting decks..." waiting state and render off the
		-- host's first broadcast. A fetch failure or an unusable pool (wrong size,
		-- unknown deck keys, out-of-cap stakes) aborts the draft -- there is no
		-- local-generation fallback to degrade into.
		if lobby and lobby.is_host then
			MP.fetch_draft_pool(function(server_pool)
				-- Staleness guard: the fetch resolves through the FIFO; if the match
				-- was cancelled (or this lobby died) meanwhile, don't start a draft
				-- into a dead lobby.
				if lobby ~= MPAPI.get_current_lobby() then
					return
				end
				local failure_detail
				if not server_pool then
					failure_detail = "no pool returned"
				elseif not MP.validate_server_pool(server_pool, bp.pool_size) then
					failure_detail = "pool failed validation"
				end
				if failure_detail then
					sendWarnMessage("[draft] aborting draft -- " .. failure_detail, "MULTIPLAYER")
					-- No local-generation fallback exists: show the user only a
					-- generic error and tear the match down via the standard
					-- leave-lobby path -- one abort path, never invent a second.
					pcall(function()
						attention_text({
							text = localize("k_draft_failed"),
							scale = 0.9,
							hold = 4,
							backdrop_colour = G.C.RED,
							align = "cm",
							offset = { x = 0, y = -3.5 },
							major = G.ROOM_ATTACH,
						})
					end)
					MP.pvp_leave_lobby()
					pcall(MPAPI.refresh_current_view)
					return
				end
				start_draft(server_pool)
			end)
		else
			start_draft(nil)
		end
	else
		proceed(meta.deck)
	end
end)

relay("pvp_stop_game", "stopGame")
