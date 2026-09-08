-- The Find Game pillar page (MPAPI page pvp_find_game), built on MPAPI's generic pillar-row
-- layout (BalatroMultiplayerAPI/api/ui_pillar_row.lua) -- same shape SPDRN's gamemode-select
-- page uses (BalatroMultiplayerSpeed/ui/main_menu/game_select.lua). Replaces the old two-step
-- Find Game -> Ranked/Casual -> ruleset grid overlay (pvp_api/queue.lua's now-removed
-- mp_pvp_find_game_ranked/_casual).
--
-- Ranked (5 pillars) and Casual (4 pillars) are two separate screens now, not one 9-pillar row
-- -- too many to read comfortably on one page (2026-09-08 user feedback on the first pass).
-- self.params.category (set by the tab buttons below, read in core.lua's page registration)
-- picks which list PVP.build_find_game_ui builds; the tab row at the top of the page switches
-- between them via a normal MPAPI.pages.show() re-navigation (same page, new params), same
-- mechanism SPDRN's practice/create_lobby/find_game intents already use -- not a separate
-- widget/mechanism of its own.
--
-- WIP: chip art is a single placeholder frame reused across every pillar (no per-mode art
-- exists yet), and MLBa Ranked has no matchmaking gamemode-key registered in PVP.PVP_GAMEMODES
-- yet, so its SELECT button is disabled rather than wired to a queue call that would fail.
-- Everything else routes straight to the existing mp_pvp_queue_ranked_*/mp_pvp_queue_casual_*
-- handlers (pvp_api/queue.lua), unchanged.

-- No new atlas registered here -- reuses objects/blinds/nemesis.lua's already-registered
-- "player_blind_chip" (G.ANIMATION_ATLAS['mp_player_blind_chip'], SMODS auto-prefixes the key)
-- as a generic placeholder chip for every pillar, rather than adding a second atlas just to
-- have *something* in the icon slot. core.lua's load_mp_dir("ui", true) call actually runs
-- BEFORE load_mp_dir("objects/blinds"), but that only orders top-level (file-load-time) code --
-- build_chip_sprite below is a function body, only called once the page is actually built
-- (well after every load_mp_dir call has finished, since that requires a live game/player
-- input), so the atlas is always registered by the time this runs.
local PLACEHOLDER_CHIP_ROW = 0

-- uses_order reflects PVP.LOBBY.config.the_order as core.lua's reset_lobby_config default
-- (true) and each ruleset's own force_lobby_options override actually resolve it, not a
-- hand-picked guess: rulesets/majorleague.lua explicitly forces false; chocolate_ranked's
-- "ranked" layer (layers/ranked.lua) explicitly forces true (redundant with the default, but
-- explicit); strawberry/smallworld have no override, so they inherit the true default.
-- KNOWN MISMATCH: rulesets/vanilla.lua has no force_lobby_options at all, so it also inherits
-- the true default -- Vanilla Ranked is listed here as false (no Order) per the content this
-- was requested with, but as of this commit the ruleset itself doesn't actually turn the_order
-- off. Flagged, not silently "fixed" -- changing vanilla.lua's actual lobby behavior wasn't
-- part of this visual pass.
--
-- Ranked: always exactly 2 players (matchmaking.service.ts's forfeit/ELO resolution is
-- hardcoded for a 2-player result) -- see pvp_api/queue.lua's own comment on this. MLBa has no
-- gamemode_key of its own in PVP.PVP_GAMEMODES yet (only a ruleset, rulesets/majorleague.lua),
-- so it has no queue_button -- build_select below disables its SELECT rather than wiring a
-- queue call that would silently misresolve.
-- desc lines are hand-wrapped to roughly Nemesis's own second line ("Nemesis every ante", 19
-- chars) rather than left as whatever length the source description happened to be -- a couple
-- (Battle Royale, Teams) were 25+ chars per line before this and visibly overran their card
-- (2026-09-08 user feedback). No code-level truncation/wrapping added; this is just each string
-- rewritten by hand to fit.
local RANKED_MODES = {
	{ key = "pvp_vanilla", name = { "Vanilla", "Ranked" },
		desc = { "Normal Balatro", "with PvP blinds" }, uses_order = false,
		queue_button = "mp_pvp_queue_ranked_vanilla", colour = G.C.GREEN },
	{ key = "pvp_chocolate", name = { "Chocolate", "Ranked" },
		desc = { "Minor balance", "changes for MP" }, uses_order = true,
		queue_button = "mp_pvp_queue_ranked_chocolate", colour = G.C.BLUE },
	{ key = "pvp_strawberry", name = { "Strawberry", "Ranked" },
		desc = { "Standardized and", "balanced for MP" }, uses_order = true,
		queue_button = "mp_pvp_queue_ranked_strawberry", colour = G.C.PURPLE },
	{ key = "pvp_majorleague", name = { "MLBa", "Ranked" },
		desc = { "Follows the MLBa", "ruleset" }, uses_order = false,
		queue_button = nil, colour = G.C.BLACK },
	{ key = "pvp_smallworld_ranked", name = { "Smallworld", "Ranked" },
		desc = { "75% of cards are", "banned at random" }, uses_order = true,
		queue_button = "mp_pvp_queue_ranked_smallworld", colour = G.C.RED },
}

-- Casual: 2-16 players. "Nemesis" here is the shared-default-ruleset casual queue (Chocolate) --
-- see pvp_api/queue.lua's own §17.4 comment: casual Nemesis was always just Chocolate under a
-- different label, never a fifth independent ruleset choice. Manhunt has an existing casual
-- queue handler (mp_pvp_queue_casual_manhunt) but wasn't in the requested pillar set, so it's
-- left reachable only via Create Lobby for now, not duplicated here. All four resolve to a
-- ruleset with no the_order override (Chocolate's "ranked" layer forces it true regardless of
-- matchmaking kind; Smallworld inherits the true default), so all four use The Order.
local CASUAL_MODES = {
	{ key = "pvp_nemesis", name = "Nemesis",
		desc = { "Face a different", "Nemesis every ante" }, uses_order = true,
		queue_button = "mp_pvp_queue_casual_chocolate", colour = G.C.BLUE },
	{ key = "pvp_royale", name = { "Battle", "Royale" },
		desc = { "Free for all;", "bottom half lose" }, uses_order = true,
		queue_button = "mp_pvp_queue_casual_royale", colour = G.C.PURPLE },
	{ key = "pvp_teams", name = "Teams",
		desc = { "Team vs team;", "best score wins" }, uses_order = true,
		queue_button = "mp_pvp_queue_casual_teams", colour = G.C.GREEN },
	{ key = "pvp_smallworld_casual", name = "Smallworld",
		desc = { "75% of cards are", "banned at random" }, uses_order = true,
		queue_button = "mp_pvp_queue_casual_smallworld", colour = G.C.RED },
}

-- Plain Sprite, not AnimatedSprite -- see SPDRN's game_select.lua build_chip_sprite for why
-- (AnimatedSprite free-runs its column animation; this icon is meant to sit static).
local function build_chip_sprite()
	return Sprite(0, 0, 1.1, 1.1, G.ANIMATION_ATLAS["mp_player_blind_chip"], { x = PLACEHOLDER_CHIP_ROW, y = 0 })
end

local function build_select(mode)
	return MPAPI.ui_pillar_select_button({
		label = "QUEUE",
		button = mode.queue_button,
		disabled = mode.queue_button == nil,
	})
end

local function build_stat_box(players)
	return MPAPI.ui_pillar_stat_box({ label = "Players", value = players, value_colour = G.C.MONEY })
end

-- Mirrors SPDRN's game_select.lua build_order_card exactly (same the_order_open button,
-- MPAPI's own G.FUNCS handler, ui/the_order.lua) -- reused as-is, not reimplemented.
local function build_order_card()
	return MPAPI.ui_embossed_box({ minw = 2.4, nodes = {
		{ n = G.UIT.R, config = { align = "cm" }, nodes = {
			{ n = G.UIT.C, config = {
				align = "cm", minw = 2.2, minh = 0.6, padding = 0.06, r = 0.1,
				colour = G.C.BLUE, shadow = true, hover = true, one_press = true, button = "the_order_open",
			}, nodes = {
				{ n = G.UIT.R, config = { align = "cm" }, nodes = {
					{ n = G.UIT.T, config = { text = "Uses", scale = 0.32, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
				{ n = G.UIT.R, config = { align = "cm" }, nodes = {
					{ n = G.UIT.T, config = { text = "The Order", scale = 0.32, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				} },
			} },
		} },
	} })
end

local function build_items(modes, players)
	local items = {}
	for _, mode in ipairs(modes) do
		items[#items + 1] = {
			id = mode.key,
			icon = build_chip_sprite(),
			select = build_select(mode),
			name_plate = MPAPI.ui_pillar_name_plate({
				lines = mode.name,
				bg_colour = mix_colours(mode.colour, G.C.BLACK, 0.3),
				outline_colour = mode.colour,
			}),
			-- minh reserves room for 3 lines regardless of how many an individual mode's desc
			-- actually has (every current one is 2) -- ui_embossed_box centers its content
			-- ('cm' align) within whatever minh it's given, same as the name plate above, so
			-- this is what makes a 2-line description sit centered with breathing room instead
			-- of the box just shrinking to hug the text (2026-09-08 user feedback).
			description = MPAPI.ui_pillar_description_box({ lines = mode.desc, minh = 1.3 }),
			stat_box = build_stat_box(players),
			extra = mode.uses_order and build_order_card() or nil,
		}
	end
	return items
end

local TABS = {
	{ key = "ranked", label = "RANKED", colour = G.C.RED },
	{ key = "casual", label = "CASUAL", colour = G.C.BLUE },
}

local function build_tab_row(category)
	local nodes = {}
	for _, tab in ipairs(TABS) do
		local is_active = tab.key == category
		nodes[#nodes + 1] = { n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
			UIBox_button({
				button = "mp_pvp_find_game_tab",
				ref_table = { category = tab.key },
				label = { tab.label },
				colour = is_active and tab.colour or G.C.UI.BACKGROUND_INACTIVE,
				minw = 3.0,
				minh = 0.6,
				scale = 0.4,
			}),
		} }
	end
	return { n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = nodes }
end

-- Re-navigates to this same page key with different params (category), same mechanism
-- SPDRN's practice/create_lobby/find_game intents already use to switch content on
-- spdrn_game_select -- verified live, repeatedly, in both directions with no stale content
-- left behind. (An earlier version of this handler appeared to leave stale pillar nodes behind
-- when hot-patched via cctl eval mid-session for testing -- did not reproduce at all across
-- several full Ranked<->Casual cycles on a freshly launched instance, so that was very likely
-- an artifact of repeatedly redefining this function on one long-running process while
-- iterating, not a real bug in this code path.)
G.FUNCS.mp_pvp_find_game_tab = function(e)
	local rt = e.config.ref_table
	if not rt or not rt.category then
		return
	end
	MPAPI.pages.show("pvp_find_game", { category = rt.category })
end

-- Builds this page's full definition (tab row + pillar row) for the given category ("ranked" or
-- "casual", default "ranked"). The caller (pvp_find_game's MPAPI.Page registration, core.lua)
-- owns the returned pillar_row controller for this page's lifetime: call :dispose() from the
-- page's own dispose() hook so the tracked chip icons get :remove()'d -- see
-- api/ui_pillar_row.lua's header comment for why that's required.
function PVP.build_find_game_ui(category)
	category = category or "ranked"
	local modes, players = RANKED_MODES, "2"
	if category == "casual" then
		modes, players = CASUAL_MODES, "2-16"
	end

	local pillar_row = MPAPI.ui_pillar_row({ items = build_items(modes, players) })
	local definition = {
		n = G.UIT.ROOT,
		config = { align = "tm", colour = G.C.CLEAR },
		nodes = { build_tab_row(category), pillar_row.row_node },
	}
	return { definition = definition, dispose = function(self) pillar_row:dispose() end }
end
