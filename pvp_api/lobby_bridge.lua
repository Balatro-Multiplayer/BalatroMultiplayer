-- PVP.LOBBY <- API-lobby mirror.
--
-- The whole PVP codebase (HUD, gameplay, run-start) reads PVP.LOBBY.* / PVP.GAME.*,
-- but the API owns the real lobby. This shim subscribes to the API lobby's events
-- and mirrors its state (code, host/guest identity, is_host, metadata->config) into
-- PVP.LOBBY so PVP's existing code keeps working unchanged. It is the PvP analog of
-- SPDRN.setup_lobby_events (BalatroMultiplayerSpeed/ui/lobby/events.lua).
--
-- Call PVP.setup_lobby_mirror(lobby) right after MPAPI.create_lobby / join_lobby /
-- a matchmaking lobby_ready, before signalling ready.

-- The single opponent in a 1v1 PvP lobby (nil until a second player is present).
function PVP.get_opponent_id()
	local lobby = MPAPI.get_current_lobby()
	if not lobby then
		return nil
	end
	for _, p in ipairs(lobby:get_players()) do
		if p.id ~= lobby.player_id then
			return p.id
		end
	end
	return nil
end

-- The gamemode-defined "current target": whichever player's enemy-facing state
-- (score/hands/lives sync, HUD, joker targeting like Asteroid/Penny Pincher/the
-- Nemesis boss blind) should be treated as "the enemy" right now. Host-computed
-- and broadcast in every N>2 case -- never a client-side race.
--  - Nemesis-pairing (rotating no-repeat duels, N>2): this ante's assigned partner,
--    broadcast by the host each ante; nil if byed or not yet received.
--  - Plain 1v1: the sole other lobby player, unchanged from before this existed.
--  - Manhunt (N>2): a Hunter's target is always the sole Runner, resolved locally
--    from the roster (static for the whole match, no broadcast needed). The
--    Runner's target is whichever Hunter currently has the highest score --
--    PVP.GAME.manhunt_target_id, broadcast live by the host (pvp_api/referee.lua).
--  - Teams (N>2): PVP.GAME.team_card_target_id, one random opposing-team member
--    per player, re-picked once per ante by the host (same cadence as Nemesis
--    pairing) -- used for joker/consumable triggering. The Teams score DISPLAY is
--    a separate aggregate broadcast (pvp_team_score_board) read directly by the
--    HUD, not routed through current_target_id().
--  - Royale (N>2, no pairing): PVP.GAME.royale_target_id, broadcast live by the
--    host and personalized per player -- a safe player's target is the adjacent
--    player with the next-lower score (their safety margin), an unsafe player's
--    target is the adjacent player with the next-higher score (what they need to
--    beat). See PVP.referee_rank_royale/broadcast_royale_targets.
function PVP.current_target_id()
	if PVP.LOBBY.config.nemesis_pairing then
		return PVP.GAME.nemesis_partner_id
	end
	local lobby = MPAPI.get_current_lobby()
	if not lobby then
		return nil
	end
	if #lobby:get_players() == 2 then
		return PVP.get_opponent_id()
	end
	if PVP.LOBBY.config.manhunt then
		if PVP.LOBBY.team_id == "HUNTER" then
			for id, role in pairs(PVP.LOBBY.roster or {}) do
				if role == "RUNNER" then
					return id
				end
			end
			return nil
		end
		return PVP.GAME.manhunt_target_id
	end
	if PVP.LOBBY.config.team_based then
		return PVP.GAME.team_card_target_id
	end
	return PVP.GAME.royale_target_id
end

-- True only while byed in Nemesis-pairing mode (an odd-numbered alive roster
-- leaves one player without a partner this ante) -- distinct from "target not
-- yet received", which current_target_id() also represents as nil. Guards that
-- need to reject stray senders while genuinely byed must check this explicitly
-- rather than relying on current_target_id() == nil, which is ambiguous between
-- the two cases.
function PVP.is_byed()
	return PVP.LOBBY.config.nemesis_pairing and PVP.GAME.nemesis_partner_id == nil
end

local function player_name(lobby, player_id)
	for _, p in ipairs(lobby:get_players()) do
		if p.id == player_id then
			return p.displayName or p.id
		end
	end
	return nil
end

-- Copy the host-authored shared metadata into PVP.LOBBY.config / PVP.LOBBY.deck so
-- PVP's ruleset/gamemode/option reads resolve. Metadata carries the lobby config
-- fields plus PvP keys (gamemode/ruleset/kind/deck/stake).
local function mirror_metadata(lobby)
	local meta = lobby:get_metadata() or {}
	-- `gamemode`/`ruleset` in metadata are already MPAPI's own content keys
	-- ("gamemode_mp_attrition" / "ruleset_mp_chocolate_ranked"), so they pass straight
	-- through -- MPAPI.get_active_gamemode()/get_active_ruleset() read this same
	-- metadata directly and need no translation. `queue_mode` carries the separate
	-- API/queue/bridge key (e.g. "pvp_chocolate") only nemesis_pairing derivation below
	-- still needs.
	local def = meta.queue_mode and PVP.PVP_GAMEMODES and PVP.PVP_GAMEMODES[meta.queue_mode]
	for k, v in pairs(meta) do
		if k ~= "deck" and k ~= "kind" then
			PVP.LOBBY.config[k] = v
		end
	end
	-- nemesis_pairing isn't part of the shared metadata schema, so it can't ride the
	-- generic loop above -- but every client (not just the host, who's the only one
	-- that runs the active gamemode's start_run) needs it set correctly, since
	-- PVP.current_target_id/attrition.lua's bye check/the joker-targeting guards all
	-- run client-side. Derive it the same way gamemode/ruleset are derived here.
	PVP.LOBBY.config.nemesis_pairing = (def and def.nemesis_pairing) or nil
	-- Same derivation for Manhunt/Teams -- every client (not just the host) needs
	-- these to resolve PVP.current_target_id(), the referee's mode branch, and the
	-- lobby-options picker, since none of them ride the generic per-key loop above.
	PVP.LOBBY.config.manhunt = (def and def.manhunt) or nil
	PVP.LOBBY.config.team_based = (def and def.team_based) or nil
	if meta.deck then
		PVP.LOBBY.deck.back = meta.deck
	end
	if meta.stake then
		PVP.LOBBY.deck.stake = tonumber(meta.stake) or PVP.LOBBY.deck.stake
	end
end

-- Reflect roster/host state into the PVP.LOBBY.host / .guest identity slots that PVP's
-- HUD and enemy tracking read. Every live caller of these slots (blind_hud, game_end,
-- blind_choice, matchmaking cancel text, Distro.lua) uses the
-- `is_host and LOBBY.guest or LOBBY.host` idiom purely to mean "my current
-- opponent" -- never "whichever player is the literal lobby host" -- so the
-- non-self slot must resolve to PVP.current_target_id(), not an arbitrary roster
-- pick. In 1v1 that's still just the sole other player (current_target_id()
-- delegates to PVP.get_opponent_id() there); in Royale/Nemesis (N>2) it's nil
-- until a target latches, same "not yet known" semantics as the masked
-- score/hands fields elsewhere -- not a wrong name.
local function mirror_players(lobby)
	local self_name = player_name(lobby, lobby.player_id) or PVP.LOBBY.username or "Guest"
	local opp_id = PVP.current_target_id()
	local opp_name = opp_id and player_name(lobby, opp_id) or nil
	PVP.LOBBY.is_host = lobby.is_host and true or false
	if lobby.is_host then
		PVP.LOBBY.host = { username = self_name, id = lobby.player_id }
		PVP.LOBBY.guest = opp_name and { username = opp_name, id = opp_id } or {}
	else
		PVP.LOBBY.host = opp_name and { username = opp_name, id = opp_id } or {}
		PVP.LOBBY.guest = { username = self_name, id = lobby.player_id }
	end
end
PVP.mirror_players = mirror_players

PVP.setup_lobby_mirror = function(lobby)
	PVP.CURRENT_LOBBY = lobby
	PVP.LOBBY.code = lobby.code
	PVP.LOBBY.connected = true
	PVP.LOBBY.is_host = lobby.is_host and true or false
	-- Manhunt/Teams role state must NOT carry over from a previous lobby: the
	-- same two players reconnecting into a different lobby (any gamemode, not
	-- just another Manhunt/Teams match) would otherwise inherit a stale
	-- "HUNTER"/"RUNNER"/"A"/"B" roster entry, which -- since referee_reset's
	-- team_based default ("pl.team_id or 'A'") only fires when team_id is still
	-- nil -- can silently stick as an invalid team_id for the new mode instead of
	-- being freshly assigned.
	PVP.LOBBY.roster = {}
	PVP.LOBBY.team_id = nil
	PVP.reset_game_states()
	-- Speed-style lobby view state: player-card grid + fresh ready tracker + buttons.
	if PVP.lobby then
		PVP.lobby.ref = lobby
		PVP.lobby.ui_ref = MPAPI.create_lobby_ui(lobby)
		PVP.lobby.buttons_initialized = false
		PVP.lobby.local_ready = false
		PVP.lobby.start_broadcasted = false
		if PVP.lobby.ready then
			PVP.lobby.ready:reset()
		end
	end
	mirror_metadata(lobby)
	mirror_players(lobby)

	local function refresh()
		if PVP.UI and PVP.UI.update_connection_status then
			pcall(PVP.UI.update_connection_status)
		end
		-- Rebuild the lobby view so roster/host/ready changes are reflected (e.g. the
		-- host's Start button appearing once the guest joins). No-op outside the menu.
		pcall(MPAPI.refresh_current_view)
	end

	lobby:on(MPAPI.LobbyEvent.CONNECTED, function()
		PVP.LOBBY.connected = true
		PVP.LOBBY.code = lobby.code
		mirror_players(lobby)
		refresh()
	end)

	lobby:on(MPAPI.LobbyEvent.PLAYER_JOINED, function(player_id)
		mirror_players(lobby)
		refresh()
	end)

	lobby:on(MPAPI.LobbyEvent.PLAYER_LEFT, function(player_id)
		if PVP.lobby and PVP.lobby.ready then
			PVP.lobby.ready:remove(player_id)
		end
		if PVP.lobby and PVP.lobby.seed_votes then
			PVP.lobby.seed_votes:remove(player_id)
		end
		mirror_players(lobby)
		-- The gamemode's forfeit hook (host-authoritative) handles a mid-match leave.
		local gm = lobby.get_gamemode_instance and lobby:get_gamemode_instance()
		if gm and gm.on_player_forfeit and G.STAGE == G.STAGES.RUN then
			MPAPI._handle_gamemode_result(gm, gm:on_player_forfeit(player_id))
		end
		refresh()
	end)

	-- Phase 9: reconnect tail-replay. PLAYER_RECONNECTED fires to every lobby
	-- member (including the reconnecting player's own client, once it
	-- re-subscribes to lobby/{code}/events) -- only act when the reconnecting
	-- player IS us; the opponent's own client needs no catch-up, it never
	-- disconnected. See pvp_api/reconnect_tail.lua.
	lobby:on(MPAPI.LobbyEvent.PLAYER_RECONNECTED, function(player_id)
		if player_id ~= lobby.player_id then return end
		if G.STAGE ~= G.STAGES.RUN then return end
		local opponent_id = PVP.get_opponent_id()
		if opponent_id then
			PVP.RECONNECT_TAIL.catch_up(opponent_id)
		end
	end)

	lobby:on(MPAPI.LobbyEvent.METADATA_CHANGED, function(metadata)
		mirror_metadata(lobby)
		MPAPI.refresh_current_view()
	end)

	lobby:on(MPAPI.LobbyEvent.HOST_CHANGED, function()
		mirror_players(lobby)
		MPAPI.refresh_current_view()
	end)

	lobby:on(MPAPI.LobbyEvent.DISCONNECTED, function()
		PVP.LOBBY.connected = false
		PVP.LOBBY.code = nil
		PVP.CURRENT_LOBBY = nil
		if PVP.lobby then
			PVP.lobby.ref = nil
			PVP.lobby.ui_ref = nil
			PVP.lobby.buttons_initialized = false
		end
		if PVP.stop_ready_resync then
			PVP.stop_ready_resync()
		end
		-- Drop the matchmaking handle for a matchmade lobby. Its match_id keeps it lingering
		-- in mm.handles until the server's MATCH_RESOLVED; leaving before that would otherwise
		-- leak the handle (stale MQTT subscription + confused re-queue). Idempotent.
		if PVP._match_handle then
			PVP._match_handle:leave()
			PVP._match_handle = nil
		end
		PVP._pvp_kind = nil
		refresh()
	end)

	lobby:on(MPAPI.LobbyEvent.ERROR, function(err)
		sendWarnMessage("Lobby error: " .. tostring(err), "MULTIPLAYER")
	end)
end
