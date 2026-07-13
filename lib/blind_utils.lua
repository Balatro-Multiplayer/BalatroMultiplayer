local blind_states_to_skip = {
	["Hidden"] = true,
	["Defeated"] = true,
	["Skipped"] = true,
}
local blind_states_path = { "Small", "Big", "Boss" }

function MP.UTILS.get_blind_to_display(blind)
	if blind then return blind end
	if not G.GAME then return "bl_small" end
	local blind_to_display = "Small"
	for _, blind_type in ipairs(blind_states_path) do
		if
			G.GAME.round_resets.blind_states[blind_type]
			and not blind_states_to_skip[G.GAME.round_resets.blind_states[blind_type]]
		then
			blind_to_display = blind_type
			break
		end
	end
	return G.GAME.round_resets.blind_choices[blind_to_display] or "bl_small"
end

-- Pure "what should the opponent's hands display reset to at blind start"
-- decision. Called from action_start_blind alongside the existing enemy.score
-- / info_received resets so the HUD never carries a stale count (or the
-- hardcoded initial default) into the new blind before the first real sync.
--
-- Returns a numeric `hands` (not nil): Conjoined Joker's per-frame update
-- does arithmetic on MP.GAME.enemy.hands (`hands * x_mult_gain`) any time
-- MP.LOBBY.code is set, not just during a PvP blind, so a nil here would
-- crash that joker's update loop between blinds/in the shop.
function MP.UTILS.enemy_hands_reset()
	return { hands = 0, hands_text = "?" }
end

-- Pure decision for what text the opponent's hands-left counter should show
-- this frame. Unlike the score mask (gated behind hide_score_until_played,
-- an opt-in "don't let me see the score before I've played" feature), this
-- has no "reveal anyway" mode: until `info_received` is true for the current
-- blind, `hands` is either last blind's leftover value or the reset
-- placeholder -- never correct -- so it's always worth hiding.
function MP.UTILS.enemy_hands_text(hands, info_received, is_pvp_boss)
	if is_pvp_boss and not info_received then return "?" end
	return tostring(hands)
end
