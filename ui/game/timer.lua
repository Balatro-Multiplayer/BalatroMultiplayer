-- ease_round override moved to game/round.lua

function MP.UI.cam_timer_opponent()
	if not MP.LOBBY.config.timer then return false end
    if MP.GAME.pvp_countdown_in_progress then return false end
    if MP.GAME.timer <= 0 then return false end
	if MP.is_pvp_boss() and MP.is_layer_active("pvp_timer") then
		if G.STATE == G.STATES.ROUND_EVAL or G.STATE == G.STATES.NEW_ROUND then return false end
		if MP.INSANE_INT.greater_than(MP.GAME.score, MP.GAME.enemy.score) then return true end
        if MP.INSANE_INT.equal(MP.GAME.score, MP.GAME.enemy.score) then return MP.GAME.pvp_reached_first end
		return false
	end
	return MP.GAME.ready_blind
end

function G.FUNCS.mp_timer_button(e)
	-- Under pressure_timer the local timer auto-ticks regardless of timer_started,
	-- but the button still needs to fire — pressing it broadcasts startAnteTimer,
	-- which is what flips the opponent's nemesis_timer_started and triggers 2x.
	if MP.UI.cam_timer_opponent() then
		if MP.GAME.timer <= 0 then
			return
		elseif not MP.GAME.timer_started then
			MP.ACTIONS.start_ante_timer()
		else
			MP.ACTIONS.pause_ante_timer()
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
									string = MP.is_layer_active("speedlatro_timer") and ">>" or {
										{
											ref_table = setmetatable({}, {
												__index = function()
													if not MP.GAME.timer then return 0 end
													-- All numbers bigger then 10 - display as integer
													-- Also accounting for rounding to prevent 10.0 to be displayed
													if MP.GAME.timer > 9.95 then
														return string.format("%d", MP.GAME.timer)
													end
													-- Less than 10 - display decimal part
													return string.format("%.1f", MP.GAME.timer)
												end,
											}),
											ref_value = "timer",
										},
									}, -- sorry
									colours = { G.C.UI.TEXT_DARK },
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
    MP.GAME.pvp_countdown_in_progress = true
	MP.GAME.pvp_countdown = seconds

	G.CONTROLLER.locks.enter_pvp = true

	local function show_next()
		if MP.GAME.pvp_countdown <= 0 then
			if callback then callback() end
            G.E_MANAGER:add_event(Event({
                blocking = false,
                func = function()
                    G.E_MANAGER:add_event(Event({
                        blocking = false,
                        func = function()
                            MP.GAME.pvp_countdown_in_progress = nil
                            return true
                        end,
                    }))
                    return true
                end,
            }))
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
	update = function(self, dt)
		if #self.colours < 2 or not MP.LOBBY.config.ruleset then return end
		local speedup = MP.GAME.timer_started and 1 or MP.current_ruleset().timer_speedup_multiplier or 1

		-- When you "timering" opponent, timer stops and you cannot see is button pressed
		-- So we need switch to real timer to make it flush
		local time_value = MP.GAME.timer_started and G.TIMERS.REAL or -(MP.GAME.timer or 0)
		local timer = (time_value / speedup) % self.cycle
		local start_index = math.ceil(timer * #self.colours / self.cycle)
		if start_index == 0 then start_index = 1 end
		local end_index = start_index == #self.colours and 1 or start_index + 1
		local start_colour, end_colour = self.colours[start_index], self.colours[end_index]
		local partial_timer = (timer % (self.cycle / #self.colours)) * #self.colours / self.cycle
		for i = 1, 4 do
			if self.interpolation == "linear" then
				self[i] = start_colour[i] + partial_timer * (end_colour[i] - start_colour[i])
			elseif self.interpolation == "trig" then
				self[i] = start_colour[i]
					+ 0.5 * (1 - math.cos(partial_timer * math.pi)) * (end_colour[i] - start_colour[i])
			end
		end
	end,
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
	update = function(self, dt)
		if #self.colours < 2 or not MP.speedlatro_timer then return end
		local speedup = MP.current_ruleset().timer_speedup_multiplier or 1

        local timer_value = MP.GAME.ready_blind and 0 or -(MP.speedlatro_timer.real or 0)
		local timer = (timer_value / speedup) % self.cycle
		local start_index = math.ceil(timer * #self.colours / self.cycle)
		if start_index == 0 then start_index = 1 end
		local end_index = start_index == #self.colours and 1 or start_index + 1
		local start_colour, end_colour = self.colours[start_index], self.colours[end_index]
		local partial_timer = (timer % (self.cycle / #self.colours)) * #self.colours / self.cycle
		for i = 1, 4 do
			if self.interpolation == "linear" then
				self[i] = start_colour[i] + partial_timer * (end_colour[i] - start_colour[i])
			elseif self.interpolation == "trig" then
				self[i] = start_colour[i]
					+ 0.5 * (1 - math.cos(partial_timer * math.pi)) * (end_colour[i] - start_colour[i])
			end
		end
	end,
})

function G.FUNCS.set_timer_box(e)
	if MP.LOBBY.config.timer then
		if MP.GAME.timer_started or MP.GAME.nemesis_timer_started then
			e.config.colour = G.C.DYN_UI.BOSS_DARK
			-- Pulse because why not
			e.children[1].config.object.colours = {
				MP.GAME.timer > 0 and SMODS.Gradients["mp_timer_accelerated"] or G.C.IMPORTANT,
			}
			return
		end
		if not MP.GAME.timer_started and MP.UI.cam_timer_opponent() then
			e.config.colour = G.C.IMPORTANT
			e.children[1].config.object.colours = { G.C.UI.TEXT_LIGHT }
			return
		end
		e.config.colour = G.C.DYN_UI.BOSS_DARK
		e.children[1].config.object.colours =
			{
                (not MP.is_pvp_boss() and not MP.GAME.pvp_countdown_in_progress and MP.is_layer_active("pressure_timer"))
                and G.C.IMPORTANT or G.C.UI.TEXT_DARK
            }
	end
end

local animation_budget_capacity = 40
local animation_budget_restore_rate = 2.5
local animation_budget_decay_rate = 0

MP.TIMER_ANIMATION_BUDGET = animation_budget_capacity

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

	-- Remove gamespeed force setted up for previous frame
	MP.TIMER_FORCE_GAMESPEED = false

	-- Restore animation budget (used to prevent skipping too much time by animations)
	MP.TIMER_ANIMATION_BUDGET =
		math.min(animation_budget_capacity, MP.TIMER_ANIMATION_BUDGET + timer_dt * animation_budget_restore_rate)

	-- Bail fast: not an MP PvP-timer context
	if G.STATE == G.STATES.GAME_OVER then return end
	if not MP.LOBBY.code then return end
	if not MP.LOBBY.config.timer then return end
	if MP.GAME.timer_consumed then return end
	if not MP.GAME.timer or MP.GAME.timer <= 0 then return end
	if MP.is_layer_active("speedlatro_timer") then return end

	local is_no_animation_timer = MP.is_layer_active("no_animation_timer")
	local is_pressure_timer = MP.is_layer_active("pressure_timer")
	local is_pvp_boss = MP.is_pvp_boss()
	local is_pvp_timer = MP.is_layer_active("pvp_timer") and is_pvp_boss

	-- Tick gating differs by layer:
	--   pressure_timer ON  -> tick during regular play (not ready_blind, not pvp boss)
	--   pressure_timer OFF -> tick whenever someone pressed a timer button.
	--     timer_started = YOU pressed it; nemesis_timer_started = OPPONENT pressed it
	--     (i.e. they're timering you). Either way your local timer should tick.
	local should_check_animations = false

	if is_pvp_timer then
        -- PvP timer: tick when opponent timering, stop when animations, state checks, pvp blind only
		if not MP.GAME.nemesis_timer_started then return end
        if G.GAME.current_round.hands_left <= 0 then return end
		if G.STATE == G.STATES.NEW_ROUND or G.STATE == G.STATES.ROUND_EVAL then return end
		should_check_animations = true
	elseif is_pressure_timer then
        -- Pressure timer: tick from the start of a game, stop when reached pvp (unless timered) or animations, not in pvp blind
		if MP.GAME.pvp_reached and not MP.GAME.nemesis_timer_started then return end
		if MP.GAME.ready_blind or is_pvp_boss then return end
		should_check_animations = true
	elseif is_no_animation_timer then
        -- No-animation timer: tick when opponen timering, stop when animations, not in pvp
		if not MP.GAME.nemesis_timer_started then return end
		if MP.GAME.ready_blind or is_pvp_boss then return end
		should_check_animations = true
	else
        -- Old timer: tick when opponent timering, not in pvp
        if is_pvp_boss then return end
		if not (MP.GAME.timer_started or MP.GAME.nemesis_timer_started) then return end
	end

	if should_check_animations then
		MP.TIMER_FORCE_GAMESPEED = true

		-- Don't tick during animations, unless the user is paused or has a menu open
		local interactive = not ((G.CONTROLLER.locked and not G.CONTROLLER.locks.frame) or (G.GAME.STOP_USE or 0) > 0)
		local menu_or_paused = G.SETTINGS.paused or G.OVERLAY_MENU

		-- Consume animations time from budget
		if not (interactive or menu_or_paused) then
			MP.TIMER_ANIMATION_BUDGET = math.max(
				0,
				MP.TIMER_ANIMATION_BUDGET - timer_dt * (animation_budget_restore_rate + animation_budget_decay_rate)
			)
			if MP.TIMER_ANIMATION_BUDGET > 0 then return end
		end
	end

	local speedup = is_pvp_timer and 1 or MP.current_ruleset().timer_speedup_multiplier or 1
	local tick_mult = MP.GAME.nemesis_timer_started and speedup or 1
	MP.GAME.timer = math.max(0, MP.GAME.timer - timer_dt * tick_mult)

	if MP.GAME.timer == 0 then
		MP.GAME.timer_consumed = true
        -- PvP timer: end PvP immediately as a loss (only when timered by opponent)
        if is_pvp_timer then
            if MP.GAME.nemesis_timer_started then
                MP.ACTIONS.fail_pvp_timer()
            end
        -- Old, No-animations: lose a live when timered by opponent
        -- Pressure timers: lose a live regardless
        elseif (is_pressure_timer or MP.GAME.nemesis_timer_started) then
            if MP.GAME.timers_forgiven < MP.LOBBY.config.timer_forgiveness then
                MP.GAME.timers_forgiven = MP.GAME.timers_forgiven + 1
            else
                MP.ACTIONS.fail_timer()
            end
        end
	end
end

function MP.UI.consume_timer(amount, silent, min_timer)
	if amount > 0 and MP.LOBBY.config.timer and MP.GAME.timer and MP.GAME.timer > (min_timer or 0) then
		MP.GAME.timer = math.max(0, MP.GAME.timer - amount)
		if not silent then
			local timer_ui = G.HUD:get_UIE_by_ID("timer_UI_count")
			if timer_ui then timer_ui.config.object:juice_up() end
		end
	end
end

function MP.UI.restore_timer(amount, silent, max_timer)
	if amount > 0 and MP.LOBBY.config.timer and MP.GAME.timer and (not max_timer or MP.GAME.timer < max_timer) then
		MP.GAME.timer = math.max(0, MP.GAME.timer + amount)
		if not silent then
			local timer_ui = G.HUD:get_UIE_by_ID("timer_UI_count")
			if timer_ui then timer_ui.config.object:juice_up() end
		end
	end
end

local old_play = G.FUNCS.play_cards_from_highlighted
function G.FUNCS.play_cards_from_highlighted(...)
    old_play(...)
    if G.play and G.play.cards[1] then return end
    if MP.LOBBY.code and MP.LOBBY.config.timer and not MP.GAME.timer_consumed then
        if MP.is_pvp_boss() then
            -- PvP timer: Increment timer when hand is played during pvp
            if MP.is_layer_active("pvp_timer") then
                local increment = MP.LOBBY.config.pvp_timer_hand_played_increment_seconds or MP.current_ruleset().pvp_timer_hand_played_increment_seconds or 0
                MP.UI.restore_timer(increment)
            end
        else
            -- No-animation, Pressure timers: Increment timer when hand is played during regular blinds
            if MP.is_any_layer_active({ "no_animation_timer", "pressure_timer" }) then
                local increment = MP.LOBBY.config.timer_hand_played_increment_seconds or MP.current_ruleset().timer_hand_played_increment_seconds or 0
                MP.UI.restore_timer(increment)
            end
        end
    end
end