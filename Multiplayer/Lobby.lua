--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD LOBBY-------------------------

G.MULTIPLAYER = {}

G.LOBBY = {
	connected = false,
	temp_code = "",
	code = nil,
	type = "",
	config = {
		no_gold_on_round_loss = true,
		death_on_round_loss = false,
		different_seeds = false
	},
	username = "Guest",
	host = {},
	guest = {},
	is_host = false,
	enemy = {
		score = 0,
		hands = 4,
	},
}

G.MULTIPLAYER_GAME = {
	ready_blind = false,
	ready_blind_text = "Ready",
	processed_round_done = false,
	lives = 0,
	loaded_ante = 0,
	loading_blinds = false
}

PREV_ACHIEVEMENT_VALUE = true
function G.MULTIPLAYER.update_connection_status()
	-- Save the previous value of the achievement flag
	PREV_ACHIEVEMENT_VALUE = G.F_NO_ACHIEVEMENTS
	if G.LOBBY.connected and G.LOBBY.code then
		-- Disable achievements when connected to server
		G.F_NO_ACHIEVEMENTS = true
	else
		-- Restore them when disconnected
		G.F_NO_ACHIEVEMENTS = PREV_ACHIEVEMENT_VALUE
	end

	if G.HUD_connection_status then
		G.HUD_connection_status:remove()
	end
	G.HUD_connection_status = G.UIDEF.get_connection_status_ui()
end

local gameMainMenuRef = Game.main_menu
---@diagnostic disable-next-line: duplicate-set-field
function Game:main_menu(change_context)
	G.MULTIPLAYER.update_connection_status()
	gameMainMenuRef(self, change_context)
end

function G.FUNCS.copy_to_clipboard(e)
	Utils.copy_to_clipboard(G.LOBBY.code)
end

function G.FUNCS.reconnect(e)
	G.MULTIPLAYER.connect()
	G.FUNCS:exit_overlay_menu()
end

function G.MULTIPLAYER.update_player_usernames()
	if G.LOBBY.code then
		if G.MAIN_MENU_UI then
			G.MAIN_MENU_UI:remove()
		end

		G.FUNCS.display_lobby_main_menu_UI()
	end
end

--[[
	There doesn't seem to be any other way to fix the wipe crashes than copying and manipulating the whole function
]]

G.FUNCS.wipe_off = function()
  G.E_MANAGER:add_event(Event({
    no_delete = true,
    func = function()
      delay(0.3)
			if not G.screenwipe then return true end
      G.screenwipe.children.particles.max = 0
      G.E_MANAGER:add_event(Event({
          trigger = 'ease',
          no_delete = true,
          blockable = false,
          blocking = false,
          timer = 'REAL',
          ref_table = G.screenwipe.colours.black,
          ref_value = 4,
          ease_to = 0,
          delay =  0.3,
          func = (function(t) return t end)
      }))
      G.E_MANAGER:add_event(Event({
        trigger = 'ease',
        no_delete = true,
        blockable = false,
        blocking = false,
        timer = 'REAL',
        ref_table = G.screenwipe.colours.white,
        ref_value = 4,
        ease_to = 0,
        delay =  0.3,
        func = (function(t) return t end)
    }))
      return true
    end
  }))
  G.E_MANAGER:add_event(Event({
    trigger = 'after',
    delay = 0.55,
    no_delete = true,
    blocking = false,
    timer = 'REAL',
    func = function()
			if not G.screenwipe then return true end
      if G.screenwipecard then G.screenwipecard:start_dissolve({G.C.BLACK, G.C.ORANGE,G.C.GOLD, G.C.RED}) end
      if G.screenwipe:get_UIE_by_ID('text') then 
        for k, v in ipairs(G.screenwipe:get_UIE_by_ID('text').children) do
          v.children[1].config.object:pop_out(4)
        end
      end
      return true
    end
  }))
  G.E_MANAGER:add_event(Event({
    trigger = 'after',
    delay = 1.1,
    no_delete = true,
    blocking = false,
    timer = 'REAL',
    func = function()
			if not G.screenwipe then return true end
      G.screenwipe.children.particles:remove()
      G.screenwipe:remove()
      G.screenwipe.children.particles = nil
      G.screenwipe = nil
      G.screenwipecard = nil
      return true
    end
  }))
  G.E_MANAGER:add_event(Event({
    trigger = 'after',
    delay = 1.2,
    no_delete = true,
    blocking = true,
    timer = 'REAL',
    func = function()
      return true
    end
  }))
end

----------------------------------------------
------------MOD LOBBY END---------------------
