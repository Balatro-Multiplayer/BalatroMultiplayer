MP.CUSTOM = MP.CUSTOM or {}

local CONTENT_SETS = { "Vanilla", "Standard", "Sandbox", "Experimental" }

-- Content set (display string) -> base ruleset short key. The custom editor is
-- "this base + a stack of modifiers", so each set just points at an existing
-- ruleset whose layers we inherit.
local CONTENT_SET_RULESET = {
	Vanilla = "vanilla",
	Standard = "blitz",
	Sandbox = "sandbox",
	Experimental = "experimental",
}

-- ---------------------------------------------------------------------------
function MP.CUSTOM.new_draft()
	return {
		name = "My Ruleset",
		base = "Standard", -- key into CONTENT_SETS / CONTENT_SET_RULESET
		modifiers = {}, -- snapshotted modifiers
		banned_jokers = {},
		banned_consumables = {},
		banned_vouchers = {},
	}
end

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

-- hijack the collection when we're in the joker ban
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

-- credit to @Aaal for MPCustomBans which I was heavily inspired by
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

G.FUNCS.mp_custom_set_base = function(args)
	if MP.CUSTOM.draft and args and args.to_key then MP.CUSTOM.draft.base = CONTENT_SETS[args.to_key] end
end

-- Launch a custom run: chosen base ruleset + the wall's MP.MODIFIERS.
-- We set the ruleset directly and deliberately DON'T route through
-- change_ruleset_selection / apply_default_modifiers, which would wipe the
-- wall's modifier selections. Modifiers ride to the guest via start_lobby's
-- modifier_layers serialization, same as the Modifiers overlay.
G.FUNCS.mp_custom_play = function(e)
	local d = MP.CUSTOM.draft or MP.CUSTOM.new_draft()
	local mode = MP.CUSTOM.editor_mode or "mp"
	local base_short = CONTENT_SET_RULESET[d.base] or "blitz"
	local base_key = "ruleset_mp_" .. base_short

	if mode == "sp" or mode == "practice" then
		MP.SP.ruleset = base_key
	else
		MP.LOBBY.config.ruleset = base_key
	end

	-- Materialize reworks for the chosen base. active_layer_chain now folds in
	-- MP.MODIFIERS (the ruleset is set above), so modifier reworks resolve too.
	MP.LoadReworks(base_short)

	local ruleset = MP.Rulesets[base_key]
	if mode == "sp" then
		G.FUNCS.start_sp_run(e)
	elseif mode == "practice" then
		G.FUNCS.start_practice_run(e)
	elseif ruleset and ruleset.forced_gamemode then
		G.FUNCS["force_" .. ruleset.forced_gamemode](e)
	else
		G.FUNCS.select_gamemode(e)
	end
end

G.FUNCS.mp_custom_open_collection = function(e)
	MP.CUSTOM.editing_bans = true
	G.FUNCS.your_collection_jokers(e)
end


-- ---------------------------------------------------------------------------
-- Tab content
-- ---------------------------------------------------------------------------
local function knob_row(node)
	return { n = G.UIT.R, config = { align = "cm", padding = 0.08 }, nodes = { node } }
end

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

	-- edit-bans: custom card bans aren't wired into ApplyBans / network sync yet.
	knobs[#knobs + 1] = knob_row(soon_pill("Edit joker bans"))

	-- Variants strip: option-cycles for graded knobs (timer / glass) plus the PvP
	-- toggle. Binary twists live on the wall below.
	local variants_strip = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.04 },
		nodes = {
			{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = { MP.UI.build_timer_modifier_cycle() } },
			{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = { MP.UI.build_glass_cycle() } },
			{ n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = { MP.UI.build_pvp_timer_toggle() } },
		},
	}

	local modifiers_panel = {
		variants_strip,
		MP.UI.build_mutators_wall(),
		{ n = G.UIT.R, config = { minh = 0.06 } },
		MP.UI.build_mutator_randomize_row(),
	}

	-- Play button label matches the start flow the base ruleset will take.
	local base_ruleset = MP.Rulesets["ruleset_mp_" .. (CONTENT_SET_RULESET[d.base] or "blitz")]
	local play_label
	if mode == "sp" or mode == "practice" then
		play_label = localize("b_play_cap")
	elseif base_ruleset and base_ruleset.forced_gamemode then
		play_label = localize("b_create_lobby")
	else
		play_label = localize("b_next")
	end

	local actions = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.12 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.06 },
				nodes = {
					UIBox_button({
						id = "mp_custom_play_btn",
						button = "mp_custom_play",
						label = { play_label },
						colour = G.C.GREEN,
						minw = 5,
						minh = 0.8,
						scale = 0.5,
						hover = true,
						shadow = true,
					}),
				},
			},
		},
	}

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
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
