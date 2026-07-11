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

	-- Display-only sync of the opponent's score/hands/skips/lives (was action_enemy_info).
	-- Runs on the OTHER player's client (self-echo suppressed by the framework); writes the
	-- MP.GAME.enemy.* store the HUD already reads. The referee (win/lose/lives) is separate,
	-- still driven by pvp_play_hand/pvp_skip.
	on_sync = function(self, from, d)
		local score = MP.INSANE_INT.from_string(d.score)
		local hands_left = tonumber(d.handsLeft)
		local skips = tonumber(d.skips)
		local lives = tonumber(d.lives)

		-- No-animation timer: opponent skip adds time immediately.
		if skips and MP.GAME.enemy.skips ~= skips then
			for _ = 1, skips - MP.GAME.enemy.skips do
				MP.GAME.enemy.spent_in_shop[#MP.GAME.enemy.spent_in_shop + 1] = 0
				if
					MP.GAME.enemy.skips < skips
					and MP.LOBBY.config.timer
					and not MP.GAME.timer_started
					and not MP.GAME.nemesis_timer_started
					and not MP.GAME.timer_consumed
					and MP.is_any_layer_active({ "no_animation_timer", "pressure_timer" })
					and (MP.LOBBY.config.timer_increment_seconds or 0) > 0
				then
					MP.UI.restore_timer(MP.LOBBY.config.timer_increment_seconds)
				end
			end
		end

		if score == nil or hands_left == nil then
			sendDebugMessage("Invalid score or hands_left", "MULTIPLAYER")
			return
		end

		if MP.INSANE_INT.greater_than(score, MP.GAME.enemy.highest_score) then MP.GAME.enemy.highest_score = score end

		-- PvP timer: stop timer according to score.
		if MP.is_pvp_boss() and MP.is_layer_active("pvp_timer") then
			if MP.INSANE_INT.greater_than(MP.GAME.score, score) then
				MP.GAME.nemesis_timer_started = false
			elseif MP.INSANE_INT.equal(MP.GAME.score, score) and MP.GAME.pvp_reached_first then
				MP.GAME.nemesis_timer_started = false
			else
				MP.GAME.timer_started = false
			end
		end

		G.E_MANAGER:add_event(Event({
			blockable = false,
			blocking = false,
			trigger = "ease",
			delay = 3,
			ref_table = MP.GAME.enemy.score,
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
			ref_table = MP.GAME.enemy.score,
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
			ref_table = MP.GAME.enemy.score,
			ref_value = "exponent",
			ease_to = score.exponent,
			func = function(t)
				return math.floor(t)
			end,
		}))

		if MP.GAME.enemy.lives > lives then
			play_sound("holo1", 0.865, 0.9)
			play_sound("gong", 0.765, 0.4)
		end
		if MP.GAME.enemy.skips < skips then
			play_sound("negative", 0.865, 0.4)
			play_sound("gong", 0.765, 0.4)
		end

		MP.GAME.enemy.real_score = score
		MP.GAME.enemy.hands = hands_left
		MP.GAME.enemy.skips = skips
		MP.GAME.enemy.lives = lives
		-- We've now heard from the opponent this blind: unmask their hands count.
		MP.GAME.enemy.info_received = true
		if MP.UI.juice_up_pvp_hud then MP.UI.juice_up_pvp_hud() end
	end,
})

-- Emit the opponent-facing display state through the nemesis blind's procedural sync channel.
-- Called from the playHand/skip transport routes, which assemble the full payload.
function MP.sync_pvp_blind(payload)
	local b = G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind
	if b and b.sync then b:sync(payload) end
end

function MP.is_pvp_boss()
	if not G.GAME or not G.GAME.blind or not G.GAME.blind.config.blind then return false end
	return G.GAME.blind.config.blind.key == "bl_mp_nemesis" or G.GAME.blind.pvp
end
