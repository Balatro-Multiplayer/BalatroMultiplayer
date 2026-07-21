SMODS.Atlas({
	key = "player_blind_chip",
	path = "player_blind_row.png",
	atlas_table = "ANIMATION_ATLAS",
	frames = 21,
	px = 34,
	py = 34,
})

SMODS.Atlas({
	key = "player_blind_col",
	path = "blind_col.png",
	atlas_table = "ANIMATION_ATLAS",
	frames = 21,
	px = 34,
	py = 34,
})

MPAPI.Blind({
	key = "nemesis",
	dollars = 5,
	mult = 1, -- Jen's Almanac crashes the game if the mult is 0
	boss_colour = G.C.MULTIPLAYER,
	boss = { min = 1, max = 10 },
	atlas = "player_blind_chip",
	discovered = true,
	in_pool = function(self)
		return false
	end,

	-- Decides whether/what to tell the opponent on a hand played or discard, dispatched via
	-- MPAPI.calculate_blind from pvp_api/net.lua's playHand/skip routes -- the blind's own
	-- decision now, not an external hardcoded sync call.
	calculate = function(self, context)
		if context.hand_played or context.discarded then
			return {
				send = { score = context.score, handsLeft = context.hands_left, skips = context.skips, lives = context.lives },
			}
		end
	end,

	-- Display-only sync of the opponent's score/hands/skips/lives (was action_enemy_info).
	-- Runs on the OTHER player's client (self-echo suppressed by the framework); writes the
	-- PVP.GAME.enemy.* store the HUD already reads. The referee (win/lose/lives) is separate,
	-- still driven by pvp_play_hand/pvp_skip.
	receive = function(self, context)
		PVP.note_target_candidate(context.from)
		if PVP.current_target_id() and context.from ~= PVP.current_target_id() then
			return
		end
		local d = context.data
		local score = PVP.INSANE_INT.from_string(d.score)
		local hands_left = tonumber(d.handsLeft)
		local skips = tonumber(d.skips)
		local lives = tonumber(d.lives)

		-- No-animation timer: opponent skip adds time immediately.
		if skips and PVP.GAME.enemy.skips ~= skips then
			for _ = 1, skips - PVP.GAME.enemy.skips do
				PVP.GAME.enemy.spent_in_shop[#PVP.GAME.enemy.spent_in_shop + 1] = 0
				if
					PVP.GAME.enemy.skips < skips
					and PVP.LOBBY.config.timer
					and not PVP.GAME.timer_started
					and not PVP.GAME.nemesis_timer_started
					and not PVP.GAME.timer_consumed
					and PVP.is_any_layer_active({ "no_animation_timer", "pressure_timer" })
					and (PVP.LOBBY.config.timer_increment_seconds or 0) > 0
				then
					PVP.UI.restore_timer(PVP.LOBBY.config.timer_increment_seconds)
				end
			end
		end

		if score == nil or hands_left == nil then
			sendDebugMessage("Invalid score or hands_left", "MULTIPLAYER")
			return
		end

		if PVP.INSANE_INT.greater_than(score, PVP.GAME.enemy.highest_score) then PVP.GAME.enemy.highest_score = score end

		-- PvP timer: stop timer according to score.
		if PVP.is_pvp_boss() and PVP.is_layer_active("pvp_timer") then
			if PVP.INSANE_INT.greater_than(PVP.GAME.score, score) then
				PVP.GAME.nemesis_timer_started = false
			elseif PVP.INSANE_INT.equal(PVP.GAME.score, score) and PVP.GAME.pvp_reached_first then
				PVP.GAME.nemesis_timer_started = false
			else
				PVP.GAME.timer_started = false
			end
		end

		G.E_MANAGER:add_event(Event({
			blockable = false,
			blocking = false,
			trigger = "ease",
			delay = 3,
			ref_table = PVP.GAME.enemy.score,
			ref_value = "e_count",
			ease_to = score.e_count,
			func = function(t)
				return math.floor(t)
			end,
		}))
		G.E_MANAGER:add_event(Event({
			blockable = false,
			blocking = false,
			trigger = "ease",
			delay = 3,
			ref_table = PVP.GAME.enemy.score,
			ref_value = "coeffiocient", -- misspelled in InsaneInt
			ease_to = score.coeffiocient,
			func = function(t)
				local mult = 1
				if score.exponent > 0 then mult = 100 end
				return math.floor(t * mult) / mult
			end,
		}))
		G.E_MANAGER:add_event(Event({
			blockable = false,
			blocking = false,
			trigger = "ease",
			delay = 3,
			ref_table = PVP.GAME.enemy.score,
			ref_value = "exponent",
			ease_to = score.exponent,
			func = function(t)
				return math.floor(t)
			end,
		}))

		if PVP.GAME.enemy.lives > lives then
			play_sound("holo1", 0.865, 0.9)
			play_sound("gong", 0.765, 0.4)
		end
		if PVP.GAME.enemy.skips < skips then
			play_sound("negative", 0.865, 0.4)
			play_sound("gong", 0.765, 0.4)
		end

		PVP.GAME.enemy.real_score = score
		PVP.GAME.enemy.hands = hands_left
		PVP.GAME.enemy.skips = skips
		PVP.GAME.enemy.lives = lives
		-- We've now heard from the opponent this blind: unmask their hands count.
		PVP.GAME.enemy.info_received = true
		if PVP.UI.juice_up_pvp_hud then PVP.UI.juice_up_pvp_hud() end
	end,
})

function PVP.is_pvp_boss()
	if not G.GAME or not G.GAME.blind or not G.GAME.blind.config.blind then return false end
	return G.GAME.blind.config.blind.key == "bl_mp_nemesis" or G.GAME.blind.pvp
end
