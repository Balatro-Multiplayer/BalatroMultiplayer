-- ============================================================================
-- Custom ruleset editor — bespoke tab in ruleset selection (FIRST CUT)
-- ============================================================================
-- Pure UI for now: pick a content set, toggle modifier layers, nudge a couple
-- scalars, and ban jokers by browsing the vanilla Collection. Everything lives
-- on an in-memory draft (MP.CUSTOM.draft). No persistence, no wire, no inject
-- yet — the point is to *see* the ban picker + knobs working.
--
-- Deliberately does NOT use loc keys: every label is a raw string so we can
-- iterate on the layout without touching localization.
-- ============================================================================

MP.CUSTOM = MP.CUSTOM or {}

-- Content sets re-rework the same cards, so they're mutually exclusive (radio).
local CONTENT_SETS = { "none", "standard", "experimental", "classic" }
-- Modifiers are edited inline in the right panel via the shared MUTATORS wall
-- (MP.UI.build_mutators_wall et al, from _modifiers_overlay.lua). They drive the
-- runtime MP.MODIFIERS list. A future save would snapshot MP.MODIFIERS into the draft.
local LIVES_OPTIONS = { 1, 2, 3, 4, 5, 6, 7, 8 }
local PVP_START_OPTIONS = { 1, 2, 3, 4, 5, 6, 7, 8 }

-- Option cycles render the chosen value as text-node text, which wants strings.
local function as_strings(nums)
	local out = {}
	for i, n in ipairs(nums) do
		out[i] = tostring(n)
	end
	return out
end
local LIVES_LABELS = as_strings(LIVES_OPTIONS)
local PVP_START_LABELS = as_strings(PVP_START_OPTIONS)

-- ---------------------------------------------------------------------------
-- Draft model (in-memory; this IS the eventual disk/wire schema)
-- ---------------------------------------------------------------------------
function MP.CUSTOM.new_draft()
	return {
		name = "My Ruleset",
		base = "standard", -- one of CONTENT_SETS
		modifiers = {}, -- snapshot of MP.MODIFIERS at save time (edited via the modifiers overlay)
		banned_jokers = {},
		banned_consumables = {},
		banned_vouchers = {},
		scalars = { starting_lives = 4, pvp_start_round = 2 },
	}
end

-- nil when not editing; the collection hooks key off this so they no-op
-- everywhere else in the game.
MP.CUSTOM.draft = nil

local function list_has(list, key)
	for _, v in ipairs(list) do
		if v == key then return true end
	end
	return false
end

local function list_remove(list, key)
	for i, v in ipairs(list) do
		if v == key then
			table.remove(list, i)
			return
		end
	end
end

local function index_of(list, value, default)
	for i, v in ipairs(list) do
		if v == value then return i end
	end
	return default or 1
end

-- ---------------------------------------------------------------------------
-- Ban set helpers (set-semantics over the draft's per-category arrays)
-- ---------------------------------------------------------------------------
local function bucket_for(draft, set)
	if set == "Joker" then return draft.banned_jokers end
	if set == "Tarot" or set == "Planet" or set == "Spectral" then return draft.banned_consumables end
	if set == "Voucher" then return draft.banned_vouchers end
	return nil
end

function MP.CUSTOM.is_banned(key)
	local d = MP.CUSTOM.draft
	if not d then return false end
	return list_has(d.banned_jokers, key)
		or list_has(d.banned_consumables, key)
		or list_has(d.banned_vouchers, key)
end

function MP.CUSTOM.toggle_ban(card)
	local d = MP.CUSTOM.draft
	if not d then return end
	local set = card.config.center.set
	local key = card.config.center.key
	local list = bucket_for(d, set)
	if not list then return end
	if list_has(list, key) then
		list_remove(list, key)
		card.debuff = false
	else
		list[#list + 1] = key
		card.debuff = true
	end
end

-- ---------------------------------------------------------------------------
-- Collection picker — paint the draft's bans onto the open Collection page,
-- DELETE toggles the hovered card. Lifted from the mockup, validated against
-- SMODS.card_collection_UIBox / SMODS_card_collection_page paging.
-- ---------------------------------------------------------------------------
function MP.CUSTOM.debuff_collection_page()
	if not (G.your_collection and MP.CUSTOM.draft) then return end
	for i = 1, #G.your_collection do
		for _, v in pairs(G.your_collection[i].cards) do
			if v.config and v.config.center_key and MP.CUSTOM.is_banned(v.config.center_key) then v.debuff = true end
		end
	end
end

-- Re-paint every time a collection UIBox is (re)built...
local _cc_ref = SMODS.card_collection_UIBox
function SMODS.card_collection_UIBox(_pool, rows, args)
	local ret = _cc_ref(_pool, rows, args)
	MP.CUSTOM.debuff_collection_page()
	return ret
end

-- ...and every time the player pages within a collection (SMODS paging fires
-- option_cycle with this opt_callback).
local _oc_ref = G.FUNCS.option_cycle
function G.FUNCS.option_cycle(e)
	local ret = _oc_ref(e)
	if e.config.ref_table and e.config.ref_table.opt_callback == "SMODS_card_collection_page" then
		MP.CUSTOM.debuff_collection_page()
	end
	return ret
end

-- The joker collection's Back button is hardcoded to `your_collection` (the
-- collection hub). When we opened it from the editor to pick bans, intercept
-- that one press and route back to the Custom tab instead. The flag is set only
-- for the editor's open and cleared on the way out, so the hub works normally
-- everywhere else.
local _your_collection_ref = G.FUNCS.your_collection
G.FUNCS.your_collection = function(e)
	if MP.CUSTOM.editing_bans then
		MP.CUSTOM.editing_bans = nil
		return G.FUNCS.mp_custom_back_to_editor(e)
	end
	return _your_collection_ref(e)
end

G.FUNCS.mp_custom_back_to_editor = function(e)
	G.FUNCS.overlay_menu({
		definition = G.UIDEF.ruleset_selection_tabs(MP.CUSTOM.editor_mode or "mp", "Custom"),
	})
end

-- Press DELETE while hovering a collection card to toggle its ban.
SMODS.Keybind({
	key = "mp_custom_ban",
	key_pressed = "delete",
	action = function(self)
		if not MP.CUSTOM.draft then return end
		local target = G.CONTROLLER.hovering and G.CONTROLLER.hovering.target
		if not (target and target.config and target.config.center) then return end
		local area = target.area
		if area and area.config and area.config.collection then MP.CUSTOM.toggle_ban(target) end
	end,
})

-- ---------------------------------------------------------------------------
-- Knob callbacks (mutate the draft in place; pure state for now)
-- ---------------------------------------------------------------------------
G.FUNCS.mp_custom_set_base = function(args)
	if MP.CUSTOM.draft and args and args.to_key then MP.CUSTOM.draft.base = CONTENT_SETS[args.to_key] end
end

G.FUNCS.mp_custom_set_lives = function(args)
	if MP.CUSTOM.draft and args and args.to_key then
		MP.CUSTOM.draft.scalars.starting_lives = LIVES_OPTIONS[args.to_key]
	end
end

G.FUNCS.mp_custom_set_pvp_start = function(args)
	if MP.CUSTOM.draft and args and args.to_key then
		MP.CUSTOM.draft.scalars.pvp_start_round = PVP_START_OPTIONS[args.to_key]
	end
end

G.FUNCS.mp_custom_open_collection = function(e)
	-- Drop into the vanilla joker collection; the hooks above paint the current
	-- ban set and DELETE toggles entries. The flag makes the collection's Back
	-- button route to the Custom tab (see the your_collection wrap above).
	MP.CUSTOM.editing_bans = true
	G.FUNCS.your_collection_jokers(e)
end

-- ---------------------------------------------------------------------------
-- "Submit your dream ruleset" — teaser interest capture (stub)
-- ---------------------------------------------------------------------------
-- Custom rulesets aren't wired to anything yet. But while it's a teaser we can
-- still learn what people *want* to build: fire-and-forget the draft to a Google
-- Form (responses land in a Sheet — no backend to stand up). Mirrors Balatro's
-- own crash reporter — a persistent thread requires `https` and pumps requests
-- off a channel, so the main thread never blocks and a missing lib can't crash.
--
-- TODO: fill these in. Make a Google Form with one long-answer question, grab the
-- "Get pre-filled link" URL: the form id is the e/<id> in /forms/d/e/<id>/, and
-- the field is the entry.<digits> in the query string.
local SUBMIT = {
	form_id = "REPLACE_WITH_FORM_ID",
	entry = "entry.000000000", -- single long-answer field; holds the whole JSON blob
}

local json = require("json")

local function urlencode(str)
	return (tostring(str or ""):gsub("\n", "\r\n"):gsub("([^%w _%%%-%.~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end):gsub(" ", "+"))
end

local function ensure_http_thread()
	if MP.CUSTOM._http_thread then return end
	MP.CUSTOM._http_thread = love.thread.newThread([[
		local ok, https = pcall(require, "https")
		local CHANNEL = love.thread.getChannel("mp_custom_http")
		while true do
			local req = CHANNEL:demand()
			if req and ok then
				pcall(https.request, req.url, {
					method = "POST",
					data = req.body,
					headers = { ["Content-Type"] = "application/x-www-form-urlencoded" },
				})
			end
		end
	]])
	MP.CUSTOM._http_thread:start()
end

function MP.CUSTOM.submit_dream(draft)
	if not draft then return end
	if SUBMIT.form_id == "REPLACE_WITH_FORM_ID" then
		sendDebugMessage("custom ruleset submit: Google Form not configured (stub)", "MULTIPLAYER")
		return
	end
	ensure_http_thread()
	local mod = SMODS.Mods["Multiplayer"]
	local payload = json.encode({
		name = draft.name,
		base = draft.base,
		modifiers = MP.MODIFIERS, -- live, edited via the shared modifiers overlay
		scalars = draft.scalars,
		banned_jokers = draft.banned_jokers,
		banned_consumables = draft.banned_consumables,
		banned_vouchers = draft.banned_vouchers,
		user = mod and mod.config and mod.config.username,
		version = mod and mod.version,
	})
	love.thread.getChannel("mp_custom_http"):push({
		url = "https://docs.google.com/forms/d/e/" .. SUBMIT.form_id .. "/formResponse",
		body = SUBMIT.entry .. "=" .. urlencode(payload),
	})
end

G.FUNCS.mp_custom_submit_dream = function(e)
	MP.CUSTOM.submit_dream(MP.CUSTOM.draft)
	MP.CUSTOM.submitted = true
	play_sound("generic1", 1.0, 0.6)
	if e then e:juice_up(0.3, 0.1) end
	G.FUNCS.mp_custom_back_to_editor(e) -- re-render so the button reads "Sent"
end

-- ---------------------------------------------------------------------------
-- Tab content
-- ---------------------------------------------------------------------------
local function text_row(str, scale, colour)
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.04 },
		nodes = {
			{ n = G.UIT.T, config = { text = str, scale = scale or 0.4, colour = colour or G.C.UI.TEXT_LIGHT } },
		},
	}
end

local function knob_row(node)
	return { n = G.UIT.R, config = { align = "cm", padding = 0.08 }, nodes = { node } }
end

-- COMING SOON banner across the top of the editor.
local function coming_soon_ribbon()
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.12, r = 0.1, colour = G.C.BOOSTER, emboss = 0.05, minw = 15 },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.T,
						config = { text = "CUSTOM RULESETS - COMING SOON", scale = 0.55, colour = G.C.UI.TEXT_LIGHT, shadow = true },
					},
				},
			},
		},
	}
end

-- Disabled "coming soon" pill, matching the mutator wall's inert-cell look.
local function soon_pill(label)
	return {
		n = G.UIT.C,
		config = { align = "cm", minw = 4.5, minh = 0.85, padding = 0.08, r = 0.1, emboss = 0.05, colour = G.C.UI.BACKGROUND_INACTIVE },
		nodes = {
			{ n = G.UIT.R, config = { align = "cm" }, nodes = { { n = G.UIT.T, config = { text = label, scale = 0.45, colour = G.C.UI.TEXT_INACTIVE } } } },
			{ n = G.UIT.R, config = { align = "cm" }, nodes = { { n = G.UIT.T, config = { text = "coming soon", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE } } } },
		},
	}
end

function MP.UI.build_custom_ruleset_editor(mode)
	MP.CUSTOM.editor_mode = mode -- so the ban picker's Back knows where to return
	MP.CUSTOM.draft = MP.CUSTOM.draft or MP.CUSTOM.new_draft()
	local d = MP.CUSTOM.draft

	local knobs = {}

	-- content set radio
	knobs[#knobs + 1] = knob_row(create_option_cycle({
		label = "Content set",
		scale = 0.8,
		options = CONTENT_SETS,
		current_option = index_of(CONTENT_SETS, d.base, 2),
		opt_callback = "mp_custom_set_base",
		w = 4,
	}))

	-- scalars
	knobs[#knobs + 1] = knob_row(create_option_cycle({
		label = "Starting lives",
		scale = 0.8,
		options = LIVES_LABELS,
		current_option = index_of(LIVES_OPTIONS, d.scalars.starting_lives, 4),
		opt_callback = "mp_custom_set_lives",
		w = 4,
	}))
	knobs[#knobs + 1] = knob_row(create_option_cycle({
		label = "PvP start ante",
		scale = 0.8,
		options = PVP_START_LABELS,
		current_option = index_of(PVP_START_OPTIONS, d.scalars.pvp_start_round, 2),
		opt_callback = "mp_custom_set_pvp_start",
		w = 4,
	}))

	-- edit-bans button
	knobs[#knobs + 1] = knob_row(UIBox_button({
		button = "mp_custom_open_collection",
		label = { "Edit joker bans" },
		minw = 4,
		minh = 0.8,
		scale = 0.45,
		colour = G.C.RED,
		hover = true,
		shadow = true,
	}))
	knobs[#knobs + 1] = text_row("Banned jokers: " .. tostring(#d.banned_jokers), 0.32, G.C.UI.TEXT_INACTIVE)
	knobs[#knobs + 1] = text_row("(hover a card, press DELETE)", 0.28, G.C.UI.TEXT_DARK)

	-- right panel: the modifiers live here now — the same MUTATORS wall the
	-- standalone overlay shows, plus the compact timer/PvP controls and the
	-- randomize pair. All drive MP.MODIFIERS, so the editor and lobby agree.
	local modifiers_panel = {
		{
			n = G.UIT.R,
			config = { align = "cm", padding = 0.04 },
			nodes = {
				{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = { MP.UI.build_timer_modifier_cycle() } },
				{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = { MP.UI.build_pvp_timer_toggle() } },
			},
		},
		MP.UI.build_mutators_wall(),
		{ n = G.UIT.R, config = { minh = 0.06 } },
		MP.UI.build_mutator_randomize_row(),
	}

	-- action row: play is honestly disabled; submitting your dream combo is live.
	local submit_node = MP.CUSTOM.submitted
			and soon_pill("Sent! thanks")
		or {
			n = G.UIT.C,
			config = { align = "cm", padding = 0.06 },
			nodes = {
				UIBox_button({
					id = "mp_custom_submit_btn",
					button = "mp_custom_submit_dream",
					label = { "Submit your dream ruleset" },
					colour = G.C.GREEN,
					minw = 4.5,
					minh = 0.85,
					scale = 0.45,
					hover = true,
					shadow = true,
				}),
			},
		}
	local actions = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.12 },
		nodes = {
			{ n = G.UIT.C, config = { align = "cm", padding = 0.06 }, nodes = { soon_pill("Save & Play") } },
			submit_node,
		},
	}

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			coming_soon_ribbon(),
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{ n = G.UIT.C, config = { align = "tm", minh = 6, minw = 5, padding = 0.1 }, nodes = knobs },
					{
						n = G.UIT.C,
						config = { align = "tm", minh = 6, minw = 10, padding = 0.15, r = 0.1, colour = G.C.BLACK },
						nodes = modifiers_panel,
					},
				},
			},
			actions,
		},
	}
end
