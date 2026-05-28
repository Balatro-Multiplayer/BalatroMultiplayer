-- Match Replay Picker UI
-- Shown in practice mode to select a past match replay for ghost PvP
-- Two-column layout: replay list (left) + match details panel (right)

local function reopen_practice_menu()
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_tabs("practice"),
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

	-- Replay's ruleset wins; if it has none, fall back to whatever the picker
	-- left in MP.SP.ruleset. If neither exists we're flying blind, but
	-- apply_default_modifiers(nil) just clears, so we degrade quietly.
	local ruleset_key = replay.ruleset or MP.SP.ruleset
	if ruleset_key then
		MP.SP.ruleset = ruleset_key
		local ruleset_name = ruleset_key:gsub("^ruleset_mp_", "")
		MP.apply_default_modifiers(ruleset_name)
		MP.LoadReworks(ruleset_name)
	end

	_preview_idx = nil
	_preview_flipped = false
	G.FUNCS.start_practice_run(e)
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
	scale = scale or 0.3
	return {
		n = G.UIT.R,
		config = { align = "cl", padding = 0.02 },
		nodes = {
			{ n = G.UIT.T, config = { text = title, scale = scale, colour = G.C.GOLD } },
		},
	}
end


local function build_joker_card_area(jokers, width, base_scale)
	if not jokers or #jokers == 0 then return nil end

	width = width or 5.5
	base_scale = base_scale or 0.8
	local card_size = math.max(0.3, base_scale - 0.01 * #jokers)
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
-- Stats panel sub-builders
-------------------------------------------------------------------------------

local function build_header_row(r)
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

	return header_nodes
end

local function build_match_info_band(r)
	local ruleset_display = r.ruleset and r.ruleset:gsub("^ruleset_mp_", "") or "?"
	local gamemode_display = r.gamemode and r.gamemode:gsub("^gamemode_mp_", "") or "?"
	local deck_display = r.deck or "?"

	local info_left = {}
	local info_right = {}
	info_left[#info_left + 1] = text_row("Ruleset:", ruleset_display, 0.25)
	info_left[#info_left + 1] = text_row("Gamemode:", gamemode_display, 0.25)
	info_left[#info_left + 1] = text_row("Deck:", deck_display, 0.25)
	if r.seed then info_left[#info_left + 1] = text_row("Seed:", r.seed, 0.25) end
	if r.stake then info_left[#info_left + 1] = text_row("Stake:", tostring(r.stake), 0.25) end

	info_right[#info_right + 1] = text_row("Final Ante:", tostring(r.final_ante or "?"), 0.25)
	if r.duration then info_right[#info_right + 1] = text_row("Duration:", r.duration, 0.25) end
	if r.timestamp then
		info_right[#info_right + 1] = text_row("Date:", os.date("%Y-%m-%d %H:%M", r.timestamp), 0.25)
	end
	if r._filename then
		local source_label = r._filename
		if r._game_index and r._game_count and r._game_count > 1 then
			source_label = source_label .. string.format(" (g%d/%d)", r._game_index, r._game_count)
		end
		info_right[#info_right + 1] = text_row("Source:", source_label, 0.22)
	end

	return {
		n = G.UIT.C,
		config = { align = "tm", padding = 0.02 },
		nodes = {
			section_header("Match Info"),
			{
				n = G.UIT.R,
				config = { align = "tm", padding = 0.02 },
				nodes = {
					{ n = G.UIT.C, config = { align = "tl", padding = 0.04, minw = 4 }, nodes = info_left },
					{ n = G.UIT.C, config = { align = "tl", padding = 0.04, minw = 4 }, nodes = info_right },
				},
			},
		},
	}
end

local function build_ante_breakdown(r)
	local ante_nodes = {}
	if r.ante_snapshots then
		ante_nodes[#ante_nodes + 1] = section_header("Ante Breakdown")
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
				ante_nodes[#ante_nodes + 1] = {
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
	return ante_nodes
end

-- Duel body: symmetric You / Opponent columns (vouchers + jokers)
-- Note: reroll_count / reroll_cost_total are only captured for the local
-- player, so they live in the footer's "Spending" cell instead of here.
local function build_side_nodes(stats, jokers, label)
	local nodes = {}
	nodes[#nodes + 1] = section_header(label)
	if stats and stats.vouchers then
		local voucher_keys = {}
		for key in stats.vouchers:gmatch("[^-]+") do
			if G.P_CENTERS[key] then voucher_keys[#voucher_keys + 1] = key end
		end
		if #voucher_keys > 0 then
			local voucher_area = build_joker_card_area(voucher_keys, 4, 0.45)
			if voucher_area then nodes[#nodes + 1] = voucher_area end
		end
	end
	if jokers then
		local joker_area = build_joker_card_area(jokers, 4, 0.6)
		if joker_area then nodes[#nodes + 1] = joker_area end
	end
	return nodes
end

local function build_spending_cell(r)
	local shop_nodes = {}
	local ps = r.player_stats
	local has_rerolls = ps and (ps.reroll_count or ps.reroll_cost_total)
	if r.shop_spending or has_rerolls then
		shop_nodes[#shop_nodes + 1] = section_header("Your Spending")
		if ps and ps.reroll_count then
			shop_nodes[#shop_nodes + 1] = text_row("Rerolls:", tostring(ps.reroll_count), 0.28)
		end
		if ps and ps.reroll_cost_total then
			shop_nodes[#shop_nodes + 1] = text_row("Reroll $:", "$" .. tostring(ps.reroll_cost_total), 0.28)
		end
		if r.shop_spending then
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
			shop_nodes[#shop_nodes + 1] = text_row("Shop $:", "$" .. tostring(total), 0.28)
			shop_nodes[#shop_nodes + 1] = {
				n = G.UIT.R,
				config = { align = "cl", padding = 0.02, maxw = 6 },
				nodes = {
					{
						n = G.UIT.T,
						config = { text = table.concat(parts, "  "), scale = 0.24, colour = G.C.UI.TEXT_INACTIVE },
					},
				},
			}
		end
	end
	return shop_nodes
end

local function build_failed_rounds_cell(r)
	local failed_nodes = {}
	if r.failed_rounds and #r.failed_rounds > 0 then
		local fr_parts = {}
		for _, a in ipairs(r.failed_rounds) do
			fr_parts[#fr_parts + 1] = "A" .. tostring(a)
		end
		failed_nodes[#failed_nodes + 1] = section_header("Failed Rounds")
		failed_nodes[#failed_nodes + 1] =
			text_row("Antes:", table.concat(fr_parts, ", "), 0.28, G.C.UI.TEXT_INACTIVE, G.C.RED)
	end
	return failed_nodes
end

local function build_action_buttons(r, flipped)
	-- Playing-as flip button + Load button (spans full width)
	local playing_as = flipped
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

	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.08 },
		nodes = action_nodes,
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

	local header_nodes = build_header_row(r)
	local match_info_band = build_match_info_band(r)
	local ante_nodes = build_ante_breakdown(r)
	local your_nodes = build_side_nodes(r.player_stats, r.player_jokers, r.player_name or "You")
	local opp_nodes = build_side_nodes(r.nemesis_stats, r.nemesis_jokers, r.nemesis_name or "Opponent")
	local shop_nodes = build_spending_cell(r)
	local failed_nodes = build_failed_rounds_cell(r)
	local load_button = build_action_buttons(r, _preview_flipped)

	-- Three vertically stacked bands: meta (just Match Info), duel, footer
	local meta_band = {
		n = G.UIT.R,
		config = { align = "tm", padding = 0.02 },
		nodes = { match_info_band },
	}

	local duel_band = {
		n = G.UIT.R,
		config = { align = "tm", padding = 0.02 },
		nodes = {
			{ n = G.UIT.C, config = { align = "tm", padding = 0.05, minw = 5 }, nodes = your_nodes },
			{ n = G.UIT.C, config = { align = "tm", padding = 0.05, minw = 5 }, nodes = opp_nodes },
		},
	}

	-- Ante Breakdown + Your Spending are both "match flow / your $ over time" data
	local footer_band = {
		n = G.UIT.R,
		config = { align = "tm", padding = 0.02 },
		nodes = {
			{ n = G.UIT.C, config = { align = "tm", padding = 0.05, minw = 4 }, nodes = ante_nodes },
			{ n = G.UIT.C, config = { align = "tm", padding = 0.05, minw = 4 }, nodes = shop_nodes },
			{ n = G.UIT.C, config = { align = "tm", padding = 0.05, minw = 2 }, nodes = failed_nodes },
		},
	}

	local body_row = {
		n = G.UIT.R,
		config = { align = "tm", padding = 0.02 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "tm", padding = 0.02 },
				nodes = { meta_band, duel_band, footer_band },
			},
		},
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

local function load_all_replays()
	local all = MP.GHOST.load_folder_replays()
	local seen = {}
	for _, r in ipairs(all) do
		seen[(r._filename or "") .. ":" .. (r._game_index or 0)] = true
	end
	for _, r in ipairs(MP.GHOST.load_lovely_log_replays(10)) do
		local key = (r._filename or "") .. ":" .. (r._game_index or 0)
		if not seen[key] then
			seen[key] = true
			all[#all + 1] = r
		end
	end

	table.sort(all, function(a, b)
		return (a.timestamp or 0) > (b.timestamp or 0)
	end)

	return all
end

local function build_replay_list(replays, preview_idx)
	local replay_nodes = {}

	if #replays == 0 then
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
						text = "Play a match, or place .log/.json in replays/",
						scale = 0.28,
						colour = G.C.UI.TEXT_INACTIVE,
					},
				},
			},
		}
	else
		local last_filename = nil
		for i, r in ipairs(replays) do
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
			local is_selected = (preview_idx == i)
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

	return replay_nodes
end

function G.UIDEF.ghost_replay_picker()
	local all = load_all_replays()
	_picker_replays = all

	local replay_nodes = build_replay_list(all, _preview_idx)

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
						config = {
							align = "tm",
							padding = 0.15,
							r = 0.1,
							colour = G.C.BLACK,
							maxw = 16.5,
							maxh = 8,
						},
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
