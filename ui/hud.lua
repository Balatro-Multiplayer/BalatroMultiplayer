function MP.UI.create_UIBox_player_row(player_id)
    local player_data
    if MP.LOBBY.players then
        for _, p in ipairs(MP.LOBBY.players) do
            if p.id == player_id then
                player_data = p
                break
            end
        end
    end
    local player_name = (player_data and player_data.name) or "???"

    local is_local = (player_id == G.SETTINGS.steam_id)
    local game_data_source
    if is_local then
        game_data_source = MP.GAME
    elseif MP.GAME.enemies and MP.GAME.enemies[player_id] then
        game_data_source = MP.GAME.enemies[player_id]
    end

    if not game_data_source then return nil end

    local lives = game_data_source.lives or MP.LOBBY.config.starting_lives
    local highest_score = game_data_source.highest_score or MP.INSANE_INT.empty()
    local hands = game_data_source.hands or 4

	return {
		n = G.UIT.R,
		config = {
			align = "cm", padding = 0.05, r = 0.1, colour = darken(G.C.JOKER_GREY, 0.1), emboss = 0.05,
		},
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cl", padding = 0, minw = 5 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", padding = 0.02, r = 0.1, colour = G.C.RED, minw = 2, outline = 0.8, outline_colour = G.C.RED },
						nodes = {
							{ n = G.UIT.T, config = { text = tostring(lives), scale = 0.4, colour = G.C.UI.TEXT_LIGHT } },
						},
					},
					{
						n = G.UIT.C,
						config = { align = "cm", minw = 4.5, maxw = 4.5 },
						nodes = {
							{ n = G.UIT.T, config = { text = " " .. player_name, scale = 0.45, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
						},
					},
				},
			},
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.05, colour = G.C.BLACK, r = 0.1 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cr", padding = 0.01, r = 0.1, colour = G.C.CHIPS, minw = 1.1 },
						nodes = {
							{ n = G.UIT.T, config = { text = tostring(hands), scale = 0.45, colour = G.C.UI.TEXT_LIGHT } },
						},
					},
				},
			},
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.05, colour = G.C.L_BLACK, r = 0.1, minw = 1.5 },
				nodes = {
					{ n = G.UIT.T, config = { text = MP.INSANE_INT.to_string(highest_score), scale = 0.45, colour = G.C.FILTER, shadow = true } },
				},
			},
		},
	}
end

function MP.UI.create_ingame_opponents_hud()
    local opponent_rows = {}
    if MP.GAME.enemies then
        for id, _ in pairs(MP.GAME.enemies) do
            local row = MP.UI.create_UIBox_player_row(id)
            if row then
                table.insert(opponent_rows, row)
                table.insert(opponent_rows, { n = G.UIT.B, config = { h = 0.1 } })
            end
        end
    end

    if #opponent_rows > 0 then
        if #opponent_rows > 1 then table.remove(opponent_rows) end -- Remove last spacer

        return UIBox({
            definition = {
                n = G.UIT.C,
                config = { align = "cm", padding = 0.1 },
                nodes = opponent_rows,
            },
            config = {
                align = "tr",
                bond = "Weak",
                offset = { x = -0.5, y = 1.5 },
                major = G.HUD,
            },
        })
    end
    return nil
end

local display_game_ui_ref = G.FUNCS.display_game_ui
function G.FUNCS.display_game_ui(...)
    display_game_ui_ref(...)
    if MP.LOBBY.code then
        if MP.ingame_hud then MP.ingame_hud:remove() end
        MP.ingame_hud = MP.UI.create_ingame_opponents_hud()
    end
end

local go_to_menu_ref = G.FUNCS.go_to_menu
function G.FUNCS.go_to_menu(...)
    if MP.ingame_hud then
        MP.ingame_hud:remove()
        MP.ingame_hud = nil
    end
    go_to_menu_ref(...)
end