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

-- Content set -> (base ruleset short key, ruleset). `base` defaults to the draft's.
local function base_ruleset(base)
	base = base or (MP.CUSTOM.draft and MP.CUSTOM.draft.base)
	if not base then return nil end
	local short = CONTENT_SET_RULESET[base] or "blitz"
	return short, MP.Rulesets["ruleset_mp_" .. short]
end

-- ---------------------------------------------------------------------------
function MP.CUSTOM.new_draft()
	return { base = "Standard" } -- key into CONTENT_SETS / CONTENT_SET_RULESET
end

MP.CUSTOM.draft = nil

-- Does a content set's base ruleset compose this layer? Lets wall cells show
-- what the content set already brings in (Sandbox -> sandbox rotation).
function MP.CUSTOM.base_has_layer(name, base)
	local short, ruleset = base_ruleset(base)
	if not short then return false end
	if short == name then return true end
	for _, layer in ipairs(ruleset and ruleset._layer_order or {}) do
		if layer == name then return true end
	end
	return false
end

-- Does a content set already bring a wall cell in? `implied_by` is a layer name
-- the base composes, or a predicate on the base ruleset (MP Jokers reads
-- multiplayer_content).
function MP.CUSTOM.base_implies(implied_by, base)
	if type(implied_by) ~= "function" then return MP.CUSTOM.base_has_layer(implied_by, base) end
	local _, ruleset = base_ruleset(base)
	return ruleset ~= nil and implied_by(ruleset) == true
end

-- Content sets that bring a cell in, for its tooltip.
function MP.CUSTOM.content_sets_implying(implied_by)
	local out = {}
	for _, set in ipairs(CONTENT_SETS) do
		if MP.CUSTOM.base_implies(implied_by, set) then out[#out + 1] = set end
	end
	return out
end

local function index_of(list, value, default)
	for i, v in ipairs(list) do
		if v == value then return i end
	end
	return default or 1
end

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
	local base_short, ruleset = base_ruleset(d.base)
	local base_key = "ruleset_mp_" .. base_short

	if mode == "sp" or mode == "practice" then
		MP.SP.ruleset = base_key
	else
		MP.LOBBY.config.ruleset = base_key
	end

	-- Materialize reworks for the chosen base. active_layer_chain now folds in
	-- MP.MODIFIERS (the ruleset is set above), so modifier reworks resolve too.
	MP.LoadReworks(base_short)

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

-- ---------------------------------------------------------------------------
-- Tab content
-- ---------------------------------------------------------------------------
local function unavailable_pill(label)
	return {
		n = G.UIT.C,
		config = {
			align = "cm",
			minw = 4.5,
			minh = 0.85,
			padding = 0.08,
			r = 0.1,
			emboss = 0.05,
			colour = G.C.UI.BACKGROUND_INACTIVE,
		},
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = { { n = G.UIT.T, config = { text = label, scale = 0.45, colour = G.C.UI.TEXT_INACTIVE } } },
			},
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.T,
						config = { text = "Available in Solo and Practice", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE },
					},
				},
			},
		},
	}
end

-- The editor is local-only for now, so on the lobby (mp) path we stub the tab.
-- It stays fully functional in sp / practice.
local function unavailable_root()
	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR, minh = 6, minw = 15 },
		nodes = {
			{ n = G.UIT.R, config = { align = "cm" }, nodes = { unavailable_pill("Custom Rulesets") } },
		},
	}
end

local BASE_DESCRIPTIONS = {
	Vanilla = "Original cards and balance",
	Standard = "Multiplayer cards and balance changes",
	Sandbox = "Sandbox Jokers and balance changes",
	Experimental = "Experimental balance changes",
}

G.FUNCS.mp_custom_base_blurb = function(e)
	local d = MP.CUSTOM.draft
	MP.UI.set_blurb(e, d and BASE_DESCRIPTIONS[d.base] or "")
end

-- Second line of the Play button: content set + wall count + clock preset
-- ("Standard / 3 changes / Normal Chaos").
MP.CUSTOM.play_summary = MP.CUSTOM.play_summary or { text = "" }

G.FUNCS.mp_custom_play_summary = function(e)
	local d = MP.CUSTOM.draft
	if not d then return end
	local text = d.base
	if MP.MUTATORS_HIDDEN then
		text = text .. " / Mystery Mix"
	else
		local count = MP.UI.active_mutator_count()
		if count > 0 then text = text .. " / " .. count .. (count == 1 and " change" or " changes") end
		local preset = MP.CHAOS_CLOCK.preset_key()
		if preset then text = text .. " / " .. MP.CHAOS_CLOCK.PRESETS[preset].label .. " Chaos" end
	end
	MP.CUSTOM.play_summary.text = text
end

local function play_button(label)
	return {
		n = G.UIT.C,
		config = {
			id = "mp_custom_play_btn",
			align = "cm",
			minw = 4,
			minh = 0.95,
			padding = 0.08,
			r = 0.1,
			colour = G.C.GREEN,
			button = "mp_custom_play",
			hover = true,
			shadow = true,
		},
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{ n = G.UIT.T, config = { text = label, scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
				},
			},
			{
				n = G.UIT.R,
				config = { align = "cm", func = "mp_custom_play_summary" },
				nodes = {
					{
						n = G.UIT.T,
						config = {
							ref_table = MP.CUSTOM.play_summary,
							ref_value = "text",
							scale = 0.3,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
		},
	}
end

local function divider()
	return {
		n = G.UIT.R,
		config = {
			align = "cm",
			minw = MP.UI.mutators_wall_width(),
			minh = 0.03,
			colour = adjust_alpha(G.C.WHITE, 0.08),
		},
	}
end

function MP.UI.build_custom_ruleset_editor(mode)
	if mode == "mp" then return unavailable_root() end
	MP.CUSTOM.editor_mode = mode -- so Play knows which start flow to take
	MP.CUSTOM.draft = MP.CUSTOM.draft or MP.CUSTOM.new_draft()
	local d = MP.CUSTOM.draft
	G.FUNCS.mp_custom_play_summary()

	-- Strip of graded knobs: content set / timer / glass / PvP timer. Binary twists
	-- live on the wall below.
	local strip = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.04 },
		nodes = {
			MP.UI.knob({
				label = "Base Ruleset",
				blurb_func = "mp_custom_base_blurb",
				control = MP.UI.knob_cycle({
					options = CONTENT_SETS,
					current_option = index_of(CONTENT_SETS, d.base, 2),
					opt_callback = "mp_custom_set_base",
				}),
			}),
			MP.UI.build_timer_knob(),
			MP.UI.build_glass_knob(),
			MP.UI.build_pvp_timer_knob(),
		},
	}

	-- Play button label matches the start flow the base ruleset will take.
	local _, ruleset = base_ruleset(d.base)
	local play_label
	if mode == "sp" or mode == "practice" then
		play_label = localize("b_play_cap")
	elseif ruleset and ruleset.forced_gamemode then
		play_label = localize("b_create_lobby")
	else
		play_label = localize("b_next")
	end

	local actions = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.06 },
		nodes = {
			MP.UI.build_mutator_actions(),
			{ n = G.UIT.B, config = { w = 0.4, h = 0.1 } },
			MP.UI.build_chaos_clock_control(),
			{ n = G.UIT.B, config = { w = 0.4, h = 0.1 } },
			play_button(play_label),
		},
	}

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.15, r = 0.1, colour = G.C.BLACK },
				nodes = {
					strip,
					divider(),
					MP.UI.build_mutators_wall(),
					divider(),
					actions,
				},
			},
		},
	}
end
