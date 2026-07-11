-- Singleplayer ruleset state (parallels MP.LOBBY.config.ruleset for multiplayer).
-- Live rulesets / game-state / networking read MP.SP + MP.is_practice_mode() to know
-- they are NOT in practice, so this state core must always exist. The actual practice
-- launcher (setup_practice_mode / start_practice_run) lived in the now-removed legacy
-- play_button menu flow; practice is a disabled no-op in the API menu (mp_pvp_practice),
-- so those entry points were dropped. Re-add them here when practice mode is wired.
MP.SP = { ruleset = nil, practice = false, unlimited_slots = false, edition_cycling = false }

function MP.is_practice_mode()
	return MP.SP.practice == true
end
