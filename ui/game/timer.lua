-- ease_round override moved to game/round.lua

function G.FUNCS.mp_timer_button(e)
	-- pressure_timer auto-ticks; manual button is meaningless under it.
	if MP.is_layer_active("pressure_timer") then return end
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
						func = "set_timer_box",
						button = "mp_timer_button",
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
                                                -- Less than 10 - display decimal part
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

local gradient_with_offset_update = function(self, dt)
    if #self.colours < 2 then return end
    local timer = (G.TIMERS.REAL-(self.mp_gradient_delay or 0))%self.cycle
    local start_index = math.ceil(timer*#self.colours/self.cycle)
    local end_index = start_index == #self.colours and 1 or start_index+1
    local start_colour, end_colour = self.colours[start_index], self.colours[end_index]
    local partial_timer = (timer%(self.cycle/#self.colours))*#self.colours/self.cycle
    for i = 1, 4 do
        if self.interpolation == 'linear' then
            self[i] = start_colour[i] + partial_timer*(end_colour[i]-start_colour[i])
        elseif self.interpolation == 'trig' then
            self[i] = start_colour[i] + 0.5*(1-math.cos(partial_timer*math.pi))*(end_colour[i]-start_colour[i])
        end
    end
end

SMODS.Gradient({
	key = "timer_accelerated",
    cycle = 1,
	colours = {
		mix_colours(G.C.WHITE, G.C.IMPORTANT, 0.55),
		G.C.IMPORTANT,
		G.C.IMPORTANT,
		G.C.IMPORTANT,
		G.C.IMPORTANT,
	},
    update = gradient_with_offset_update
})
SMODS.Gradient({
	key = "speedlatro_timer_accelerated",
    cycle = 1,
	colours = {
        G.C.WHITE,
		G.C.WHITE,
		G.C.WHITE,
		G.C.WHITE,
		mix_colours(G.C.IMPORTANT, G.C.WHITE, 0.55),
	},
    update = gradient_with_offset_update
})

function G.FUNCS.set_timer_box(e)
	if MP.LOBBY.config.timer then
		if MP.GAME.timer_started or MP.GAME.nemesis_timer_started then
			e.config.colour = G.C.DYN_UI.BOSS_DARK
			e.children[1].config.object.colours = { MP.GAME.timer > 0 and SMODS.Gradients["mp_timer_accelerated"] or G.C.IMPORTANT }
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
    gameUpdateRef(self, dt)

    -- If I let timer tick only when we're in MP context
    -- then big jump of dt will happend between state changes.
    -- So we need count time all the time. Sad!

    -- Again, we cannot rely on any variant of dt since game does not
    -- update at all while window is grabbed,
    -- and when you release it dt does not reflect time wasted

    -- This thing cost NOTHING im comparision to game drawing and UI updating
    -- We can afford some inefficiencies.
    local new_time = love.timer.getTime()
    local timer_dt = new_time - (MP.TIMER_CLOCK or new_time)
    MP.TIMER_CLOCK = new_time

    -- Bail fast: not an MP PvP-timer context
    if not MP.LOBBY.code then return end
    if not MP.LOBBY.config.timer then return end
    if MP.GAME.timer_consumed then return end
    if not MP.GAME.timer or MP.GAME.timer <= 0 then return end
    if MP.is_layer_active("speedlatro_timer") then return end

    -- Tick gating differs by layer:
    --   pressure_timer ON  -> tick during regular play (not ready_blind, not pvp boss)
    --   pressure_timer OFF -> vanilla semantics: tick only when player has started the timer
    if MP.is_layer_active("pressure_timer") then
        if MP.GAME.ready_blind or MP.is_pvp_boss() then return end
    else
        if not MP.GAME.timer_started then return end
    end

    -- Don't tick during animations, unless the user is paused or has a menu open
    local interactive = not (G.CONTROLLER.locked or (G.GAME.STOP_USE or 0) > 0)
    local menu_or_paused = G.SETTINGS.paused or G.OVERLAY_MENU
    if not (interactive or menu_or_paused) then return end

    local ruleset = MP.Rulesets[MP.LOBBY.config.ruleset]
    local speedup = (ruleset and ruleset.timer_speedup_multiplier) or 1
    local tick_mult = MP.GAME.nemesis_timer_started and speedup or 1
    MP.GAME.timer = math.max(0, MP.GAME.timer - timer_dt * tick_mult)

    if MP.GAME.timer == 0 then
        MP.GAME.timer_consumed = true
        if MP.GAME.timers_forgiven < MP.LOBBY.config.timer_forgiveness then
            MP.GAME.timers_forgiven = MP.GAME.timers_forgiven + 1
        else
            MP.ACTIONS.fail_timer()
        end
    end
end

function MP.UI.consume_timer(amount, silent, min_timer)
    if
        amount > 0
        and MP.LOBBY.config.timer
        and MP.GAME.timer
        and MP.GAME.timer > (min_timer or 0)
    then
        MP.GAME.timer = math.max(0, MP.GAME.timer - amount)
        if not silent then
            local timer_ui = G.HUD:get_UIE_by_ID("timer_UI_count")
            if timer_ui then
                timer_ui.config.object:juice_up()
            end
        end
    end
end