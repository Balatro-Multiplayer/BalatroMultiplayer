-- ease_round override moved to game/round.lua

function G.FUNCS.mp_timer_button(e)
	if MP.LOBBY.config.timer then
		if MP.GAME.ready_blind then
			if MP.GAME.timer <= 0 then
				return
			elseif not MP.GAME.timer_started then
				MP.ACTIONS.start_ante_timer()
			else
				MP.ACTIONS.pause_ante_timer()
			end
		end
	end
end

function MP.UI.timer_hud()
	if MP.LOBBY.config.timer then
		return {
			n = G.UIT.C,
			config = {
				align = "cm",
				padding = 0.05,
				minw = 1.45,
				minh = 1,
				colour = G.C.DYN_UI.BOSS_MAIN,
				emboss = 0.05,
				r = 0.1,
			},
			nodes = {
				{
					n = G.UIT.R,
					config = { align = "cm", maxw = 1.35 },
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_timer"),
								minh = 0.33,
								scale = 0.34,
								colour = G.C.UI.TEXT_LIGHT,
								shadow = true,
							},
						},
					},
				},
				{
					n = G.UIT.R,
					config = {
						align = "cm",
						r = 0.1,
						minw = 1.2,
						colour = G.C.DYN_UI.BOSS_DARK,
						id = "row_round_text",
						-- func = "set_timer_box",
						-- button = "mp_timer_button",
					},
					nodes = {
						{
							n = G.UIT.O,
							config = {
								object = DynaText({
									string = MP.is_layer_active("speedlatro_timer") and ">>"
										or { { ref_table = setmetatable({}, {
                                            __index = function()
                                                if not MP.GAME.timer then return 0 end
                                                -- All numbers bigger then 10 - display as integer
                                                -- Also accounting for rounding to prevent 10.0 to be displayed
                                                if MP.GAME.timer > 9.95 then return string.format("%d", MP.GAME.timer) end
                                                -- Less than 10 - display decimap part
                                                return string.format("%.1f", MP.GAME.timer)
                                            end,
                                        }), ref_value = "timer" } }, -- sorry
									colours = { G.C.IMPORTANT },
									shadow = true,
									scale = 0.8,
								}),
								id = "timer_UI_count",
							},
						},
					},
				},
			},
		}
	end
end

function MP.UI.start_pvp_countdown(callback)
	local seconds = countdown_seconds
	local tick_delay = 1
	if MP.LOBBY and MP.LOBBY.config and MP.LOBBY.config.pvp_countdown_seconds then
		seconds = MP.LOBBY.config.pvp_countdown_seconds
	end
	MP.GAME.pvp_countdown = seconds

	G.CONTROLLER.locks.enter_pvp = true

	local function show_next()
		if MP.GAME.pvp_countdown <= 0 then
			if callback then callback() end
			G.E_MANAGER:add_event(Event({
				no_delete = true,
				trigger = "after",
				blocking = false,
				blockable = false,
				delay = 1,
				timer = "TOTAL",
				func = function()
					G.CONTROLLER.locks.enter_pvp = nil
					return true
				end,
			}))
			return true
		end

		G.FUNCS.attention_text_realtime({
			text = tostring(MP.GAME.pvp_countdown),
			scale = 5,
			hold = 0.85,
			align = "cm",
			major = G.play,
			backdrop_colour = G.C.MULT,
		})

		play_sound("tarot2", 1, 0.4)

		MP.GAME.pvp_countdown = MP.GAME.pvp_countdown - 1

		G.E_MANAGER:add_event(Event({
			trigger = "after",
			timer = "REAL",
			delay = tick_delay,
			blockable = false,
			func = show_next,
		}))
		return true
	end

	G.E_MANAGER:add_event(Event({
		trigger = "after",
		timer = "REAL",
		delay = 0,
		blockable = false,
		func = show_next,
	}))
end

function G.FUNCS.set_timer_box(e)
	if MP.LOBBY.config.timer then
		if MP.GAME.timer_started then
			e.config.colour = G.C.DYN_UI.BOSS_DARK
			e.children[1].config.object.colours = { G.C.IMPORTANT }
			return
		end
		if not MP.GAME.timer_started and MP.GAME.ready_blind then
			e.config.colour = G.C.IMPORTANT
			e.children[1].config.object.colours = { G.C.UI.TEXT_LIGHT }
			return
		end
		e.config.colour = G.C.DYN_UI.BOSS_DARK
		e.children[1].config.object.colours = { G.C.IMPORTANT }
	end
end

local gameUpdateRef = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
    if MP.LOBBY.code and MP.GAME and not MP.GAME.timer_consumed and MP.GAME.timer and MP.GAME.timer > 0 then
        -- Do not tick when no pvp or we're ready
        if not MP.GAME.ready_blind and not MP.is_pvp_boss() then
            -- Do tick when user can interact with a game
            -- OR
            -- Do tick when game is paused or any overlay menu opened
            if not (G.CONTROLLER.locked or (G.GAME.STOP_USE or 0) > 0) or (G.SETTINGS.paused or G.OVERLAY_MENU) then
                MP.GAME.timer = MP.GAME.timer - G.real_dt
                if MP.GAME.timer <= 0 then
                    MP.GAME.timer = 0
                    MP.GAME.timer_consumed = true
                    if not MP.GAME.ready_blind and not MP.is_pvp_boss() then
                        if MP.GAME.timers_forgiven < MP.LOBBY.config.timer_forgiveness then
                            MP.GAME.timers_forgiven = MP.GAME.timers_forgiven + 1
                        else
                            MP.ACTIONS.fail_timer()
                        end
                    end
                end
            end
        end
    end
	gameUpdateRef(self, dt)
end