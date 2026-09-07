-- The Find Game pillar page (MPAPI page pvp_find_game), built on MPAPI's generic pillar-row
-- layout (BalatroMultiplayerAPI/api/ui_pillar_row.lua) -- same shape SPDRN's gamemode-select
-- page uses (BalatroMultiplayerSpeed/ui/main_menu/game_select.lua). Replaces the old two-step
-- Find Game -> Ranked/Casual -> ruleset grid overlay (pvp_api/queue.lua's now-removed
-- mp_pvp_find_game_ranked/_casual) with a single screen showing every queueable mode as a
-- pillar, grouped Ranked-then-Casual via each item's `group`.
--
-- WIP per user request 2026-09-08: visual layout pass only. Chip art is a single placeholder
-- frame reused across every pillar (no per-mode art exists yet), and MLBa Ranked has no
-- matchmaking gamemode-key registered in PVP.PVP_GAMEMODES yet, so its SELECT button is
-- disabled rather than wired to a queue call that would fail. Everything else routes straight
-- to the existing mp_pvp_queue_ranked_*/mp_pvp_queue_casual_* handlers (pvp_api/queue.lua),
-- unchanged.
-- No new atlas registered here -- reuses objects/blinds/nemesis.lua's already-registered
-- "player_blind_chip" (G.ANIMATION_ATLAS['mp_player_blind_chip'], SMODS auto-prefixes the key)
-- as a generic placeholder chip for every pillar, rather than adding a second atlas just to
-- have *something* in the icon slot. core.lua's load_mp_dir("ui", true) call actually runs
-- BEFORE load_mp_dir("objects/blinds"), but that only orders top-level (file-load-time) code --
-- build_chip_sprite below is a function body, only called once the page is actually built
-- (well after every load_mp_dir call has finished, since that requires a live game/player
-- input), so the atlas is always registered by the time this runs.
local PLACEHOLDER_CHIP_ROW = 0

-- Ranked: always exactly 2 players (matchmaking.service.ts's forfeit/ELO resolution is
-- hardcoded for a 2-player result) -- see pvp_api/queue.lua's own comment on this. MLBa has no
-- gamemode_key of its own in PVP.PVP_GAMEMODES yet (only a ruleset, rulesets/majorleague.lua),
-- so it has no queue_button -- build_select below disables its SELECT rather than wiring a
-- queue call that would silently misresolve.
local RANKED_MODES = {
	{ key = "pvp_vanilla", name = { "Vanilla", "Ranked" },
		desc = { "Normal Balatro with", "PvP blinds" }, caption = "No Order button",
		queue_button = "mp_pvp_queue_ranked_vanilla", colour = G.C.GREEN },
	{ key = "pvp_chocolate", name = { "Chocolate", "Ranked" },
		desc = { "Minor MP Balance", "Changes" }, caption = "Uses The Order",
		queue_button = "mp_pvp_queue_ranked_chocolate", colour = G.C.BLUE },
	{ key = "pvp_strawberry", name = { "Strawberry", "Ranked" },
		desc = { "Standardized and", "Balanced for MP" }, caption = "Uses The Order",
		queue_button = "mp_pvp_queue_ranked_strawberry", colour = G.C.PURPLE },
	{ key = "pvp_majorleague", name = { "MLBa", "Ranked" },
		desc = { "Follows the MLBa", "Rules" }, caption = "No Order button",
		queue_button = nil, colour = G.C.BLACK },
	{ key = "pvp_smallworld_ranked", name = { "Smallworld", "Ranked" },
		desc = { "75% of cards are", "banned at random" },
		queue_button = "mp_pvp_queue_ranked_smallworld", colour = G.C.RED },
}

-- Casual: 2-16 players. "Nemesis" here is the shared-default-ruleset casual queue (Chocolate) --
-- see pvp_api/queue.lua's own §17.4 comment: casual Nemesis was always just Chocolate under a
-- different label, never a fifth independent ruleset choice. Manhunt has an existing casual
-- queue handler (mp_pvp_queue_casual_manhunt) but wasn't in the requested pillar set, so it's
-- left reachable only via Create Lobby for now, not duplicated here.
local CASUAL_MODES = {
	{ key = "pvp_nemesis", name = "Nemesis",
		desc = { "Face a different", "Nemesis every ante" },
		queue_button = "mp_pvp_queue_casual_chocolate", colour = G.C.BLUE },
	{ key = "pvp_royale", name = { "Battle", "Royale" },
		desc = { "Everyone for themselves,", "bottom half of scores lose" },
		queue_button = "mp_pvp_queue_casual_royale", colour = G.C.PURPLE },
	{ key = "pvp_teams", name = "Teams",
		desc = { "One team against another,", "best collective score wins" },
		queue_button = "mp_pvp_queue_casual_teams", colour = G.C.GREEN },
	{ key = "pvp_smallworld_casual", name = "Smallworld",
		desc = { "75% of cards are", "banned at random" },
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

local function build_items(modes, group, players)
	local items = {}
	for _, mode in ipairs(modes) do
		items[#items + 1] = {
			id = mode.key,
			group = group,
			icon = build_chip_sprite(),
			select = build_select(mode),
			name_plate = MPAPI.ui_pillar_name_plate({
				lines = mode.name,
				bg_colour = mix_colours(mode.colour, G.C.BLACK, 0.3),
				outline_colour = mode.colour,
			}),
			description = MPAPI.ui_pillar_description_box({ lines = mode.desc, caption = mode.caption }),
			stat_box = build_stat_box(players),
		}
	end
	return items
end

-- Builds the pillar-row controller (MPAPI.ui_pillar_row's return value: {definition, row_node,
-- dispose}). The caller (pvp_find_game's MPAPI.Page registration, core.lua) owns the controller
-- for this page's lifetime: hand `.definition` to build(), and call `:dispose()` from the page's
-- own dispose() hook so the tracked chip icons get :remove()'d -- see api/ui_pillar_row.lua's
-- header comment for why that's required.
function PVP.build_find_game_ui()
	local items = {}
	for _, item in ipairs(build_items(RANKED_MODES, "ranked", "2")) do
		items[#items + 1] = item
	end
	for _, item in ipairs(build_items(CASUAL_MODES, "casual", "2-16")) do
		items[#items + 1] = item
	end
	return MPAPI.ui_pillar_row({ items = items, group_gap = 0.9 })
end
