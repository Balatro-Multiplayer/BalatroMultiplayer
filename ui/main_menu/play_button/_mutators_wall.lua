-- Writes a live one-line blurb (first child of e), recalculating only on change.
function MP.UI.set_blurb(e, txt)
	if e.children[1] and e.children[1].config.text ~= txt then
		e.children[1].config.text = txt
		e.UIBox:recalculate(true)
	end
end

-- Editor knobs are variant cycles (MP.variant_of, layers/_mutators.lua) with a
-- blurb per variant. mod = nil is the default: inherit whatever the ruleset does.
-- Option labels come from each variant's label, or from the knob's localized list.
local TIMER = {
	variants = {
		{ blurb = "150-second timer." },
		{ mod = "no_animation_timer", blurb = "100 seconds. No animations." },
		{ mod = "pressure_timer", blurb = "100 seconds. Starts immediately." },
		{ mod = { "pressure_timer", "pressure_timer_plus" }, blurb = "Pressure timer. +15s per hand." },
	},
}

local GLASS = {
	variants = {
		{ label = "Default", blurb = "Use the base ruleset." },
		{ label = "Vanilla", mod = "glass_vanilla", blurb = "X2 Mult." },
		{ label = "Standard", mod = "glass_standard", blurb = "X1.5 Mult. Justice banned." },
		{ label = "Legacy", mod = "glass_legacy", blurb = "X1.5 Mult. Justice available." },
		{ label = "Experimental", mod = "glass_experimental", blurb = "X2 Mult. Grim, Familiar, Incantation." },
	},
}

local function variant_labels(cycle)
	local labels = {}
	for i, v in ipairs(cycle.variants) do
		labels[i] = v.label
	end
	return labels
end

local function variant_index(cycle)
	return (select(2, MP.variant_of(cycle)))
end

G.FUNCS.change_modifier_timer = function(args)
	MP.set_variant(TIMER, TIMER.variants[args.to_key])
end
G.FUNCS.mp_timer_blurb = function(e)
	MP.UI.set_blurb(e, (MP.variant_of(TIMER)).blurb)
end

G.FUNCS.change_glass_variant = function(args)
	MP.set_variant(GLASS, GLASS.variants[args.to_key])
end
G.FUNCS.mp_glass_blurb = function(e)
	MP.UI.set_blurb(e, (MP.variant_of(GLASS)).blurb)
end

-- Wall columns, left to right. Cells come from the mutator registry
-- (MP.MUTATORS, filled by `mutator = {...}` on each layer); this table only
-- owns presentation. `content` columns change which cards exist rather than
-- how the run plays, so Randomize / Mystery Mix leave them as the player set them.
local CATEGORIES = {
	{ name = "ECONOMY", colour = G.C.MONEY },
	{ name = "MAYHEM", colour = G.C.PURPLE },
	{ name = "HAZARDS", colour = G.C.RED },
	{ name = "CHAOS", colour = G.C.ORANGE },
	{ name = "JOKERS", colour = G.C.SECONDARY_SET.Planet, panel = true, content = true },
}

-- The draft's base ruleset already brings this cell in (e.g. Rotation under the
-- Sandbox content set, MP Jokers under Standard).
local function implied(def)
	return def.implied_by and MP.CUSTOM and MP.CUSTOM.base_implies and MP.CUSTOM.base_implies(def.implied_by)
end

-- "off" | "on" | "implied" for toggles; variants read "on" off-default.
local function cell_state(def)
	if def.variants then
		local _, i = MP.variant_of(def)
		if i == 1 then return implied(def) and "implied" or "off" end
		return "on"
	end
	if MP.has_modifier(def.key) then return "on" end
	return implied(def) and "implied" or "off"
end

local function cell_text(def)
	if def.variants then return (MP.variant_of(def)).label end
	return def.label
end

G.FUNCS.mp_toggle_mutator = function(e)
	local def = e.config.ref_table.def
	MP.MUTATORS_HIDDEN = false -- touching anything reveals the wall
	if def.variants then
		local _, i = MP.variant_of(def)
		local shift = love.keyboard.isDown("lshift", "rshift")
		if shift and def.secret then
			MP.set_variant(def, i == 0 and def.variants[1] or def.secret)
		else
			MP.set_variant(def, def.variants[i % #def.variants + 1])
		end
		play_sound("cardSlide1", 1.1, 0.5)
	else
		local on = MP.toggle_modifier(def.key)
		play_sound(on and "cardSlide1" or "cardSlide2", 1.1, 0.5)
	end
	e:juice_up(0.2, 0.1)
end

-- Cell palettes. On = solid category fill + white pip; off = outline-only in the
-- category tint, so "on" is the only loud state on the wall. Implied = on, but dimmed,
-- because the base ruleset already owns it. Hidden = one neutral look for every
-- cell, so a Mystery Mix reads as hidden rather than as all-off.
local function cell_palette(colour)
	return {
		on = { fill = colour, outline = colour, text = G.C.UI.TEXT_LIGHT, pip = G.C.WHITE },
		implied = {
			fill = mix_colours(colour, G.C.BLACK, 0.55),
			outline = mix_colours(colour, G.C.BLACK, 0.7),
			text = G.C.UI.TEXT_LIGHT,
			pip = mix_colours(colour, G.C.WHITE, 0.4),
		},
		off = {
			fill = mix_colours(colour, G.C.BLACK, 0.12),
			outline = mix_colours(colour, G.C.BLACK, 0.55),
			text = mix_colours(colour, G.C.WHITE, 0.6),
			pip = mix_colours(colour, G.C.BLACK, 0.3),
		},
	}
end

-- Off cells the Chaos Clock can draw while it's on: the pip lights in the
-- clock's colour, so the wall shows its pool.
local CLOCK_PIP = G.C.DARK_EDITION

local function clock_draws(def)
	return def.clock
		and (not def.clock.preset or def.clock.preset == MP.CHAOS_CLOCK.preset_key())
		and MP.CHAOS_CLOCK.eligible(def.key, def.clock)
end

local HIDDEN_PALETTE = {
	fill = mix_colours(G.C.WHITE, G.C.BLACK, 0.1),
	outline = mix_colours(G.C.WHITE, G.C.BLACK, 0.35),
	text = G.C.UI.TEXT_INACTIVE,
	pip = G.C.CLEAR,
}

-- Live recolour of cell fill / outline / pip / label. Children: pip, gap, label.
local cell_tooltip

G.FUNCS.mp_mutator_cell_colour = function(e)
	local rt = e.config.ref_table
	local preset = MP.CHAOS_CLOCK.preset_key()
	if rt.clock_preset ~= preset then
		e.config.tooltip.text = cell_tooltip(rt.def)
		rt.clock_preset = preset
	end
	local p, pip
	if MP.MUTATORS_HIDDEN then
		p = HIDDEN_PALETTE
		pip = p.pip
		rt.text = rt.def.label
	else
		local state = cell_state(rt.def)
		p = rt.palette[state]
		pip = p.pip
		if state == "off" and MP.CHAOS_CLOCK.preset_key() and clock_draws(rt.def) then pip = CLOCK_PIP end
		rt.text = cell_text(rt.def)
	end
	e.config.colour = p.fill
	e.config.outline_colour = p.outline
	if e.children[1] then e.children[1].config.colour = pip end
	if e.children[3] then e.children[3].config.colour = p.text end
end

local function live_cells(cat)
	return MP.mutators_in(cat.name)
end

local function each_live_cell(fn, skip_content)
	for _, cat in ipairs(CATEGORIES) do
		if not (skip_content and cat.content) then
			for _, def in ipairs(live_cells(cat)) do
				fn(def)
			end
		end
	end
end

-- Number of wall cells not at their default (on, or a non-default variant).
-- Graded knobs (timer / glass / PvP timer on the strip, the Chaos Clock on the
-- action row) don't count.
function MP.UI.active_mutator_count()
	local n = 0
	each_live_cell(function(def)
		local state = cell_state(def)
		if state == "on" then n = n + 1 end
	end)
	return n
end

MP.UI.mutator_readout = MP.UI.mutator_readout or { count = "0" }

G.FUNCS.mp_mutator_readout = function(e)
	MP.UI.mutator_readout.count = MP.MUTATORS_HIDDEN and "?" or tostring(MP.UI.active_mutator_count())
end

local function clear_mutators(skip_content)
	each_live_cell(function(def)
		if def.variants then
			MP.set_variant(def, def.variants[1])
		else
			MP.remove_modifier(def.key)
		end
	end, skip_content)
	MP.set_variant(MP.CHAOS_CLOCK.CYCLE, nil)
end

-- Roll a fresh random loadout: ~1 in 3 toggle cells on (content columns
-- untouched), and a uniform pick of Chaos Clock preset. The roll seed is logged so a surprising loadout can be
-- reproduced.
local roll_count = 0
local function roll_mutators()
	clear_mutators(true)
	roll_count = roll_count + 1
	local seed = "wall_" .. os.time() .. "_" .. roll_count
	local rng = MP.rng.stream(seed)
	local picked = {}
	each_live_cell(function(def)
		if not def.variants and rng:chance(0.35, def.key) then
			MP.add_modifier(def.key)
			picked[#picked + 1] = def.key
		end
	end, true)
	local clock = rng:element(MP.CHAOS_CLOCK.CYCLE.variants, "chaos_clock")
	MP.set_variant(MP.CHAOS_CLOCK.CYCLE, clock)
	if clock.mod then picked[#picked + 1] = clock.mod end
	sendDebugMessage("Mutator roll " .. seed .. ": " .. table.concat(picked, ","), "MULTIPLAYER")
end

G.FUNCS.mp_clear_mutators = function(e)
	MP.MUTATORS_HIDDEN = false
	clear_mutators()
	play_sound("cardSlide2", 1.0, 0.5)
	e:juice_up(0.3, 0.1)
end

G.FUNCS.mp_randomize_mutators = function(e)
	MP.MUTATORS_HIDDEN = false
	roll_mutators()
	play_sound("generic1", 1.0, 0.5)
	e:juice_up(0.3, 0.1)
end

G.FUNCS.mp_mystery_mix = function(e)
	roll_mutators()
	MP.MUTATORS_HIDDEN = true -- keep the roll a secret
	play_sound("timpani", 1.0, 0.5)
	e:juice_up(0.3, 0.1)
end

-- TODO(rewire): fold this and mod_badges.lua's inline builder into one shared
-- MP.UI.credit_badge(credits) so we can use it anywhere we like :)
local function mutator_credit_badge(credits)
	credits.art = credits.art or {}
	credits.idea = credits.idea or {}
	credits.code = credits.code or {}

	local function calc_scale_fac(text)
		local size = 0.9
		local font = G.LANG.font
		local max_text_width = 2 - 2 * 0.05 - 4 * 0.03 * size - 2 * 0.03
		local calced_text_width = 0
		for _, c in utf8.chars(text) do
			local tx = font.FONT:getWidth(c) * (0.33 * size) * G.TILESCALE * font.FONTSCALE
				+ 2.7 * 1 * G.TILESCALE * font.FONTSCALE
			calced_text_width = calced_text_width + tx / (G.TILESIZE * G.TILESCALE)
		end
		return calced_text_width > max_text_width and max_text_width / calced_text_width or 1
	end

	local strings = {}
	for _, v in ipairs({ "art", "idea", "code" }) do
		for i = 1, #credits[v] do
			strings[#strings + 1] = localize({ type = "variable", key = "a_mp_" .. v, vars = { credits[v][i] } })[1]
		end
	end

	-- fallback if {}
	if #strings == 0 then return { n = G.UIT.R, config = { align = "cm" }, nodes = {} } end

	local min_scale_fac = 1
	for i = 1, #strings do
		min_scale_fac = math.min(min_scale_fac, calc_scale_fac(strings[i]))
	end

	local ct = {}
	for i = 1, #strings do
		ct[i] = { string = strings[i] }
	end

	return {
		n = G.UIT.R,
		config = { align = "cm" },
		nodes = {
			{
				n = G.UIT.R,
				config = {
					align = "cm",
					colour = G.C.MULTIPLAYER,
					r = 0.1,
					minw = 2 / min_scale_fac,
					minh = 0.36,
					emboss = 0.05,
					padding = 0.03 * 0.9,
				},
				nodes = {
					{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
					{
						n = G.UIT.O,
						config = {
							object = DynaText({
								string = ct,
								colours = { credits.text_colour or G.C.WHITE },
								silent = true,
								float = true,
								shadow = true,
								offset_y = -0.03,
								spacing = 1,
								scale = 0.33 * 0.9,
							}),
						},
					},
					{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
				},
			},
		},
	}
end

local CELL_W, CELL_H, PIP = 2.55, 0.46, 0.12
local CELL_TEXT = 0.32

local CLOCK_AT = { blind = "May trigger each Blind.", ante = "May activate each Ante." }
local CLOCK_LASTS =
	{ instant = "One-time effect.", blind = "Lasts until the next Blind.", ante = "Lasts until the next Ante." }

cell_tooltip = function(def)
	local text = {}
	for i, line in ipairs(def.desc or {}) do
		text[i] = line
	end
	if def.count then text[#text + 1] = def.count .. " Jokers." end
	if def.unavailable and def.unavailable() then
		for _, line in ipairs(def.unavailable_desc) do
			text[#text + 1] = line
		end
	end
	if def.clock then
		text[#text + 1] = "Chaos Clock:"
		if def.clock.preset then text[#text + 1] = MP.CHAOS_CLOCK.PRESETS[def.clock.preset].label .. " only." end
		text[#text + 1] = CLOCK_AT[def.clock.at]
		local preset = MP.CHAOS_CLOCK.PRESETS[MP.CHAOS_CLOCK.preset_key()]
		local duration = preset
				and preset.severe_for_run
				and def.clock.severity == 3
				and def.clock.lasts ~= "instant"
				and "Lasts for the rest of the run."
			or CLOCK_LASTS[def.clock.lasts]
		for _, line in ipairs(def.clock_desc or { duration }) do
			text[#text + 1] = line
		end
		for _, line in ipairs(def.clock_note or {}) do
			text[#text + 1] = line
		end
	end
	if def.implied_by and MP.CUSTOM and MP.CUSTOM.content_sets_implying then
		local sets = MP.CUSTOM.content_sets_implying(def.implied_by)
		if #sets > 0 then text[#text + 1] = "Included with " .. table.concat(sets, ", ") .. "." end
	end
	return text
end

local function mutator_cell(def, palette)
	local tooltip = { title = def.label, text = cell_tooltip(def) }
	if def.credits then tooltip.filler = { func = mutator_credit_badge, args = def.credits } end
	local rt = { def = def, palette = palette, text = cell_text(def), clock_preset = MP.CHAOS_CLOCK.preset_key() }
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.035 },
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cm",
					minw = CELL_W,
					minh = CELL_H,
					padding = 0.06,
					r = 0.1,
					outline = 1.2,
					outline_colour = palette.off.outline,
					hover = true,
					shadow = true,
					colour = palette.off.fill,
					button = "mp_toggle_mutator",
					func = "mp_mutator_cell_colour",
					ref_table = rt,
					tooltip = tooltip,
				},
				nodes = {
					{ n = G.UIT.B, config = { w = PIP, h = PIP, r = 0.05, colour = palette.off.pip } },
					{ n = G.UIT.B, config = { w = 0.1, h = 0.1 } },
					{
						n = G.UIT.T,
						config = { ref_table = rt, ref_value = "text", scale = CELL_TEXT, colour = palette.off.text },
					},
					-- trailing gap the width of pip + gap keeps the label optically centred
					{ n = G.UIT.B, config = { w = PIP + 0.1, h = 0.1 } },
				},
			},
		},
	}
end

-- Invisible cell-sized slot keeps the columns aligned.
local function cell_placeholder()
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.035 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm", minw = CELL_W, minh = CELL_H, padding = 0.06 },
				nodes = { { n = G.UIT.T, config = { text = " ", scale = 0.34, colour = G.C.CLEAR } } },
			},
		},
	}
end

local function mutator_column(cat, rows)
	local palette = cell_palette(cat.colour)
	local live = live_cells(cat)
	local nodes = {
		{
			n = G.UIT.R,
			config = { align = "cm", padding = 0.04, minh = 0.4 },
			nodes = { { n = G.UIT.T, config = { text = cat.name, scale = 0.4, colour = cat.colour, shadow = true } } },
		},
	}
	for _, def in ipairs(live) do
		nodes[#nodes + 1] = mutator_cell(def, palette)
	end
	for _ = #live + 1, rows do
		nodes[#nodes + 1] = cell_placeholder()
	end
	local config = { align = "tm", padding = 0.06 }
	-- Panel columns (Jokers) sit on a tinted backing so they read as their own
	-- block rather than a fifth peer of the twist columns.
	if cat.panel then
		config.r = 0.1
		config.colour = mix_colours(cat.colour, G.C.BLACK, 0.18)
	end
	return { n = G.UIT.C, config = config, nodes = nodes }
end

function MP.UI.build_timer_modifier_cycle()
	return MP.UI.Disableable_Option_Cycle({
		id = "modifier_timer_option",
		enabled_ref_table = { val = true },
		enabled_ref_value = "val",
		label = localize("k_opts_modifier_timer"),
		scale = 0.8,
		options = localize("ml_mp_modifier_timer_opt"),
		current_option = variant_index(TIMER),
		opt_callback = "change_modifier_timer",
		minw = 4,
		w = 4,
	})
end

-- create_toggle bound to one modifier in MP.MODIFIERS.
function MP.UI.modifier_toggle(name, args)
	args.ref_table = { val = MP.has_modifier(name) }
	args.ref_value = "val"
	args.callback = function(on)
		if on then
			MP.add_modifier(name)
		else
			MP.remove_modifier(name)
		end
	end
	return create_toggle(args)
end

-- Top-strip knob: label, control, live one-line blurb. Every knob on the custom
-- editor's strip shares this footprint so labels, controls and blurbs line up.
local KNOB_SCALE, KNOB_W = 0.7, 4.3

function MP.UI.knob(args)
	local w = args.minw or KNOB_W
	return {
		n = G.UIT.C,
		config = { align = "tm", minw = w, padding = 0.05 },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.T,
						config = { text = args.label, scale = 0.5 * KNOB_SCALE, colour = G.C.UI.TEXT_LIGHT },
					},
				},
			},
			{ n = G.UIT.R, config = { align = "cm", minh = 0.8 }, nodes = { args.control } },
			{
				n = G.UIT.R,
				config = { align = "cm", minh = 0.3, maxw = w - 0.2, func = args.blurb_func },
				nodes = {
					{ n = G.UIT.T, config = { text = args.blurb or "", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE } },
				},
			},
		},
	}
end

function MP.UI.knob_cycle(args)
	return create_option_cycle({
		id = args.id,
		scale = KNOB_SCALE,
		options = args.options,
		current_option = args.current_option,
		opt_callback = args.opt_callback,
		w = 4,
		minw = 4,
	})
end

function MP.UI.build_timer_knob()
	return MP.UI.knob({
		label = localize("k_opts_modifier_timer"),
		blurb_func = "mp_timer_blurb",
		control = MP.UI.knob_cycle({
			id = "modifier_timer_option",
			options = localize("ml_mp_modifier_timer_opt"),
			current_option = variant_index(TIMER),
			opt_callback = "change_modifier_timer",
		}),
	})
end

function MP.UI.build_glass_knob()
	return MP.UI.knob({
		label = "Glass Cards",
		blurb_func = "mp_glass_blurb",
		control = MP.UI.knob_cycle({
			id = "modifier_glass_option",
			options = variant_labels(GLASS),
			current_option = variant_index(GLASS),
			opt_callback = "change_glass_variant",
		}),
	})
end

function MP.UI.build_pvp_timer_knob()
	return MP.UI.knob({
		label = localize("b_opts_modifier_pvp_timer"),
		blurb = "90s, +15s per hand.",
		minw = 3,
		control = MP.UI.modifier_toggle("pvp_timer", { id = "modifier_pvp_timer_toggle", label = "", w = 0 }),
	})
end

-- Width of the wall, for the header row and the editor's dividers.
function MP.UI.mutators_wall_width()
	return #CATEGORIES * (CELL_W + 0.31)
end

function MP.UI.build_mutators_wall()
	local rows = 0
	for _, cat in ipairs(CATEGORIES) do
		rows = math.max(rows, #live_cells(cat))
	end
	local columns = {}
	for _, cat in ipairs(CATEGORIES) do
		columns[#columns + 1] = mutator_column(cat, rows)
	end
	local width = MP.UI.mutators_wall_width()
	return {
		n = G.UIT.R,
		config = { align = "cm" },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.02, func = "mp_mutator_readout" },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cl", minw = width - 2.2 },
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "HOUSE RULES",
									scale = 0.5,
									colour = G.C.UI.TEXT_LIGHT,
									shadow = true,
								},
							},
						},
					},
					{
						n = G.UIT.C,
						config = { align = "cr", minw = 2.2 },
						nodes = {
							{ n = G.UIT.T, config = { text = "SELECTED", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE } },
							{ n = G.UIT.B, config = { w = 0.12, h = 0.1 } },
							{
								n = G.UIT.T,
								config = {
									ref_table = MP.UI.mutator_readout,
									ref_value = "count",
									scale = 0.45,
									colour = G.C.UI.TEXT_LIGHT,
									shadow = true,
								},
							},
						},
					},
				},
			},
			{ n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = columns },
		},
	}
end

local function small_button(id, func, label, colour, description)
	local button = UIBox_button({
		id = id,
		button = func,
		label = { label },
		colour = colour,
		minw = 2.1,
		minh = 0.55,
		scale = 0.35,
		col = true,
	})
	button.nodes[1].config.tooltip = { title = label, text = description }
	return {
		n = G.UIT.C,
		config = { align = "cm", padding = 0.04 },
		nodes = {
			button,
		},
	}
end

-- Clear / Randomize / Mystery Mix (operate on MP.MODIFIERS via the global FUNCS).
-- Kept small so the editor's Play button is the one loud action.
function MP.UI.build_mutator_actions()
	return {
		n = G.UIT.C,
		config = { align = "cm" },
		nodes = {
			small_button("mp_clear_mutators_btn", "mp_clear_mutators", "Reset Rules", G.C.GREY, {
				"Restore default house rules",
				"and turn off Chaos Clock.",
			}),
			small_button("mp_randomize_mutators_btn", "mp_randomize_mutators", "Randomize", G.C.ORANGE, {
				"Choose random house rules",
				"and a Chaos Clock setting.",
				"Keeps your Joker selections.",
			}),
			small_button("mp_mystery_mix_btn", "mp_mystery_mix", "Mystery Mix", G.C.PURPLE, {
				"Choose a random setup",
				"and keep it hidden.",
				"Change any house rule to reveal it.",
			}),
		},
	}
end

-- Chaos Clock: a setting on the action row, not a wall cell, because it draws
-- from the wall's Off cells. Shaped as a small knob (label / cycle / pool
-- readout) so it doesn't read as a fourth button.
local CLOCK = MP.CHAOS_CLOCK.CYCLE

-- Off cells the clock can switch on, plus its own one-shot events.
function MP.UI.chaos_clock_pool()
	local cells, events = 0, 0
	each_live_cell(function(def)
		if cell_state(def) == "off" and clock_draws(def) then cells = cells + 1 end
	end)
	for _ in pairs(MP.CHAOS_CLOCK.EVENTS) do
		events = events + 1
	end
	return cells, events
end

local function clock_tooltip()
	local text = {}
	for i, line in ipairs(CLOCK.desc) do
		text[i] = line
	end
	for _, v in ipairs(CLOCK.variants) do
		local preset = v.preset and MP.CHAOS_CLOCK.PRESETS[v.preset]
		if preset then
			text[#text + 1] = v.label .. ":"
			for _, line in ipairs(preset.desc) do
				text[#text + 1] = line
			end
		end
	end
	return text
end

G.FUNCS.mp_change_chaos_clock = function(args)
	MP.MUTATORS_HIDDEN = false
	MP.set_variant(CLOCK, CLOCK.variants[args.to_key])
end

-- Randomize / Clear move the clock from outside the cycle, so keep the cycle's
-- index and text in step. Under Mystery Mix it reads "?".
G.FUNCS.mp_chaos_clock_sync = function(e)
	local args = e.config.ref_table
	local i = variant_index(CLOCK)
	args.current_option = i
	args.current_option_val = MP.MUTATORS_HIDDEN and "?" or args.options[i]
end

G.FUNCS.mp_chaos_clock_blurb = function(e)
	local txt
	if MP.MUTATORS_HIDDEN then
		txt = "A surprise setup"
	elseif not MP.CHAOS_CLOCK.preset_key() then
		txt = "No random effects"
	else
		txt = MP.CHAOS_CLOCK.PRESETS[MP.CHAOS_CLOCK.preset_key()].blurb
	end
	MP.UI.set_blurb(e, txt)
end

function MP.UI.build_chaos_clock_control()
	local args = {
		options = variant_labels(CLOCK),
		current_option = variant_index(CLOCK),
		opt_callback = "mp_change_chaos_clock",
		scale = 0.6,
		w = 3,
		no_pips = true,
	}
	local cycle = create_option_cycle(args)
	return {
		n = G.UIT.C,
		config = { align = "cm", padding = 0.02 },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.C,
						config = {
							align = "cm",
							hover = true,
							tooltip = { title = CLOCK.label, text = clock_tooltip() },
						},
						nodes = {
							{ n = G.UIT.T, config = { text = CLOCK.label, scale = 0.32, colour = G.C.UI.TEXT_LIGHT } },
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = { align = "cm", func = "mp_chaos_clock_sync", ref_table = args },
				nodes = { cycle },
			},
			{
				n = G.UIT.R,
				config = { align = "cm", minh = 0.25, func = "mp_chaos_clock_blurb" },
				nodes = { { n = G.UIT.T, config = { text = "", scale = 0.27, colour = G.C.UI.TEXT_INACTIVE } } },
			},
		},
	}
end
