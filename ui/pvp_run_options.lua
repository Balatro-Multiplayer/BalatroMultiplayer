-- Custom pause/options screen for an active PvP run (mirrors Speed's ui/run_options.lua).
-- Shows Settings + Seed Change (unanimous vote, gated) + Forfeit. Wired via
-- prevent_pause + options_builder in core.lua's register_mod; the API renders this for
-- the in-run pause overlay and leaves the non-run (main-menu) options box vanilla.

G.FUNCS.mp_pvp_seed_change = function()
	G.FUNCS.exit_overlay_menu()
	-- A unanimous vote restarts the match on a fresh seed (see pvp_seed_vote action).
	MP.cast_seed_vote()
end

G.FUNCS.mp_pvp_forfeit = function()
	G.FUNCS.exit_overlay_menu()
	MP.pvp_forfeit()
end

-- Seed change is only offered for the first few minutes of a run.
MP.SEED_CHANGE_WINDOW = 300

MP.create_run_options = function()
	-- Each button is its own row inside one column so they stack vertically.
	local rows = {}
	local function add_row(node)
		rows[#rows + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.08 }, nodes = { node } }
	end

	add_row(UIBox_button({ button = "settings", label = { localize("b_settings") }, minw = 5, focus_args = { snap_to = true } }))

	-- Seed Change visibility/enabled state:
	--   * hidden entirely when the gamemode sets seed_change_allowed = false
	--   * shown but disabled once SEED_CHANGE_WINDOW seconds have elapsed
	local lobby = MPAPI.get_current_lobby()
	local meta = lobby and lobby:get_metadata()
	local gm = meta and meta.gamemode and MPAPI.GameModes[meta.gamemode]
	if not gm or gm.seed_change_allowed ~= false then
		local within_window = MP._run_started_at ~= nil
			and (love.timer.getTime() - MP._run_started_at) < MP.SEED_CHANGE_WINDOW
		add_row(MPAPI.disableable_button({
			button = "mp_pvp_seed_change",
			label = { "Seed Change" },
			colour = G.C.BLUE,
			minw = 5,
			enabled = within_window,
		}).node)
	end

	add_row(UIBox_button({ button = "mp_pvp_forfeit", label = { "Forfeit" }, minw = 5, colour = G.C.RED }))

	return create_UIBox_generic_options({
		contents = {
			{ n = G.UIT.C, config = { align = "cm" }, nodes = rows },
		},
	})
end
