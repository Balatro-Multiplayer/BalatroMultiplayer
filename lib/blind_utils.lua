local blind_states_to_skip = {
    ["Hidden"] = true,
    ["Defeated"] = true,
    ["Skipped"] = true
}
local blind_states_path = { "Small", "Big", "Boss" }

function MP.UTILS.get_blind_to_display(blind)
    if blind then return blind end
    if not G.GAME then return "bl_small" end
    local blind_to_display = "Small"
    for _, blind_type in ipairs(blind_states_path) do
        if G.GAME.round_resets.blind_states[blind_type] and not blind_states_to_skip[G.GAME.round_resets.blind_states[blind_type]] then
            blind_to_display = blind_type
            break
        end
    end
    return G.GAME.round_resets.blind_choices[blind_to_display] or "bl_small"
end