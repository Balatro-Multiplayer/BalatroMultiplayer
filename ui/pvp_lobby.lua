-- Lobby view, copied from the Speedrunning mod's ui/lobby (buttons/view/controls/
-- code/ready) and rewired to PvP. Private lobbies: host gets START + LOBBY OPTIONS,
-- guests get a READY toggle; both get deck/code panels + LEAVE. Matchmaking lobbies:
-- a status panel; the run auto-starts once all clients are ready.

MP.lobby = MP.lobby or { buttons = {} }
MP.lobby.ready = MP.lobby.ready or MPAPI.ReadyTracker()
-- Unanimous seed-change vote tracker (pause menu -> pvp_seed_vote); see pvp_api/run_actions.lua.
MP.lobby.seed_votes = MP.lobby.seed_votes or MPAPI.VoteTracker()

function MP.get_lobby_kind()
	return MP._pvp_kind
end

function MP.is_matchmaking()
	return MP._pvp_kind == MP.LobbyKind.RANKED or MP._pvp_kind == MP.LobbyKind.CASUAL
end

-- ── ready system (copied from Speed's ready.lua) ─────────────────────────────
function MP.signal_ready(ready)
	local lobby = MP.lobby.ref
	if not lobby then
		return
	end
	lobby:action(MPAPI.ActionTypes["pvp_player_ready"]):broadcast({ ready = ready and true or false })
end

function MP.start_ready_resync()
	if not MP.is_matchmaking() then
		return
	end
	MP._ready_resync_stop = MPAPI.ready_resync({
		send = function()
			MP.signal_ready(true)
		end,
		should_continue = function()
			return MP.lobby.ref ~= nil and MP.is_matchmaking()
		end,
	})
end

function MP.stop_ready_resync()
	if MP._ready_resync_stop then
		MP._ready_resync_stop()
		MP._ready_resync_stop = nil
	end
end

function MP.reset_ready_state()
	local b = MP.lobby.buttons
	MP.lobby.ready:reset()
	MP.lobby.local_ready = false
	MP.lobby.start_broadcasted = false
	if b.ready_args then
		b.ready_args.label = { localize("b_ready_cap") }
		b.ready_args.colour = G.C.GREEN
	end
	if b.ready then
		b.ready:update()
	end
	if b.start_game then
		b.start_game:update()
	end
end

-- Host-only: record a player's ready state and react.
function MP.set_player_ready(player_id, ready)
	local lobby = MP.lobby.ref
	if not lobby or not lobby.is_host then
		return
	end
	MP.lobby.ready:set(player_id, ready)
	if MP.is_matchmaking() then
		MP.maybe_autostart()
	elseif MP.lobby.buttons.start_game then
		MP.lobby.buttons.start_game:update()
	end
end

-- Host-only matchmaking auto-start: once all clients are ready, start exactly once.
function MP.maybe_autostart()
	local L = MP.lobby
	if L.start_broadcasted or not L.ref or not L.ref.is_host or not MP.is_matchmaking() then
		return
	end
	if #L.ref:get_players() < 2 or not L.ready:all_ready() then
		return
	end
	L.start_broadcasted = true
	MP.pvp_start_match()
end

G.FUNCS.mp_pvp_toggle_ready = function()
	local L = MP.lobby
	L.local_ready = not L.local_ready
	if L.buttons.ready_args and L.buttons.ready then
		L.buttons.ready_args.label = { L.local_ready and localize("b_unready_cap") or localize("b_ready_cap") }
		L.buttons.ready_args.colour = L.local_ready and G.C.ORANGE or G.C.GREEN
		L.buttons.ready:update()
	end
	MP.signal_ready(L.local_ready)
end

-- ── code panel handlers (copied from Speed's code.lua) ───────────────────────
G.FUNCS.mp_pvp_view_code = function(e)
	local text_config = e.children[1].children[1].config
	local code = MP.lobby.ref and MP.lobby.ref.code
	if not code then
		return
	end
	if text_config.text ~= code then
		e.config.colour = G.C.ETERNAL
		text_config.text = code
	else
		e.config.colour = G.C.GREEN
		text_config.text = localize("b_view_code_cap")
	end
	e.UIBox:recalculate()
end

G.FUNCS.mp_pvp_copy_code = function(e)
	local code = MP.lobby.ref and MP.lobby.ref.code
	if not code then
		return
	end
	if love.system and love.system.setClipboardText then
		love.system.setClipboardText(code)
	end
	local text_config = e.children[1].children[1].config
	e.config.colour = G.C.ETERNAL
	text_config.text = localize("k_copied_cap")
	e.UIBox:recalculate()
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 1.5,
		func = function()
			e.config.colour = G.C.PURPLE
			text_config.text = localize("b_copy_code_cap")
			e.UIBox:recalculate()
			return true
		end,
	}))
end

G.FUNCS.mp_pvp_start_game = function()
	MP.pvp_start_match()
end

G.FUNCS.mp_pvp_leave_lobby = function()
	local function do_leave()
		MP.pvp_leave_lobby()
		MPAPI.refresh_current_view()
	end
	-- Mid-game (e.g. from the end screen) confirm before tearing down the run; from the
	-- main-menu lobby view leave immediately.
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		G.FUNCS.confirm_selection(do_leave)
	else
		do_leave()
	end
end

G.FUNCS.mp_pvp_lobby_options = function() end -- placeholder (Phase 6+)

-- ── lobby buttons (copied from Speed's buttons.lua) ──────────────────────────
function MP.lobby.create_buttons()
	local L = MP.lobby
	if L.buttons_initialized then
		return
	end
	local b = L.buttons

	b.start_game = MPAPI.disableable_button({
		id = "mp_pvp_start_game",
		button = "mp_pvp_start_game",
		colour = G.C.BLUE,
		minw = 3.65,
		minh = 1.55,
		label = localize("b_start_game_cap"),
		scale = 0.7,
		enabled = function()
			local lobby = L.ref
			if not lobby or not lobby.is_host then
				return false
			end
			local players = lobby:get_players()
			if #players < 2 then
				return false
			end
			for _, p in ipairs(players) do
				if p.id ~= lobby.player_id and not L.ready:is_ready(p.id) then
					return false
				end
			end
			return true
		end,
	})
	b.ready_args = {
		id = "mp_pvp_ready",
		button = "mp_pvp_toggle_ready",
		colour = G.C.GREEN,
		minw = 3.65,
		minh = 1.55,
		label = { localize("b_ready_cap") },
		scale = 0.7,
		col = true,
		enabled = true,
	}
	b.ready = MPAPI.disableable_button(b.ready_args)
	b.lobby_options = MPAPI.disableable_button({
		id = "mp_pvp_lobby_options",
		button = "mp_pvp_lobby_options",
		colour = G.C.ORANGE,
		minw = 2.65,
		minh = 1.35,
		label = localize("b_lobby_options_cap"),
		scale = 0.6,
		col = true,
		enabled = false,
	})
	b.view_code = MPAPI.disableable_button({
		id = "mp_pvp_view_code",
		button = "mp_pvp_view_code",
		colour = G.C.GREEN,
		minw = 3.65,
		minh = 0.6,
		label = { localize("b_view_code_cap") },
		scale = 0.45,
		enabled = true,
	})
	b.copy_code = MPAPI.disableable_button({
		id = "mp_pvp_copy_code",
		button = "mp_pvp_copy_code",
		colour = G.C.PURPLE,
		minw = 3.65,
		minh = 0.6,
		label = { localize("b_copy_code_cap") },
		scale = 0.45,
		enabled = true,
	})
	b.leave = MPAPI.disableable_button({
		id = "mp_pvp_leave_lobby",
		button = "mp_pvp_leave_lobby",
		colour = G.C.RED,
		minw = 3.65,
		minh = 1.55,
		label = localize("b_leave_lobby_cap"),
		scale = 0.7,
		col = true,
		enabled = true,
	})

	L.buttons_initialized = true
end

-- ── controls (copied from Speed's controls.lua) ──────────────────────────────
local function code_panel()
	local b = MP.lobby.buttons
	return {
		n = G.UIT.C,
		config = { align = "cm", padding = 0.1, r = 0.2, colour = G.C.BLACK },
		nodes = {
			{ n = G.UIT.C, config = { align = "cm", maxh = 1.4 }, nodes = {
				{ n = G.UIT.T, config = { text = localize("k_lobby_code_cap"), scale = 0.45, colour = G.C.UI.TEXT_LIGHT, vert = true, maxh = 1.4 } },
			} },
			{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = {
				{ n = G.UIT.R, config = { align = "cm" }, nodes = { b.view_code.node } },
				{ n = G.UIT.R, config = { align = "cm" }, nodes = { b.copy_code.node } },
			} },
		},
	}
end

-- Read-only deck label (host deck picker is a later addition).
local function deck_panel()
	local lobby = MP.lobby.ref
	local meta = (lobby and lobby:get_metadata()) or {}
	local deck_name = meta.deck or "Red Deck"
	return { n = G.UIT.C, config = { align = "cm", padding = 0.05, r = 0.1, colour = G.C.L_BLACK, minw = 2.65, minh = 1.35, emboss = 0.05 }, nodes = {
		{ n = G.UIT.R, config = { align = "cm" }, nodes = { { n = G.UIT.T, config = { text = "Deck", scale = 0.32, colour = G.C.UI.TEXT_INACTIVE } } } },
		{ n = G.UIT.R, config = { align = "cm" }, nodes = { { n = G.UIT.T, config = { text = deck_name, scale = 0.42, colour = G.C.UI.TEXT_LIGHT, shadow = true } } } },
	} }
end

local function build_private_controls()
	local b = MP.lobby.buttons
	local lobby = MP.lobby.ref
	local row_nodes = {}
	if lobby and lobby.is_host then
		row_nodes[#row_nodes + 1] = b.start_game.node
		row_nodes[#row_nodes + 1] = b.lobby_options.node
	else
		row_nodes[#row_nodes + 1] = b.ready.node
	end
	row_nodes[#row_nodes + 1] = deck_panel()
	row_nodes[#row_nodes + 1] = code_panel()
	row_nodes[#row_nodes + 1] = b.leave.node

	return {
		n = G.UIT.C,
		config = { align = "cm", padding = 0.1, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK, mid = true },
		nodes = { { n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = row_nodes } },
	}
end

-- Reactive status panel: the deck ban-pick draft while one is active, otherwise the
-- waiting line. Held as one ui_element so the draft refreshes in place.
local _mm_status_el = nil
local function build_mm_status()
	if MPAPI.BanPick.is_active() then
		return { nodes = MPAPI.BanPick.build_contents() }
	end
	return { nodes = {
		{ n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
			{ n = G.UIT.T, config = { id = "mp_pvp_mm_status", text = localize("k_waiting_for_players"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
		} },
	} }
end

local function build_matchmaking_controls()
	_mm_status_el = _mm_status_el or MPAPI.ui_element(build_mm_status)
	return {
		n = G.UIT.C,
		config = { align = "cm", padding = 0.2, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK, mid = true },
		nodes = { _mm_status_el.node },
	}
end

function MP.lobby.refresh_mm_status()
	if _mm_status_el then
		_mm_status_el:update()
	end
end

function MP.lobby.build_controls()
	if MP.is_matchmaking() then
		return build_matchmaking_controls()
	end
	return build_private_controls()
end

-- ── lobby view (copied from Speed's view.lua) ────────────────────────────────
MP.build_in_lobby_ui = function()
	local L = MP.lobby
	local lobby = MPAPI.get_current_lobby()

	if lobby and not L.ui_ref then
		L.ref = lobby
		L.ui_ref = MPAPI.create_lobby_ui(lobby)
	end
	if not L.ui_ref then
		return MP.build_pre_lobby_ui()
	end

	L.create_buttons()
	MPAPI.set_logo_offset(-10, true)

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm" },
				nodes = {
					{ n = G.UIT.R, config = { align = "cm", padding = 0.1, mid = true }, nodes = { L.ui_ref.node } },
					{ n = G.UIT.R, config = { minh = 0.2 } },
					{ n = G.UIT.R, config = { align = "cm" }, nodes = { L.build_controls() } },
				},
			},
		},
	}
end
