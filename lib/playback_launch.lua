-- §22.2/§22.3 (Phase 5): bootstraps a local, single-player run seeded to
-- reproduce a PREVIOUSLY RECORDED match's exact seed/deck/stake/ruleset --
-- distinct from PVP._start_practice (lib/practice_mode.lua), which uses
-- practice's own ephemeral defaults, since a human practicing doesn't care
-- about matching a specific past match's cards. Reuses the exact same
-- local-lobby machinery (MPAPI.create_local_lobby/setup_lobby_mirror)
-- practice mode does -- see practice_mode.lua's own header comment for why
-- that reuse is safe (same primitives real private lobbies use). A local
-- lobby's `.code` stays nil (MPAPI.create_local_lobby never sets one), which
-- is also why PVP.RLOG never records during a playback session already,
-- confirmed live: RLOG.is_active() (lib/replay_log.lua) already gates on
-- `PVP.LOBBY.code`, unchanged -- no separate "don't record during replay"
-- guard needed.
--
-- `manifest` is the {seed, deck, sleeve, challenge, stake, ruleset, gamemode,
-- ...} table recorded once per match by PVP.RLOG.begin_run (see
-- networking/action_handlers.lua's action_start_game) and shipped as the
-- carbon log's own "manifest" event -- i.e. exactly what
-- MPAPI.playback.build_timeline's first event already carries for whichever
-- player is chosen as POV.
function PVP._start_playback(manifest, on_ready)
	PVP.reset_lobby_config()
	PVP.SP.practice = true
	PVP.SP.ruleset = manifest.ruleset

	local lobby = MPAPI.create_local_lobby(PVP.id, { max_players = 1 })
	if not lobby then
		PVP.SP.practice = false
		return
	end
	lobby.suppress_lobby_view = true
	PVP._pvp_kind = PVP.LobbyAccess.PRACTICE
	PVP._pvp_gamemode = manifest.gamemode
	PVP.setup_lobby_mirror(lobby)

	-- lobby_start_run (networking/action_handlers.lua) reads deck/stake off
	-- PVP.LOBBY.deck, NOT off the args table passed to it (args.stake there is
	-- unused dead weight -- confirmed by reading its body) -- these must be set
	-- here for the seed to actually reproduce the original match's cards.
	PVP.LOBBY.deck.back = manifest.deck
	PVP.LOBBY.deck.stake = manifest.stake
	PVP.LOBBY.deck.sleeve = manifest.sleeve
	PVP.LOBBY.deck.challenge = manifest.challenge
	PVP.LOBBY.config.ruleset = manifest.ruleset
	PVP.LOBBY.config.gamemode = manifest.gamemode

	PVP.GAME.lives = PVP.LOBBY.config.starting_lives

	lobby:on(MPAPI.LobbyEvent.CONNECTED, function()
		PVP.LOBBY.guest = { username = "???", id = "practice" }
		lobby:set_metadata(PVP.pvp_lobby_metadata(manifest.gamemode, PVP.LobbyAccess.PRACTICE))
		G.FUNCS.lobby_start_run(nil, { seed = manifest.seed })
	end)

	PVP._playback_wait_for(function()
		return G.STATE == G.STATES.BLIND_SELECT
	end, on_ready)
end

-- Minimal, self-contained one-shot condition poll (no ClaudeControl
-- dependency -- MPAPI/PvP must work standalone without it installed).
-- Mirrors the shape of MPAPI's own Game:update-hook pattern
-- (BalatroMultiplayerAPI/api/playback/driver.lua) rather than copying
-- ClaudeControl's coroutine-based lib/wait.lua directly.
PVP._playback_waiters = PVP._playback_waiters or {}

function PVP._playback_wait_for(predicate, callback)
	PVP._playback_waiters[#PVP._playback_waiters + 1] = { predicate = predicate, callback = callback }
end

local _playback_launch_update_ref = Game.update
function Game:update(dt)
	_playback_launch_update_ref(self, dt)
	for i = #PVP._playback_waiters, 1, -1 do
		local w = PVP._playback_waiters[i]
		if w.predicate() then
			table.remove(PVP._playback_waiters, i)
			w.callback()
		end
	end
end
