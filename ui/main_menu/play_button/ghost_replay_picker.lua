-- Ghost Replay Picker UI
-- Shown in practice mode to select a past match replay for ghost PvP
-- Two-column layout: replay list (left) + stats detail panel (right)

local function reopen_practice_menu()
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_options("practice"),
	})
end

local function refresh_picker()
	G.FUNCS.exit_overlay_menu()
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ghost_replay_picker(),
	})
end

function G.FUNCS.open_ghost_replay_picker(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ghost_replay_picker(),
	})
end

-- Stashed merged replay list so callbacks can index into it
local _picker_replays = {}
-- Currently previewed replay (shown in right panel)
local _preview_idx = nil

function G.FUNCS.preview_ghost_replay(e)
	local idx = tonumber(e.config.id:match("ghost_replay_(%d+)"))
	_preview_idx = idx
	refresh_picker()
end

function G.FUNCS.load_previewed_ghost(e)
	local replay = _picker_replays[_preview_idx]
	if not replay then return end

	MP.GHOST.load(replay)

	if replay.ruleset then
		MP.SP.ruleset = replay.ruleset
		local ruleset_name = replay.ruleset:gsub("^ruleset_mp_", "")
		MP.LoadReworks(ruleset_name)
	end

	if replay.gamemode then MP.LOBBY.config.gamemode = replay.gamemode end

	_preview_idx = nil
	reopen_practice_menu()
end

-- Keep old name working for any external callers
function G.FUNCS.select_ghost_replay(e)
	G.FUNCS.preview_ghost_replay(e)
end

function G.FUNCS.clear_ghost_replay(e)
	MP.GHOST.clear()
	_preview_idx = nil
	reopen_practice_menu()
end

function G.FUNCS.flip_ghost_perspective(e)
	MP.GHOST.flip()
	refresh_picker()
end

-- DEBUG: Generate a test ghost replay and refresh the picker
function G.FUNCS.generate_test_ghost_replay(e)
	MP.GHOST.generate_test_replay()
	refresh_picker()
end

G.FUNCS.ghost_picker_back = function(e)
	_preview_idx = nil
	reopen_practice_menu()
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function build_replay_label(r)
	local result_text = (r.winner == "player") and "W" or "L"
	local player_display = r.player_name or "?"
	local nemesis_display = r.nemesis_name or "?"
	local ante_display = tostring(r.final_ante or "?")

	local timestamp_display = ""
	if r.timestamp then timestamp_display = os.date("%m/%d", r.timestamp) end

	return string.format(
		"%s %s v %s A%s %s",
		result_text,
		player_display,
		nemesis_display,
		ante_display,
		timestamp_display
	)
end

local function text_row(label, value, scale, label_colour, value_colour)
	scale = scale or 0.3
	label_colour = label_colour or G.C.UI.TEXT_INACTIVE
	value_colour = value_colour or G.C.WHITE
	return {
		n = G.UIT.R,
		config = { align = "cl", padding = 0.02 },
		nodes = {
			{ n = G.UIT.T, config = { text = label .. " ", scale = scale, colour = label_colour } },
			{ n = G.UIT.T, config = { text = tostring(value), scale = scale, colour = value_colour } },
		},
	}
end

local function section_header(title, scale)
	scale = scale or 0.32
	return {
		n = G.UIT.R,
		config = { align = "cl", padding = 0.04 },
		nodes = {
			{ n = G.UIT.T, config = { text = title, scale = scale, colour = G.C.GOLD } },
		},
	}
end

local function format_score(s)
	local n = tonumber(s)
	if not n then return tostring(s) end
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(n)
end

local function joker_list_text(jokers)
	if not jokers or #jokers == 0 then return "None" end
	local names = {}
	for _, j in ipairs(jokers) do
		local key = j.key or j
		-- Try to get localized name
		local name = key
		if G.P_CENTERS and G.P_CENTERS[key] then
			local loc = G.P_CENTERS[key].loc_txt
			if loc and loc.name then name = loc.name end
		end
		-- Clean up key prefix as fallback display
		name = name:gsub("^j_mp_", ""):gsub("^j_", ""):gsub("_", " ")
		names[#names + 1] = name
	end
	return table.concat(names, ", ")
end

-------------------------------------------------------------------------------
-- Stats detail panel (right column)
-------------------------------------------------------------------------------

local function build_stats_panel(r)
	if not r then
		return {
			n = G.UIT.C,
			config = { align = "cm", padding = 0.2, minw = 6, minh = 5 },
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = "Select a replay",
						scale = 0.35,
						colour = G.C.UI.TEXT_INACTIVE,
					},
				},
			},
		}
	end

	local nodes = {}

	-- Match header
	local result_str = (r.winner == "player") and "VICTORY" or "DEFEAT"
	local result_colour = (r.winner == "player") and G.C.GREEN or G.C.RED
	nodes[#nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.04 },
		nodes = {
			{ n = G.UIT.T, config = { text = result_str, scale = 0.4, colour = result_colour } },
		},
	}

	-- Players
	local player_display = r.player_name or "?"
	local nemesis_display = r.nemesis_name or "?"
	nodes[#nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.02 },
		nodes = {
			{ n = G.UIT.T, config = { text = player_display .. "  vs  " .. nemesis_display, scale = 0.35, colour = G.C.WHITE } },
		},
	}

	-- Match info
	nodes[#nodes + 1] = section_header("Match Info")
	local ruleset_display = r.ruleset and r.ruleset:gsub("^ruleset_mp_", "") or "?"
	local gamemode_display = r.gamemode and r.gamemode:gsub("^gamemode_mp_", "") or "?"
	local deck_display = r.deck or "?"
	nodes[#nodes + 1] = text_row("Ruleset:", ruleset_display)
	nodes[#nodes + 1] = text_row("Gamemode:", gamemode_display)
	nodes[#nodes + 1] = text_row("Deck:", deck_display)
	if r.seed then nodes[#nodes + 1] = text_row("Seed:", r.seed) end
	if r.stake then nodes[#nodes + 1] = text_row("Stake:", tostring(r.stake)) end
	nodes[#nodes + 1] = text_row("Final Ante:", tostring(r.final_ante or "?"))
	if r.duration then nodes[#nodes + 1] = text_row("Duration:", r.duration) end
	if r.timestamp then
		nodes[#nodes + 1] = text_row("Date:", os.date("%Y-%m-%d %H:%M", r.timestamp))
	end

	-- Ante breakdown
	if r.ante_snapshots then
		nodes[#nodes + 1] = section_header("Ante Breakdown")
		local antes = {}
		for k in pairs(r.ante_snapshots) do antes[#antes + 1] = tonumber(k) end
		table.sort(antes)

		for _, ante_num in ipairs(antes) do
			local snap = r.ante_snapshots[tostring(ante_num)] or r.ante_snapshots[ante_num]
			if snap then
				local result_icon = snap.result == "win" and "W" or "L"
				local r_col = snap.result == "win" and G.C.GREEN or G.C.RED
				local p_score = format_score(snap.player_score or 0)
				local e_score = format_score(snap.enemy_score or 0)
				local lives_str = ""
				if snap.player_lives and snap.enemy_lives then
					lives_str = string.format("  [%d-%d]", snap.player_lives, snap.enemy_lives)
				end
				nodes[#nodes + 1] = {
					n = G.UIT.R,
					config = { align = "cl", padding = 0.01 },
					nodes = {
						{ n = G.UIT.T, config = { text = string.format("A%d ", ante_num), scale = 0.28, colour = G.C.UI.TEXT_INACTIVE } },
						{ n = G.UIT.T, config = { text = result_icon, scale = 0.28, colour = r_col } },
						{ n = G.UIT.T, config = { text = string.format("  %s - %s%s", p_score, e_score, lives_str), scale = 0.28, colour = G.C.WHITE } },
					},
				}
			end
		end
	end

	-- Jokers
	if r.player_jokers then
		nodes[#nodes + 1] = section_header("Your Jokers")
		local jtext = joker_list_text(r.player_jokers)
		nodes[#nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cl", padding = 0.02, maxw = 5.5 },
			nodes = {
				{ n = G.UIT.T, config = { text = jtext, scale = 0.26, colour = G.C.WHITE } },
			},
		}
	end
	if r.nemesis_jokers then
		nodes[#nodes + 1] = section_header("Opponent Jokers")
		local jtext = joker_list_text(r.nemesis_jokers)
		nodes[#nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cl", padding = 0.02, maxw = 5.5 },
			nodes = {
				{ n = G.UIT.T, config = { text = jtext, scale = 0.26, colour = G.C.WHITE } },
			},
		}
	end

	-- Player stats
	if r.player_stats then
		nodes[#nodes + 1] = section_header("Your Stats")
		if r.player_stats.reroll_count then
			nodes[#nodes + 1] = text_row("Rerolls:", tostring(r.player_stats.reroll_count), 0.28)
		end
		if r.player_stats.reroll_cost_total then
			nodes[#nodes + 1] = text_row("Reroll $:", tostring(r.player_stats.reroll_cost_total), 0.28)
		end
		if r.player_stats.vouchers then
			nodes[#nodes + 1] = text_row("Vouchers:", r.player_stats.vouchers:gsub("v_", ""):gsub("-", ", "):gsub("_", " "), 0.28)
		end
	end

	if r.nemesis_stats then
		nodes[#nodes + 1] = section_header("Opponent Stats")
		if r.nemesis_stats.reroll_count then
			nodes[#nodes + 1] = text_row("Rerolls:", tostring(r.nemesis_stats.reroll_count), 0.28)
		end
		if r.nemesis_stats.reroll_cost_total then
			nodes[#nodes + 1] = text_row("Reroll $:", tostring(r.nemesis_stats.reroll_cost_total), 0.28)
		end
		if r.nemesis_stats.vouchers then
			nodes[#nodes + 1] = text_row("Vouchers:", r.nemesis_stats.vouchers:gsub("v_", ""):gsub("-", ", "):gsub("_", " "), 0.28)
		end
	end

	-- Shop spending
	if r.shop_spending then
		nodes[#nodes + 1] = section_header("Shop Spending")
		local total = 0
		local antes = {}
		for k, v in pairs(r.shop_spending) do
			antes[#antes + 1] = tonumber(k)
			total = total + v
		end
		table.sort(antes)
		local parts = {}
		for _, a in ipairs(antes) do
			parts[#parts + 1] = string.format("A%d:$%d", a, r.shop_spending[tostring(a)] or r.shop_spending[a])
		end
		nodes[#nodes + 1] = text_row("Total:", "$" .. tostring(total), 0.28)
		nodes[#nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cl", padding = 0.02, maxw = 5.5 },
			nodes = {
				{ n = G.UIT.T, config = { text = table.concat(parts, "  "), scale = 0.24, colour = G.C.UI.TEXT_INACTIVE } },
			},
		}
	end

	-- Failed rounds
	if r.failed_rounds and #r.failed_rounds > 0 then
		local fr_parts = {}
		for _, a in ipairs(r.failed_rounds) do fr_parts[#fr_parts + 1] = "A" .. tostring(a) end
		nodes[#nodes + 1] = text_row("Failed Rounds:", table.concat(fr_parts, ", "), 0.28, G.C.UI.TEXT_INACTIVE, G.C.RED)
	end

	-- Load as ghost button
	nodes[#nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.08 },
		nodes = {
			UIBox_button({
				id = "load_previewed_ghost",
				button = "load_previewed_ghost",
				label = { "Load as Ghost" },
				minw = 4,
				minh = 0.6,
				scale = 0.35,
				colour = G.C.GREEN,
				hover = true,
				shadow = true,
			}),
		},
	}

	return {
		n = G.UIT.C,
		config = { align = "tm", padding = 0.15, minw = 6, r = 0.1, colour = G.C.L_BLACK },
		nodes = nodes,
	}
end

-------------------------------------------------------------------------------
-- Main picker UI
-------------------------------------------------------------------------------

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

	-- Stash for callbacks to index into
	_picker_replays = all

	-- Left column: replay list
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
						scale = 0.35,
						colour = G.C.UI.TEXT_INACTIVE,
					},
				},
			},
		}
	else
		for i, r in ipairs(all) do
			local label = build_replay_label(r)
			local is_selected = (_preview_idx == i)
			local btn_colour
			if is_selected then
				btn_colour = G.C.WHITE
			elseif r._source == "file" then
				btn_colour = G.C.BLUE
			else
				btn_colour = G.C.GREY
			end

			replay_nodes[#replay_nodes + 1] = {
				n = G.UIT.R,
				config = { align = "cm", padding = 0.03 },
				nodes = {
					UIBox_button({
						id = "ghost_replay_" .. i,
						button = "preview_ghost_replay",
						label = { label },
						minw = 5.5,
						minh = 0.45,
						scale = 0.3,
						colour = btn_colour,
						hover = true,
						shadow = true,
					}),
				},
			}
		end
	end

	-- Control buttons below the list
	local control_nodes = {}

	if MP.GHOST.is_active() then
		local playing_as = MP.GHOST.flipped
			and (MP.GHOST.replay.nemesis_name or "?")
			or (MP.GHOST.replay.player_name or "?")
		control_nodes[#control_nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.03 },
			nodes = {
				UIBox_button({
					id = "flip_ghost_perspective",
					button = "flip_ghost_perspective",
					label = { "As: " .. playing_as },
					minw = 2.5,
					minh = 0.45,
					scale = 0.3,
					colour = G.C.GREEN,
					hover = true,
					shadow = true,
				}),
				UIBox_button({
					id = "clear_ghost_replay",
					button = "clear_ghost_replay",
					label = { "Clear" },
					minw = 2,
					minh = 0.45,
					scale = 0.3,
					colour = G.C.RED,
					hover = true,
					shadow = true,
				}),
			},
		}
	end

	-- DEBUG button
	control_nodes[#control_nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.03 },
		nodes = {
			UIBox_button({
				id = "generate_test_ghost",
				button = "generate_test_ghost_replay",
				label = { "DEBUG: Gen Test" },
				minw = 4,
				minh = 0.4,
				scale = 0.25,
				colour = G.C.PURPLE,
				hover = true,
				shadow = true,
			}),
		},
	}

	-- Back button
	control_nodes[#control_nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.05 },
		nodes = {
			UIBox_button({
				id = "ghost_picker_back",
				button = "ghost_picker_back",
				label = { localize("b_back") },
				minw = 3,
				minh = 0.5,
				scale = 0.35,
				colour = G.C.ORANGE,
				hover = true,
				shadow = true,
			}),
		},
	}

	-- Left column
	local left_col = {
		n = G.UIT.C,
		config = { align = "tm", padding = 0.1, minw = 6, r = 0.1, colour = G.C.L_BLACK },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.06 },
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_ghost_replays"),
							scale = 0.45,
							colour = G.C.WHITE,
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.05, maxh = 5 },
				nodes = replay_nodes,
			},
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.05 },
				nodes = control_nodes,
			},
		},
	}

	-- Right column: stats detail
	local preview_replay = _preview_idx and _picker_replays[_preview_idx] or nil
	local right_col = build_stats_panel(preview_replay)

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR, minh = 7, minw = 13 },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.15 },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "tm", padding = 0.15, r = 0.1, colour = G.C.BLACK },
						nodes = {
							{
								n = G.UIT.R,
								config = { align = "tm", padding = 0.05 },
								nodes = { left_col, right_col },
							},
						},
					},
				},
			},
		},
	}
end
