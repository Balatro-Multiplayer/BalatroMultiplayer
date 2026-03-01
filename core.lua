MP = SMODS.current_mod

MP.BANNED_MODS = {
	["Incantation"] = true,
	["Brainstorm"] = true,
	["DVPreview"] = true,
	["Aura"] = true,
	["NotJustYet"] = true,
	["Showman"] = true,
	["TagPreview"] = true,
	["FantomsPreview"] = true,
}

MP.LOBBY = {
	connected = false,
	temp_code = "",
	temp_seed = "",
	code = nil,
	type = "",
	config = {}, -- Now set in MP.reset_lobby_config
	deck = {
		back = "Red Deck",
		sleeve = "sleeve_casl_none",
		stake = 1,
		challenge = "",
	},
	username = "Guest",
	blind_col = 1,
	host = {},
	guest = {},
	is_host = false,
	ready_to_start = false,
}
MP.GAME = {}
MP.UI = {}
MP.ACTIONS = {}
MP.MOD_ACTIONS = {}

-- SMODS flag: lets cards count as multiple enhancements at once (required by Alloy)
MP.optional_features = { quantum_enhancements = true }

function MP.register_mod_action(modAction, callback, modId)
	if not modId then
		local mod = SMODS.current_mod
		if not mod then
			sendWarnMessage("MP.register_mod_action called outside of mod init without a modId", "MULTIPLAYER")
			return
		end
		modId = mod.id
	end
	MP.MOD_ACTIONS[modId] = MP.MOD_ACTIONS[modId] or {}
	MP.MOD_ACTIONS[modId][modAction] = callback
end

MP.INTEGRATIONS = {
	Preview = SMODS.Mods["Multiplayer"].config.integrations.Preview,
}

MP.PREVIEW = {
	text = SMODS.Mods["Multiplayer"].config.preview.text,
	button = SMODS.Mods["Multiplayer"].config.preview.button,
}

MP.EXPERIMENTAL = {
	use_new_networking = true,
	show_sandbox_collection = false,
	alt_stakes = false,
}

G.C.MULTIPLAYER = HEX("AC3232")

MP.SMODS_VERSION = "1.0.0~BETA-1224a"
MP.REQUIRED_LOVELY_VERSION = "0.9"

function MP.should_use_the_order()
	return MP.LOBBY and MP.LOBBY.config and MP.LOBBY.config.the_order and MP.LOBBY.code
end

function MP.is_major_league_ruleset()
	return MP.LOBBY and MP.LOBBY.config and MP.LOBBY.config.ruleset == "ruleset_mp_majorleague" and MP.LOBBY.code
end

function MP.load_mp_file(file)
	local chunk, err = SMODS.load_file(file, "Multiplayer")
	if chunk then
		local ok, func = pcall(chunk)
		if ok then
			return func
		else
			sendWarnMessage("Failed to process file: " .. func, "MULTIPLAYER")
		end
	else
		sendWarnMessage("Failed to find or compile file: " .. tostring(err), "MULTIPLAYER")
	end
	return nil
end

function MP.load_mp_dir(directory, recursive)
	recursive = recursive or false
	local function has_prefix(name)
		return name:match("^_") ~= nil
	end

	local dir_path = MP.path .. "/" .. directory
	local items = NFS.getDirectoryItemsInfo(dir_path)
	-- sort by prefix like { _file, _dir, file, dir }
	table.sort(items, function(a, b)
		if has_prefix(a.name) ~= has_prefix(b.name) then return has_prefix(a.name) end
		return (a.type == "directory") ~= (b.type == "directory") and a.type ~= "directory" or false
	end)

	-- load sorted files/dirs
	for _, item in ipairs(items) do
		local path = directory .. "/" .. item.name
		sendDebugMessage("Loading item: " .. path, "MULTIPLAYER")
		if item.type ~= "directory" then
			MP.load_mp_file(path)
		elseif recursive then
			MP.load_mp_dir(path, recursive)
		end
	end
end

MP.load_mp_dir("lib")
MP.load_mp_dir("overrides")

function MP.reset_lobby_config(persist_ruleset_and_gamemode)
	sendDebugMessage("Resetting lobby options", "MULTIPLAYER")
	MP.LOBBY.config = {
		gold_on_life_loss = true,
		no_gold_on_round_loss = false,
		death_on_round_loss = true,
		different_seeds = false,
		the_order = true,
		starting_lives = 4,
		pvp_start_round = 2,
		timer_base_seconds = 150,
		timer_increment_seconds = 60,
		pvp_countdown_seconds = 3,
		showdown_starting_antes = 3,
		ruleset = persist_ruleset_and_gamemode and MP.LOBBY.config.ruleset or "ruleset_mp_blitz",
		gamemode = persist_ruleset_and_gamemode and MP.LOBBY.config.gamemode or "gamemode_mp_attrition",
		weekly = nil,
		custom_seed = "random",
		different_decks = false,
		back = "Red Deck",
		sleeve = "sleeve_casl_none",
		stake = 1,
		challenge = "",
		cocktail = "",
		multiplayer_jokers = true,
		timer = true,
		timer_forgiveness = 0,
		forced_config = false,
		preview_disabled = false,
		legacy_smallworld = false,
	}
end
MP.reset_lobby_config()

function MP.reset_game_states()
	sendDebugMessage("Resetting game states", "MULTIPLAYER")
	MP.GAME = {
		ready_blind = false,
		ready_blind_text = localize("b_ready"),
		processed_round_done = false,
		lives = 0,
		loaded_ante = 0,
		loading_blinds = false,
		comeback_bonus_given = true,
		comeback_bonus = 0,
		end_pvp = false,
		enemy = {
			score = MP.INSANE_INT.empty(),
			score_text = "0",
			hands = 4,
			location = localize("loc_selecting"),
			skips = 0,
			lives = MP.LOBBY.config.starting_lives,
			sells = 0,
			sells_per_ante = {},
			spent_in_shop = {},
			highest_score = MP.INSANE_INT.empty(),
		},
		location = "loc_selecting",
		next_blind_context = nil,
		ante_key = tostring(math.random()),
		antes_keyed = {},
		prevent_eval = false,
		round_ended = false,
		duplicate_end = false,
		misprint_display = "",
		spent_total = 0,
		spent_before_shop = 0,
		highest_score = MP.INSANE_INT.empty(),
		timer = MP.LOBBY.config.timer_base_seconds,
		timer_started = false,
		pvp_countdown = 0,
		real_money = 0,
		ce_cache = false,
		furthest_blind = 0,
		pincher_index = -3,
		pincher_unlock = false,
		asteroids = 0,
		pizza_discards = 0,
		wait_for_enemys_furthest_blind = false,
		disable_live_and_timer_hud = false,
		timers_forgiven = 0,
		stats = {
			reroll_count = 0,
			reroll_cost_total = 0,
			-- Add more stats here in the future
		},
	}
end
MP.reset_game_states()

MP.LOBBY.username = MP.UTILS.get_username()
MP.LOBBY.blind_col = MP.UTILS.get_blind_col()

MP.LOBBY.config.weekly = MP.UTILS.get_weekly()

if not SMODS.current_mod.lovely then
	G.E_MANAGER:add_event(Event({
		no_delete = true,
		trigger = "immediate",
		blockable = false,
		blocking = false,
		func = function()
			if G.MAIN_MENU_UI then
				MP.UI.UTILS.overlay_message(
					MP.UTILS.wrapText(
						"Your Multiplayer Mod is not loaded correctly, make sure the Multiplayer folder does not have an extra Multiplayer folder around it.",
						50
					)
				)
				return true
			end
		end,
	}))
	return
end

SMODS.Atlas({
	key = "modicon",
	path = "modicon.png",
	px = 34,
	py = 34,
})

MP.load_mp_dir("compatibility")

local networking_dir = MP.EXPERIMENTAL.use_new_networking and "networking" or "networking-old"
MP.load_mp_file(networking_dir .. "/action_handlers.lua")

MP.load_mp_dir("gamemodes")
MP.load_mp_dir("rulesets")
MP.load_mp_dir("ui", true)

if MP.LOBBY.config.weekly then -- this could be a function but why bother
	MP.load_mp_file("rulesets/weeklies/" .. MP.LOBBY.config.weekly .. ".lua")
end

MP.load_mp_dir("objects/editions")
MP.load_mp_dir("objects/enhancements")
MP.load_mp_dir("objects/stickers")
MP.load_mp_dir("objects/blinds")
MP.load_mp_dir("objects/decks")
MP.load_mp_dir("objects/jokers")
MP.load_mp_dir("objects/jokers/sandbox")
MP.load_mp_dir("objects/jokers/sandbox/extra-credit")
MP.load_mp_dir("objects/jokers/standard")
MP.load_mp_dir("objects/stakes")
MP.load_mp_dir("objects/tags")
MP.load_mp_dir("objects/consumables")
MP.load_mp_dir("objects/consumables/sandbox")
MP.load_mp_dir("objects/boosters")
MP.load_mp_dir("objects/challenges")

local SOCKET = MP.load_mp_file(networking_dir .. "/socket.lua")
MP.NETWORKING_THREAD = love.thread.newThread(SOCKET)
MP.NETWORKING_THREAD:start(SMODS.Mods["Multiplayer"].config.server_url, SMODS.Mods["Multiplayer"].config.server_port)
MP.ACTIONS.connect()
