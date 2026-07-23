-- Pure decision logic for opponent disconnect/reconnect/leave events mid-run.
--
-- Why every departure routes through grace: the API's lobby event stream
-- cannot reliably distinguish a deliberate leave from an ungraceful network
-- drop. `player_left` fires both for an explicit `lobby:leave()` call AND
-- for a raw connection drop whose retained `players/<id>/info` topic clears
-- (LWT) -- which can arrive before, instead of, or without ever seeing a
-- `player_disconnected` event first (see BalatroMultiplayerAPI's
-- api/lobby/events.lua `handle_player_info`). There is no `reason` field on
-- the event to disambiguate. So rather than guess wrong and instant-win/lose
-- a match on a network blip, every mid-run opponent departure -- however it
-- is reported -- routes into the same pause/grace flow; only local grace
-- EXPIRY (there is no authoritative server anymore to send `stopGame`) turns
-- it into a forfeit. See the PR body for the full writeup of this tradeoff.

-- state: { in_run: bool, is_opponent: bool, grace_active: bool }
-- event: "player_disconnected" | "player_reconnected" | "player_left"
-- returns "ignore" | "start_grace" | "cancel_grace"
function MP.decide_departure_action(event, state)
	if not state or not state.is_opponent or not state.in_run then
		return "ignore"
	end
	if event == "player_reconnected" then
		if state.grace_active then
			return "cancel_grace"
		end
		return "ignore"
	end
	if event == "player_disconnected" or event == "player_left" then
		if state.grace_active then
			return "ignore" -- already paused; let grace expiry (or reconnect) resolve it
		end
		return "start_grace"
	end
	return "ignore"
end

-- Pure guard for the countdown tick in networking/action_handlers.lua: should
-- this tick resolve the grace period into a forfeit? Single-fire by
-- construction -- once `countdown.resolved` is true (or the countdown itself
-- has been cleared, e.g. by a reconnect), this always answers false.
function MP.disconnect_grace_expired(remaining, countdown)
	if not countdown or countdown.resolved then
		return false
	end
	return remaining <= 0
end
