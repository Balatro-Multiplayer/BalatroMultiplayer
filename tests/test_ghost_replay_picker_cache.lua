G = {
	FUNCS = {},
	UIDEF = {},
	UIT = {
		C = "column",
		R = "row",
		ROOT = "root",
		T = "text",
	},
	C = {
		BLACK = "black",
		CLEAR = "clear",
		GREY = "grey",
		L_BLACK = "light_black",
		ORANGE = "orange",
		RED = "red",
		WHITE = "white",
		UI = {
			TEXT_INACTIVE = "text_inactive",
		},
	},
}

local folder_loads = 0
local lovely_loads = 0

MP = {
	GHOST = {
		flip = function() end,
		is_active = function()
			return false
		end,
		load_folder_replays = function()
			folder_loads = folder_loads + 1
			return {}
		end,
		load_lovely_log_replays = function()
			lovely_loads = lovely_loads + 1
			return {}
		end,
	},
}

function localize(key)
	return key
end

function UIBox_button(args)
	return args
end

function G.FUNCS.exit_overlay_menu() end

function G.FUNCS.overlay_menu(args)
	return args
end

function G.UIDEF.ruleset_selection_tabs()
	return {}
end

dofile("ui/main_menu/play_button/ghost_replay_picker.lua")

G.FUNCS.open_ghost_replay_picker()
assert(folder_loads == 1 and lovely_loads == 1, "opening the picker must load replay sources once")

G.FUNCS.preview_ghost_replay({ config = { id = "ghost_replay_1" } })
assert(folder_loads == 1 and lovely_loads == 1, "selecting a replay must reuse the open picker's replay snapshot")

G.FUNCS.flip_ghost_perspective()
assert(folder_loads == 1 and lovely_loads == 1, "flipping perspective must reuse the open picker's replay snapshot")

G.FUNCS.ghost_picker_back()
G.FUNCS.open_ghost_replay_picker()
assert(folder_loads == 2 and lovely_loads == 2, "reopening the picker must refresh replay sources")

print("test_ghost_replay_picker_cache: OK")
