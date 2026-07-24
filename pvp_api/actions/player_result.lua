-- §17.10: end-of-run roster -- every player's jokers, deck, and highest
-- PvP-blind score, not just the local player's own. Modeled directly on
-- SPDRN's own spdrn_player_result (built earlier this session, §16.10):
-- a one-shot broadcast every player sends once their own match involvement
-- ends, collected into a table keyed by SENDER id.
--
-- This replaces the existing get_end_game_jokers/get_nemesis_deck pair as
-- the roster's data source -- those are, despite their "pull" framing,
-- already full lobby broadcasts under the hood (pvp_api/net.lua's
-- get_end_game_jokers/receive_end_game_jokers), but the receiver writes into
-- a SINGLE scalar (PVP.end_game_jokers_payload) with no sender id at all, so
-- in any N>2 lobby whichever response lands last silently clobbers every
-- other player's data. Keying by sender id here avoids that outright, the
-- same fix already applied to SPDRN's Enemy Location Indicator (§16.11) and
-- PvP's own Enemy Location HUD (§17.11) this session. The old pair is left
-- in place for the existing single-nemesis toggle/deck-view UI.
PVP._collected_results = PVP._collected_results or {}

local function capture_local_jokers()
	local jokers = {}
	if G.jokers and G.jokers.cards then
		for _, card in ipairs(G.jokers.cards) do
			local center = card.config and card.config.center
			if center then
				jokers[#jokers + 1] = {
					key = center.key,
					edition = card.edition,
					eternal = card.ability and card.ability.eternal or false,
					perishable = card.ability and card.ability.perishable or false,
				}
			end
		end
	end
	return jokers
end

-- Called once, when this client's own match involvement ends (win or loss --
-- see action_win_game/action_lose_game in networking/action_handlers.lua).
--
-- Named report_ROSTER_result, not report_match_result -- pvp_api/queue.lua
-- ALREADY defines PVP.report_match_result(winner_id) (matchmaking placement/
-- ELO reporting, called from pvp_api/actions/outcomes.lua). A same-name
-- function here would silently clobber whichever one loads second, and
-- calling that OTHER function with no winner_id from here would also corrupt
-- every real matchmaking result -- confirmed live: this collision existed for
-- one commit before being caught by this session's own end-of-batch
-- verification pass and fixed immediately.
function PVP.report_roster_result()
	local lobby = MPAPI.get_current_lobby()
	if not lobby then
		return
	end
	local jokers = capture_local_jokers()
	local deck_back = PVP.LOBBY.deck and PVP.LOBBY.deck.back
	local highest_pvp_score = PVP.INSANE_INT.to_string(PVP.GAME.highest_pvp_score)

	PVP._collected_results[lobby.player_id] = {
		jokers = jokers,
		deck_back = deck_back,
		highest_pvp_score = highest_pvp_score,
	}
	lobby:action(MPAPI.ActionTypes["pvp_player_result"]):broadcast({
		jokers = jokers,
		deck_back = deck_back,
		highest_pvp_score = highest_pvp_score,
	})
end

MPAPI.ActionType({
	key = "pvp_player_result",
	prefix_config = { key = false },
	on_receive = function(_at, from_player_id, params)
		if not params then
			return
		end
		PVP._collected_results[from_player_id] = {
			jokers = params.jokers,
			deck_back = params.deck_back,
			highest_pvp_score = params.highest_pvp_score,
		}
		if PVP.UI.refresh_roster then
			PVP.UI.refresh_roster()
		end
	end,
})
