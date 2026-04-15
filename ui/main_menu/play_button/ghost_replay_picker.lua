-- Match Replay Picker UI
-- Shown in practice mode to select a past match replay for ghost PvP
-- Two-column layout: replay list (left) + match details panel (right)

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
-- Perspective flip for the previewed replay (before loading)
local _preview_flipped = false

function G.FUNCS.preview_ghost_replay(e)
	local idx = tonumber(e.config.id:match("ghost_replay_(%d+)"))
	if idx ~= _preview_idx then
		_preview_flipped = false
	end
	_preview_idx = idx
	refresh_picker()
end

function G.FUNCS.load_previewed_ghost(e)
	local replay = _picker_replays[_preview_idx]
	if not replay then return end
	if not MP.GHOST.is_ruleset_supported(replay) then return end

	MP.GHOST.load(replay)
	MP.GHOST.flipped = _preview_flipped

	if replay.ruleset then
		MP.SP.ruleset = replay.ruleset
		local ruleset_name = replay.ruleset:gsub("^ruleset_mp_", "")
		MP.LoadReworks(ruleset_name)
	end

	_preview_idx = nil
	_preview_flipped = false
	reopen_practice_menu()
end

-- Keep old name working for any external callers
function G.FUNCS.select_ghost_replay(e)
	G.FUNCS.preview_ghost_replay(e)
end

function G.FUNCS.clear_ghost_replay(e)
	MP.GHOST.clear()
	_preview_idx = nil
	_preview_flipped = false
	reopen_practice_menu()
end

function G.FUNCS.flip_ghost_perspective(e)
	if _preview_idx then
		_preview_flipped = not _preview_flipped
	else
		MP.GHOST.flip()
	end
	refresh_picker()
end

G.FUNCS.ghost_picker_back = function(e)
	_preview_idx = nil
	_preview_flipped = false
	reopen_practice_menu()
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------


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


local function build_joker_card_area(jokers, width)
	if not jokers or #jokers == 0 then return nil end

	width = width or 5.5
	local card_size = math.max(0.3, 0.8 - 0.01 * #jokers)
	local card_area = CardArea(0, 0, width, G.CARD_H * card_size, {
		card_limit = nil,
		type = "title_2",
		view_deck = true,
		highlight_limit = 0,
		card_w = G.CARD_W * card_size,
	})

	for _, j in ipairs(jokers) do
		local key = j.key or j
		local center = G.P_CENTERS[key]
		if center then
			local card = Card(
				0,
				0,
				G.CARD_W * card_size,
				G.CARD_H * card_size,
				nil,
				center,
				{ bypass_discovery_center = true, bypass_discovery_ui = true }
			)
			card_area:emplace(card)
		end
	end

	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.02 },
		nodes = {
			{ n = G.UIT.O, config = { object = card_area } },
		},
	}
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
						text = "Select a match",
						scale = 0.35,
						colour = G.C.UI.TEXT_INACTIVE,
					},
				},
			},
		}
	end

	-- Header row (spans both columns)
	local header_nodes = {}

	local result_str = (r.winner == "player") and "VICTORY" or "DEFEAT"
	local result_colour = (r.winner == "player") and G.C.GREEN or G.C.RED
	header_nodes[#header_nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.04 },
		nodes = {
			{ n = G.UIT.T, config = { text = result_str, scale = 0.4, colour = result_colour } },
		},
	}

	local player_display = r.player_name or "?"
	local nemesis_display = r.nemesis_name or "?"
	header_nodes[#header_nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.02 },
		nodes = {
			{
				n = G.UIT.T,
				config = { text = player_display .. "  vs  " .. nemesis_display, scale = 0.35, colour = G.C.WHITE },
			},
		},
	}

	-- Left inner column: match info + ante breakdown + stats
	local left_nodes = {}

	left_nodes[#left_nodes + 1] = section_header("Match Info")
	if r._filename then
		local source_label = r._filename
		if r._game_index and r._game_count and r._game_count > 1 then
			source_label = source_label .. string.format(" (game %d of %d)", r._game_index, r._game_count)
		end
		left_nodes[#left_nodes + 1] = text_row("Source:", source_label, 0.25)
	end
	local ruleset_display = r.ruleset and r.ruleset:gsub("^ruleset_mp_", "") or "?"
	local gamemode_display = r.gamemode and r.gamemode:gsub("^gamemode_mp_", "") or "?"
	local deck_display = r.deck or "?"
	left_nodes[#left_nodes + 1] = text_row("Ruleset:", ruleset_display)
	left_nodes[#left_nodes + 1] = text_row("Gamemode:", gamemode_display)
	left_nodes[#left_nodes + 1] = text_row("Deck:", deck_display)
	if r.seed then left_nodes[#left_nodes + 1] = text_row("Seed:", r.seed) end
	if r.stake then left_nodes[#left_nodes + 1] = text_row("Stake:", tostring(r.stake)) end
	left_nodes[#left_nodes + 1] = text_row("Final Ante:", tostring(r.final_ante or "?"))
	if r.duration then left_nodes[#left_nodes + 1] = text_row("Duration:", r.duration) end
	if r.timestamp then left_nodes[#left_nodes + 1] = text_row("Date:", os.date("%Y-%m-%d %H:%M", r.timestamp)) end

	-- Ante breakdown
	if r.ante_snapshots then
		left_nodes[#left_nodes + 1] = section_header("Ante Breakdown")
		local antes = {}
		for k in pairs(r.ante_snapshots) do
			antes[#antes + 1] = tonumber(k)
		end
		table.sort(antes)

		for _, ante_num in ipairs(antes) do
			local snap = r.ante_snapshots[tostring(ante_num)] or r.ante_snapshots[ante_num]
			if snap then
				local result_icon = snap.result == "win" and "W" or "L"
				local r_col = snap.result == "win" and G.C.GREEN or G.C.RED
				local p_score = MP.GHOST.format_score(snap.player_score or 0)
				local e_score = MP.GHOST.format_score(snap.enemy_score or 0)
				local lives_str = ""
				if snap.player_lives and snap.enemy_lives then
					lives_str = string.format("  [%d-%d]", snap.player_lives, snap.enemy_lives)
				end
				left_nodes[#left_nodes + 1] = {
					n = G.UIT.R,
					config = { align = "cl", padding = 0.01 },
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = string.format("A%d ", ante_num),
								scale = 0.28,
								colour = G.C.UI.TEXT_INACTIVE,
							},
						},
						{ n = G.UIT.T, config = { text = result_icon, scale = 0.28, colour = r_col } },
						{
							n = G.UIT.T,
							config = {
								text = string.format("  %s - %s%s", p_score, e_score, lives_str),
								scale = 0.28,
								colour = G.C.WHITE,
							},
						},
					},
				}
			end
		end
	end

	-- Player/opponent stats
	local function add_stats(nodes, stats, label)
		if not stats then return end
		nodes[#nodes + 1] = section_header(label)
		if stats.reroll_count then nodes[#nodes + 1] = text_row("Rerolls:", tostring(stats.reroll_count), 0.28) end
		if stats.reroll_cost_total then
			nodes[#nodes + 1] = text_row("Reroll $:", tostring(stats.reroll_cost_total), 0.28)
		end
		if stats.vouchers then
			nodes[#nodes + 1] =
				text_row("Vouchers:", stats.vouchers:gsub("v_", ""):gsub("-", ", "):gsub("_", " "), 0.28)
		end
	end

	add_stats(left_nodes, r.player_stats, "Your Stats")
	add_stats(left_nodes, r.nemesis_stats, "Opponent Stats")

	-- Failed rounds
	if r.failed_rounds and #r.failed_rounds > 0 then
		local fr_parts = {}
		for _, a in ipairs(r.failed_rounds) do
			fr_parts[#fr_parts + 1] = "A" .. tostring(a)
		end
		left_nodes[#left_nodes + 1] =
			text_row("Failed Rounds:", table.concat(fr_parts, ", "), 0.28, G.C.UI.TEXT_INACTIVE, G.C.RED)
	end

	-- Right inner column: jokers + shop spending
	local right_nodes = {}

	if r.player_jokers then
		right_nodes[#right_nodes + 1] = section_header("Your Jokers")
		local joker_area = build_joker_card_area(r.player_jokers, 4)
		if joker_area then right_nodes[#right_nodes + 1] = joker_area end
	end
	if r.nemesis_jokers then
		right_nodes[#right_nodes + 1] = section_header("Opponent Jokers")
		local joker_area = build_joker_card_area(r.nemesis_jokers, 4)
		if joker_area then right_nodes[#right_nodes + 1] = joker_area end
	end

	-- Shop spending
	if r.shop_spending then
		right_nodes[#right_nodes + 1] = section_header("Shop Spending")
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
		right_nodes[#right_nodes + 1] = text_row("Total:", "$" .. tostring(total), 0.28)
		right_nodes[#right_nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cl", padding = 0.02, maxw = 4 },
			nodes = {
				{
					n = G.UIT.T,
					config = { text = table.concat(parts, "  "), scale = 0.24, colour = G.C.UI.TEXT_INACTIVE },
				},
			},
		}
	end

	-- Assemble two-column body
	local body_row = {
		n = G.UIT.R,
		config = { align = "tm", padding = 0.05 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "tm", padding = 0.08, minw = 4 },
				nodes = left_nodes,
			},
			{
				n = G.UIT.C,
				config = { align = "tm", padding = 0.08, minw = 4.5 },
				nodes = right_nodes,
			},
		},
	}

	-- Playing-as flip button + Load button (spans full width)
	local playing_as = _preview_flipped
		and (r.nemesis_name or "?")
		or (r.player_name or "?")

	local supported = MP.GHOST.is_ruleset_supported(r)
	local action_nodes = {}

	if supported then
		action_nodes[#action_nodes + 1] = UIBox_button({
			id = "flip_ghost_perspective",
			button = "flip_ghost_perspective",
			label = { "Playing as: " .. playing_as },
			minw = 3.5,
			minh = 0.5,
			scale = 0.3,
			colour = G.C.BLUE,
			hover = true,
			shadow = true,
		})
		action_nodes[#action_nodes + 1] = UIBox_button({
			id = "load_previewed_ghost",
			button = "load_previewed_ghost",
			label = { "Play Match" },
			minw = 3.5,
			minh = 0.5,
			scale = 0.35,
			colour = G.C.GREEN,
			hover = true,
			shadow = true,
		})
	else
		action_nodes[#action_nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.04 },
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = "Unsupported ruleset — cannot play this replay",
						scale = 0.3,
						colour = G.C.RED,
					},
				},
			},
		}
	end

	local load_button = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.08 },
		nodes = action_nodes,
	}

	return {
		n = G.UIT.C,
		config = { align = "tm", padding = 0.1, minw = 9, r = 0.1, colour = G.C.L_BLACK },
		nodes = {
			-- Header spanning both columns
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = { { n = G.UIT.C, config = { align = "cm" }, nodes = header_nodes } },
			},
			-- Two-column body
			body_row,
			-- Full-width button
			load_button,
		},
	}
end

-------------------------------------------------------------------------------
-- Main picker UI
-------------------------------------------------------------------------------

function G.UIDEF.ghost_replay_picker()
	-- Load replays from the replays/ folder, sorted newest-first
	local all = MP.GHOST.load_folder_replays()

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
		replay_nodes[#replay_nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.02 },
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = "Place .log or .json files in the replays/ folder",
						scale = 0.28,
						colour = G.C.UI.TEXT_INACTIVE,
					},
				},
			},
		}
	else
		local last_filename = nil
		for i, r in ipairs(all) do
			-- Show filename header when entering a new log file group with multiple games
			if r._filename and r._game_count and r._game_count > 1 then
				if r._filename ~= last_filename then
					last_filename = r._filename
					local display_name = r._filename:gsub("%.log$", "")
					replay_nodes[#replay_nodes + 1] = {
						n = G.UIT.R,
						config = { align = "cl", padding = 0.02 },
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = display_name .. " (" .. r._game_count .. " games)",
									scale = 0.25,
									colour = G.C.UI.TEXT_INACTIVE,
								},
							},
						},
					}
				end
			else
				last_filename = nil
			end

			local label = MP.GHOST.build_label(r)
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
		control_nodes[#control_nodes + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.03 },
			nodes = {
				UIBox_button({
					id = "clear_ghost_replay",
					button = "clear_ghost_replay",
					label = { "Clear Replay" },
					minw = 3,
					minh = 0.45,
					scale = 0.3,
					colour = G.C.RED,
					hover = true,
					shadow = true,
				}),
			},
		}
	end

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
