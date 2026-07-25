-- §22.3 (Phase 4): live spectate feed adapter. Turns a spectator token
-- (MPAPI.replay.spectate_lobby) into a running MPAPI.playback driver whose
-- timeline is fed incrementally from the live match instead of a finished
-- carbon log -- the same driver/registry/handler code Phase 2/3 already
-- built and tested for post-hoc replay, just with a different event source.
--
-- Deliberately NOT built on the normal participant pipeline
-- (MPAPI._internal.handle_action / lobby:action(...):broadcast, wired up by
-- api/lobby/subscriptions.lua for a real lobby member). That pipeline
-- dispatches EVERY registered ActionType matching a message on the topic --
-- pvp_play_hand, pvp_skip, mpapi_sync, mpapi_opponent_context, etc. -- all of
-- which assume they're running on a live PARTICIPANT's own client, mutating
-- that client's own G.GAME/PVP.GAME/PVP.REF. A spectator has no stake in the
-- match (may not even have an active run at all), so those handlers firing
-- against unrelated/nonexistent local state would corrupt it at best, crash
-- at worst. Instead this opens a SECOND, read-only MQTT connection (per
-- networking/api_client/replay.lua's own doc comment: "the caller reconnects
-- or connects a second MQTT client using this token as the CONNECT
-- password") and hand-decodes only the one action type a passive observer
-- actually needs: pvp_log_event (lib/replay_log.lua/pvp_api/replay_log_actions.lua),
-- ignoring every other action on the same topic entirely.
--
-- §22.3 full-fidelity update: S.start now bootstraps its own seeded local
-- run via PVP._start_playback (lib/playback_launch.lua), using the manifest
-- fields the server's getSpectatorSnapshot extracts from the match's own
-- buffered manifest event (BalatroMultiplayerServer's replay-log.service.ts)
-- -- the same seed/deck/stake/ruleset a post-hoc replay uses, so a spectator
-- sees the real, deterministic cards too, not just score/ante text. Known
-- gap, not solved here: this only gives full fidelity for a spectator who
-- joins from the very start of a match -- one joining mid-match has no way
-- to replay the ALREADY-MISSED actions (only the aggregated latest ante/
-- score the snapshot carries), so their local run starts at ante 1/blind-
-- select while the live feed's next real event may be from a much later
-- point -- the display baseline (_apply_snapshot) still shows the right
-- ballpark score/ante, but the actual cards on screen won't reflect a mid-
-- match join. Same class of gap as the already-flagged missing `lives` field.
PVP.SPECTATE = PVP.SPECTATE or {}
local S = PVP.SPECTATE
S._mqtt = nil
S._driver = nil

local function self_player_id()
	local conn = MPAPI.get_connection()
	return conn and conn.player_id
end

-- Pure decode step, kept separate from the live MQTT wiring below so it's
-- directly testable with synthetic payloads (no real broker needed). Returns
-- a driver-ready {t, player_id, opcode, args} entry for a pvp_log_event
-- action, or nil for anything else on the topic (every other real action
-- type -- see file header for why those must never reach a spectator).
function S.decode_action_event(topic, payload)
	local ok, data = pcall(MPAPI.json_decode, payload)
	if not ok or not data or data.action ~= 'pvp_log_event' then
		return nil
	end
	local from = topic:match('players/([^/]+)/actions$')
	if not from then
		return nil
	end
	local params = data.params or {}
	return { t = params.t, player_id = from, opcode = params.opcode, args = params.args }
end

local function on_actions_message(topic, payload)
	if not S._driver then
		return
	end
	local entry = S.decode_action_event(topic, payload)
	if entry then
		S._driver:push_event(entry)
	end
end

-- Applies the one-time join snapshot (MPAPI.replay.spectate_lobby's own
-- {token, snapshot} response) as a baseline, through the SAME registered
-- handlers Phase 3 already tests (set_ante_key/hand_result) rather than
-- duplicating their projection logic here. The first player id in the
-- snapshot is picked as the nominal POV (drives PVP.GAME, the "own board"
-- side) -- a spectator has no real self in the match, this is a display
-- choice, not an identity claim. Known gap (flagged in the approved plan,
-- not solved here): the snapshot has no `lives` field, since the server's
-- getSpectatorSnapshot only derives ante/score/handsRemaining from buffered
-- carbon events -- live lives changes flow through pvp_player_lives, a
-- separate broadcast this file doesn't touch yet.
-- Exposed as a module field (not a local), same reasoning as
-- MPAPI.playback._queues_empty -- so a test can call it directly with a
-- synthetic snapshot, without needing a real spectate_lobby round trip.
function S._apply_snapshot(snapshot)
	local pov_player_id = snapshot[1] and snapshot[1].playerId
	for _, entry in ipairs(snapshot) do
		local ctx = { is_pov = entry.playerId == pov_player_id, player_id = entry.playerId }
		if entry.ante then
			MPAPI.playback.dispatch('pvp', 'set_ante_key', entry.ante, ctx)
		end
		if entry.score or entry.handsRemaining then
			MPAPI.playback.dispatch('pvp', 'hand_result', { entry.score, entry.handsRemaining }, ctx)
		end
	end
	return pov_player_id
end

-- Starts spectating `code`. on_ready(err) reports whether the feed connected
-- (nil err = success); once it does, the driver is playing and PVP.GAME/
-- enemy already reflect the join-time snapshot, updating live as further
-- pvp_log_event broadcasts arrive. Bootstraps its own seeded local run first
-- (see file header) -- this can take a moment (a real run start), unlike
-- Phase 4's original version which assumed a run already existed.
function S.start(code, on_ready)
	MPAPI.replay.spectate_lobby(code, function(err, data)
		if err or not data or not data.token then
			if on_ready then
				on_ready((err and err.message) or 'spectate_lobby failed')
			end
			return
		end

		local snapshot = data.snapshot or {}
		local manifest = snapshot[1] and snapshot[1].manifest
		if not manifest then
			if on_ready then
				on_ready('spectate: no manifest available yet for this lobby (no buffered run)')
			end
			return
		end

		PVP._start_playback(manifest, function()
			local pov_player_id = S._apply_snapshot(snapshot)
			S._driver = MPAPI.playback.new_driver({}, { mod_id = 'pvp', pov_player_id = pov_player_id })
			S._driver:play()

			local conn = MPAPI.get_connection()
			local mqtt = MPAPI.networking.mqtt_client.new({
				broker = conn.config.mqtt_broker,
				port = conn.config.mqtt_port,
				secure = conn.config.mqtt_secure,
				username = self_player_id(),
				password = data.token,
			})
			S._mqtt = mqtt

			mqtt.on_connect = function()
				mqtt:subscribe(mqtt:lobby_topic(code, 'players/+/actions'), 1, on_actions_message)
				if on_ready then
					on_ready(nil)
				end
			end
			mqtt.on_error = function(msg)
				if on_ready then
					on_ready(tostring(msg))
				end
			end

			mqtt:connect()
		end)
	end)
end

function S.stop()
	if S._driver then
		S._driver:stop()
		S._driver = nil
	end
	if S._mqtt then
		S._mqtt:disconnect()
		S._mqtt = nil
	end
end

function S.is_active()
	return S._mqtt ~= nil
end

-- Drives the spectator's second MQTT client every frame. Game:update is
-- already wrapped once by BalatroMultiplayerAPI/api/playback/driver.lua (MPAPI
-- loads first) -- this wraps that same reference again, the same
-- capture-and-call-through pattern used throughout this codebase (e.g.
-- api/gamemode/hooks.lua's reset_blinds/ease_ante wraps).
local _game_update_ref = Game.update
function Game:update(dt)
	_game_update_ref(self, dt)
	if S._mqtt then
		S._mqtt:update()
	end
end
