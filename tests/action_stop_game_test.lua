local function load_action_stop_game(env)
	local f = assert(io.open("networking/action_handlers.lua", "r"))
	local src = f:read("*a")
	f:close()

	local start_idx = assert(src:find("local function action_stop_game%(%)"))
	local next_fn_idx = assert(src:find("\nlocal function action_end_pvp%(%)", start_idx))
	local snippet = src:sub(start_idx, next_fn_idx - 1)

	local chunk = assert(load(snippet .. "\nreturn action_stop_game", "action_stop_game_snippet", "t", env))
	return chunk()
end

describe("action_stop_game", function()
	it("sets message and schedules delayed cleanup", function()
		local attention
		local added_event

		local env = {
			MP = {
				enemy_disconnect_countdown = { end_time = 10 },
				LOBBY = { code = "ABCD", connected = true, in_game = true },
			},
			G = {
				ROOM_ATTACH = {},
				E_MANAGER = {
					add_event = function(_, ev)
						added_event = ev
					end,
				},
			},
			attention_text = function(args)
				attention = args
			end,
			Event = function(def)
				return def
			end,
			set_main_menu_UI = function()
			end,
		}

		local action_stop_game = load_action_stop_game(env)
		action_stop_game()

		assert(env.MP.enemy_disconnect_countdown == nil)
		assert(attention ~= nil)
		assert(attention.text == "Opponent left the lobby")
		assert(added_event.delay == 2.0)
		assert(type(added_event.func) == "function")
	end)

	it("applies delayed state reset and returns true", function()
		local overlay_closed = 0
		local menu_refreshed = 0
		local added_event

		local env = {
			MP = {
				enemy_disconnect_countdown = nil,
				LOBBY = { code = "ABCD", connected = true, in_game = true },
			},
			G = {
				ROOM_ATTACH = {},
				OVERLAY_MENU = true,
				STATE = "INGAME",
				STATE_COMPLETE = true,
				STATES = { MENU = "MENU" },
				E_MANAGER = {
					add_event = function(_, ev)
						added_event = ev
					end,
				},
				FUNCS = {
					exit_overlay_menu = function()
						overlay_closed = overlay_closed + 1
					end,
				},
			},
			attention_text = function()
			end,
			Event = function(def)
				return def
			end,
			set_main_menu_UI = function()
				menu_refreshed = menu_refreshed + 1
			end,
		}

		local action_stop_game = load_action_stop_game(env)
		action_stop_game()
		local ok = added_event.func()

		assert(ok == true)
		assert(env.MP.LOBBY.code == nil)
		assert(env.MP.LOBBY.connected == false)
		assert(env.MP.LOBBY.in_game == false)
		assert(env.G.STATE == "MENU")
		assert(env.G.STATE_COMPLETE == false)
		assert(overlay_closed == 1)
		assert(menu_refreshed == 1)
	end)
end)
