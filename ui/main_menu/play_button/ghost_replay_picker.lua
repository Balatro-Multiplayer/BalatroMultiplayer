-- Ghost Replay Picker UI
-- Shown in practice mode to select a past match replay for ghost PvP

local function reopen_practice_menu()
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_options("practice"),
	})
end

function G.FUNCS.open_ghost_replay_picker(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ghost_replay_picker(),
	})
end

-- Stashed merged replay list so select_ghost_replay can index into it
local _picker_replays = {}

function G.FUNCS.select_ghost_replay(e)
	local idx = tonumber(e.config.id:match("ghost_replay_(%d+)"))
	local replay = _picker_replays[idx]

	if not replay then return end

	MP.GHOST.load(replay)

	-- Set ruleset from the replay
	if replay.ruleset then
		MP.SP.ruleset = replay.ruleset
		local ruleset_name = replay.ruleset:gsub("^ruleset_mp_", "")
		MP.LoadReworks(ruleset_name)
	end

	-- Set gamemode from the replay
	if replay.gamemode then MP.LOBBY.config.gamemode = replay.gamemode end

	reopen_practice_menu()
end

function G.FUNCS.clear_ghost_replay(e)
	MP.GHOST.clear()
	reopen_practice_menu()
end

function G.FUNCS.flip_ghost_perspective(e)
	MP.GHOST.flip()
	G.FUNCS.exit_overlay_menu()
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ghost_replay_picker(),
	})
end

-- DEBUG: Generate a test ghost replay and refresh the picker
function G.FUNCS.generate_test_ghost_replay(e)
	MP.GHOST.generate_test_replay()
	-- Refresh the picker to show the new replay
	G.FUNCS.exit_overlay_menu()
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ghost_replay_picker(),
	})
end

local function build_replay_label(r)
	local result_text = (r.winner == "player") and "W" or "L"
	local player_display = r.player_name or "?"
	local nemesis_display = r.nemesis_name or "?"
	local ruleset_display = r.ruleset and r.ruleset:gsub("^ruleset_mp_", "") or "?"
	local deck_display = r.deck or "?"
	local ante_display = tostring(r.final_ante or "?")

	local timestamp_display = ""
	if r.timestamp then timestamp_display = os.date("%m/%d %H:%M", r.timestamp) end

	return string.format(
		"%s | %s vs %s | %s | %s | Ante %s | %s",
		result_text,
		player_display,
		nemesis_display,
		ruleset_display,
		deck_display,
		ante_display,
		timestamp_display
	)
end

function G.UIDEF.ghost_replay_picker()
	-- Merge config replays + folder replays into one list, sorted newest-first
	local config_replays = SMODS.Mods["Multiplayer"].config.ghost_replays or {}
	local folder_replays = MP.GHOST.load_folder_replays()

	local all = {}
	for _, r in ipairs(config_replays) do
		r._source = r._source or "config"
		all[#all + 1] = r
	end
	for _, r in ipairs(folder_replays) do
		all[#all + 1] = r
	end

	-- Sort newest-first
	table.sort(all, function(a, b)
		return (a.timestamp or 0) > (b.timestamp or 0)
	end)

	-- Stash for select_ghost_replay to index into
	_picker_replays = all

	local replay_nodes = {}

	if #all == 0 then
		replay_nodes[#replay_nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.2 },
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = localize("k_no_ghost_replays"),
						scale = 0.4,
						colour = G.C.UI.TEXT_INACTIVE,
					},
				},
			},
		}
	else
		for i, r in ipairs(all) do
			local label = build_replay_label(r)
			local btn_colour = r._source == "file" and G.C.BLUE or G.C.GREY

			replay_nodes[#replay_nodes + 1] = {
				n = G.UIT.R,
				config = { align = "cm", padding = 0.05 },
				nodes = {
					UIBox_button({
						id = "ghost_replay_" .. i,
						button = "select_ghost_replay",
						label = { label },
						minw = 7,
						minh = 0.5,
						scale = 0.35,
						colour = btn_colour,
						hover = true,
						shadow = true,
					}),
				},
			}
		end
	end

	-- Clear ghost + flip perspective buttons if one is active
	local clear_nodes = {}
	if MP.GHOST.is_active() then
		-- Show who you're playing as
		local playing_as = MP.GHOST.flipped
			and (MP.GHOST.replay.nemesis_name or "?")
			or (MP.GHOST.replay.player_name or "?")
		clear_nodes[#clear_nodes + 1] = UIBox_button({
			id = "flip_ghost_perspective",
			button = "flip_ghost_perspective",
			label = { "Playing as: " .. playing_as },
			minw = 3,
			minh = 0.5,
			scale = 0.35,
			colour = G.C.GREEN,
			hover = true,
			shadow = true,
		})
		clear_nodes[#clear_nodes + 1] = UIBox_button({
			id = "clear_ghost_replay",
			button = "clear_ghost_replay",
			label = { "Clear Ghost" },
			minw = 3,
			minh = 0.5,
			scale = 0.35,
			colour = G.C.RED,
			hover = true,
			shadow = true,
		})
	end

	-- DEBUG: Generate test replay button
	local debug_nodes = {}
	debug_nodes[#debug_nodes + 1] = UIBox_button({
		id = "generate_test_ghost",
		button = "generate_test_ghost_replay",
		label = { "DEBUG: Generate Test Replay" },
		minw = 5,
		minh = 0.5,
		scale = 0.3,
		colour = G.C.PURPLE,
		hover = true,
		shadow = true,
	})

	-- Back button to return to practice menu
	local back_nodes = {}
	back_nodes[#back_nodes + 1] = UIBox_button({
		id = "ghost_picker_back",
		button = "ghost_picker_back",
		label = { localize("b_back") },
		minw = 3,
		minh = 0.6,
		scale = 0.4,
		colour = G.C.ORANGE,
		hover = true,
		shadow = true,
	})

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR, minh = 6, minw = 8 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.2, r = 0.1, colour = G.C.BLACK, minw = 8 },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.1 },
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = localize("k_ghost_replays"),
									scale = 0.5,
									colour = G.C.WHITE,
								},
							},
						},
					},
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.05, maxh = 4 },
						nodes = replay_nodes,
					},
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.1 },
						nodes = clear_nodes,
					},
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.05 },
						nodes = debug_nodes,
					},
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.1 },
						nodes = back_nodes,
					},
				},
			},
		},
	}
end

G.FUNCS.ghost_picker_back = function(e)
	reopen_practice_menu()
end
