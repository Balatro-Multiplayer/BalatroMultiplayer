-- Singleplayer ruleset state (parallels MP.LOBBY.config.ruleset for multiplayer)
MP.SP = { ruleset = nil, practice = false, unlimited_slots = false, edition_cycling = false }

function MP.is_practice_mode()
	return MP.SP.practice == true
end

function G.FUNCS.setup_practice_mode(e)
	G.SETTINGS.paused = true
	MP.LOBBY.config.ruleset = nil
	MP.LOBBY.config.gamemode = nil
	MP.SP.ruleset = nil
	MP.SP.practice = true
	MP.SP.unlimited_slots = false
	MP.SP.edition_cycling = false
	MP.GHOST.clear()

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_options("practice"),
	})
end

function G.FUNCS.start_practice_run(e)
	G.FUNCS.exit_overlay_menu()
	if MP.GHOST.is_active() then
		local r = MP.GHOST.replay
		MP.reset_game_states()
		local starting_lives = MP.LOBBY.config.starting_lives or 4
		MP.GAME.lives = starting_lives
		MP.GAME.enemy.lives = starting_lives
		local deck_key = MP.UTILS.get_deck_key_from_name(r.deck)
		if deck_key then G.GAME.viewed_back = G.P_CENTERS[deck_key] end
		G.FUNCS.start_run(e, { seed = r.seed, stake = r.stake or 1 })
		sendDebugMessage(
			string.format(
				"Practice run state: practice=%s, ghost=%s, ruleset=%s, gamemode=%s, deck_key=%s, lives=%s, enemy_lives=%s, seed=%s, stake=%s",
				tostring(MP.is_practice_mode()),
				tostring(MP.GHOST.is_active()),
				tostring(MP.get_active_ruleset()),
				tostring(MP.get_active_gamemode()),
				tostring(deck_key),
				tostring(MP.GAME.lives),
				tostring(MP.GAME.enemy.lives),
				tostring(G.GAME.pseudorandom and G.GAME.pseudorandom.seed or "?"),
				tostring(G.GAME.stake or "?")
			),
			"MULTIPLAYER"
		)
	else
		G.FUNCS.setup_run(e)
	end
end

function G.FUNCS.toggle_unlimited_slots(e)
	MP.SP.unlimited_slots = not MP.SP.unlimited_slots
end
