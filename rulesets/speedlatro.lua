MP.Ruleset({
	key = "speedlatro",
	multiplayer_content = true,
	standard = true,
	banned_silent = {
		"j_hanging_chad",
		"j_ticket",
		"j_selzer",
		"j_turtle_bean",
		"j_bloodstone",
		"c_ouija",
	},
	banned_jokers = {},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	reworked_jokers = {
		"j_mp_hanging_chad",
		"j_mp_ticket",
		"j_mp_seltzer",
		"j_mp_turtle_bean",
	},
	reworked_consumables = {
		"c_mp_ouija_standard",
	},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_mp_display_glass",
	},
	reworked_tags = {},
	reworked_blinds = {},
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = false,
			forced_gamemode_text = "k_attrition",
			description_key = "k_speedlatro_description",
		})
	end,
	forced_gamemode = "gamemode_mp_attrition",
}):inject()

-- speedlatro specific timer
-- i can't be bothered to do run_start hooks and risk that being janky so it'll be initialized in gupdate

local base_timer = 147

local gupdate = Game.update
function Game:update(dt)
	if MP.is_ruleset_active("speedlatro") and G.STAGE == G.STAGES.RUN then
		if not MP.speedlatro_timer then
			MP.speedlatro_timer = {real = base_timer, display = base_timer}
			MP.speedlatro_timer.text = UIBox{
				definition = {n=G.UIT.ROOT, config = {align = 'cm', colour = G.C.CLEAR, padding = 0.2}, nodes={
					{n=G.UIT.R, config = {align = 'cm', maxw = 1}, nodes={
						{n=G.UIT.O, config={object = DynaText({scale = 1.1, string = {{ref_table = MP.speedlatro_timer, ref_value = "display"}}, maxw = 18, colours = {G.C.WHITE},float = true, shadow = true, silent = true, pop_in = 0, pop_in_rate = 6})}},
					}}
				}}, 
				config = {
					align = 'cm',
					offset ={x=0.3,y=-2.9},
					major = G.deck,
				}
			}
		end
		-- holy fucking conditional
		if not (G.STATE == G.STATES.HAND_PLAYED 
		and G.GAME.current_round.hands_left < 1 
		and G.STATE_COMPLETE 
		and MP.LOBBY.connected 
		and MP.LOBBY.code 
		and MP.is_pvp_boss()) then
			if not (G.CONTROLLER.locks.enter_pvp or MP.GAME.ready_blind) then
				local mult = 1
				if MP.GAME.timer_started and not MP.is_pvp_boss() then
					mult = 2
				end
				MP.speedlatro_timer.real = MP.speedlatro_timer.real - dt*mult
			end
		end
		if MP.speedlatro_timer.real <= 0 then
			MP.speedlatro_timer.real = 0
			-- weird logic flow
			if MP.LOBBY.code then
				if not MP.speedlatro_timer.failed then
					MP.ACTIONS.fail_timer()
					MP.speedlatro_timer.failed = true
				end
			elseif G.STATE ~= G.STATES.GAME_OVER then
				G.STATE = G.STATES.GAME_OVER
				G.STATE_COMPLETE = false
			end
		end

		-- fun
		MP.GAME.timer = 999

		local suffix = string.sub(math.floor((MP.speedlatro_timer.real+100)*100), -2)
		MP.speedlatro_timer.display = math.floor(MP.speedlatro_timer.real).."."..suffix

	elseif MP.speedlatro_timer then
		MP.speedlatro_timer.text:remove()
		MP.speedlatro_timer = nil
	end
	return gupdate(self, dt)
end

-- not perfect but whatever this mode is janky anyways

local new_round_ref = new_round
function new_round()
	if MP.is_ruleset_active("speedlatro") then
		if MP.LOBBY.code then
			if G.GAME.round_resets.blind == G.P_BLINDS["bl_mp_nemesis"] then
				MP.speedlatro_timer.real = base_timer/2
				MP.speedlatro_timer.failed = false
			end
		elseif G.GAME.round_resets.blind ~= G.P_BLINDS["bl_small"]
		and G.GAME.round_resets.blind ~= G.P_BLINDS["bl_big"] then
			MP.speedlatro_timer.real = base_timer/2
		end
	end
	return new_round_ref()
end

local end_round_ref = end_round
function end_round()
	if MP.is_ruleset_active("speedlatro") then
		if MP.LOBBY.code then
			if MP.is_pvp_boss() then
				MP.speedlatro_timer.real = base_timer
				MP.speedlatro_timer.failed = false
			end
		elseif G.GAME.blind:get_type() == "Boss" then
			MP.speedlatro_timer.real = base_timer
		end
	end
	return end_round_ref()
end