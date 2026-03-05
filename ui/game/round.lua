-- Contains function overrides (monkey-patches) for round-related functionality
-- Overrides functions like ease_ante, ease_round, reset_blinds, EventManager:add_event

local ease_ante_ref = ease_ante
function ease_ante(mod)
	if MP.LOBBY.code and not MP.LOBBY.config.disable_live_and_timer_hud then
		-- Prevents easing multiple times at once
		if MP.GAME.antes_keyed[MP.GAME.ante_key] then return end

		-- pizza: remove discards
		if MP.GAME.pizza_discards > 0 then
			G.GAME.round_resets.discards = G.GAME.round_resets.discards - MP.GAME.pizza_discards
			ease_discard(-MP.GAME.pizza_discards)
			MP.GAME.pizza_discards = 0
		end

		MP.GAME.antes_keyed[MP.GAME.ante_key] = true
		MP.ACTIONS.set_ante(G.GAME.round_resets.ante + mod)
		G.E_MANAGER:add_event(Event({
			trigger = "immediate",
			func = function()
				G.GAME.round_resets.ante = G.GAME.round_resets.ante + mod
				check_and_set_high_score("furthest_ante", G.GAME.round_resets.ante)
				return true
			end,
		}))
	end
	return ease_ante_ref(mod)
end

local ease_round_ref = ease_round
function ease_round(mod)
	if MP.LOBBY.code and not MP.LOBBY.config.disable_live_and_timer_hud and MP.LOBBY.config.timer then return end
	ease_round_ref(mod)
end

local reset_blinds_ref = reset_blinds
function reset_blinds()
	reset_blinds_ref()
	G.GAME.round_resets.pvp_blind_choices = {}
	if MP.LOBBY.code then
		local mp_small_choice, mp_big_choice, mp_boss_choice =
			MP.Gamemodes[MP.LOBBY.config.gamemode]:get_blinds_by_ante(G.GAME.round_resets.ante)
		G.GAME.round_resets.blind_choices.Small = mp_small_choice or G.GAME.round_resets.blind_choices.Small
		G.GAME.round_resets.blind_choices.Big = mp_big_choice or G.GAME.round_resets.blind_choices.Big
		G.GAME.round_resets.blind_choices.Boss = mp_boss_choice or G.GAME.round_resets.blind_choices.Boss
	end
end

-- necessary for showdown mode to ensure rounds progress properly, only affects nemesis blind to avoid possible incompatibilities (though i know many mods like to do this exact hook)
local blind_get_type = Blind.get_type
function Blind:get_type()
	if self.name == "bl_mp_nemesis" then
		return G.GAME.blind_on_deck
	else
		return blind_get_type(self)
	end
end

-- added event suppression for a lovely patch for ease_ante
local add_event_ref = EventManager.add_event
function EventManager:add_event(event, queue, front)
	if MP.suppress_next_event then
		MP.suppress_next_event = false
		return
	end
	return add_event_ref(self, event, queue, front)
end
