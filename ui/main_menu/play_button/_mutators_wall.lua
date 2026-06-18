local function timer_modifier_to_index()
	if MP.has_modifier("pressure_timer_plus") then return 4 end
	if MP.has_modifier("pressure_timer") then return 3 end
	if MP.has_modifier("no_animation_timer") then return 2 end
	return 1
end

G.FUNCS.change_modifier_timer = function(args)
	MP.remove_modifier("no_animation_timer")
	MP.remove_modifier("pressure_timer")
	MP.remove_modifier("pressure_timer_plus")
	if args.to_key == 2 then
		MP.add_modifier("no_animation_timer")
	elseif args.to_key == 3 then
		MP.add_modifier("pressure_timer")
	elseif args.to_key == 4 then
		MP.add_modifier("pressure_timer")
		MP.add_modifier("pressure_timer_plus")
	end
end

local TIMER_BLURBS = {
	"Regular 150s timer.",
	"100s timer, animations off.",
	"100s, no anim, starts at once.",
	"Pressure, +15s per hand played.",
}

G.FUNCS.mp_timer_blurb = function(e)
	local txt = TIMER_BLURBS[timer_modifier_to_index()] or ""
	if e.children[1] and e.children[1].config.text ~= txt then
		e.children[1].config.text = txt
		e.UIBox:recalculate(true)
	end
end

-- Each cycle is one table: label / mod / blurb on the same line. mod = nil means
-- "no modifier" (the cycle's default, inherits whatever the ruleset does).
local GLASS_VARIANTS = {
	{ label = "Inherit", mod = nil, blurb = "Inherit the main ruleset." },
	{ label = "Vanilla", mod = "glass_vanilla", blurb = "x2 mult." },
	{ label = "Standard", mod = "glass_standard", blurb = "x1.5 (Justice Disabled)." },
	{ label = "Legacy", mod = "glass_legacy", blurb = "x1.5 (Justice Enabled)." },
	{ label = "Experimental", mod = "glass_experimental", blurb = "x2 (Grim/Familiar/Incantation only)." },
}

local function variant_labels(variants)
	local labels = {}
	for i, v in ipairs(variants) do
		labels[i] = v.label
	end
	return labels
end

local function variant_index(variants)
	for i, v in ipairs(variants) do
		if v.mod and MP.has_modifier(v.mod) then return i end
	end
	return 1
end

local function pick_variant(variants, to_key)
	for _, v in ipairs(variants) do
		if v.mod then MP.remove_modifier(v.mod) end
	end
	local chosen = variants[to_key]
	if chosen and chosen.mod then MP.add_modifier(chosen.mod) end
end

local function variant_blurb_func(variants)
	return function(e)
		local txt = variants[variant_index(variants)].blurb
		if e.children[1] and e.children[1].config.text ~= txt then
			e.children[1].config.text = txt
			e.UIBox:recalculate(true)
		end
	end
end

G.FUNCS.change_glass_variant = function(args)
	pick_variant(GLASS_VARIANTS, args.to_key)
end
G.FUNCS.mp_glass_blurb = variant_blurb_func(GLASS_VARIANTS)

local MUTATOR_WALL = {
	{
		name = "ECONOMY",
		colour = G.C.MONEY,
		cells = {
			{
				key = "inflation",
				label = "Inflation",
				desc = { "Shop prices creep up $1 with", "every card you buy." },
				soon = true,
			},
			{
				key = "no_interest",
				label = "No Interest",
				desc = { "Savings earn nothing.", "Spend it or lose the edge." },
				soon = true,
			},
			{ key = "discard_tax", label = "Discard Tax", desc = { "Every discard costs $1." }, soon = true },
			{ key = "frugal", label = "Frugal", desc = { "Unspent discards pay out $1." }, soon = true },
			{
				key = "wraith_rework",
				label = "Kind Wraith",
				desc = { "Wraith spawns an Uncommon and", "pays $5 (was Rare, money to $0)." },
			},
		},
	},
	{
		name = "MAYHEM",
		colour = G.C.PURPLE,
		cells = {
			{ key = "flipped_cards", label = "Blind Poker", desc = { "Your hand is dealt face-down." }, soon = true },
			{
				key = "debuff_played_cards",
				label = "Dead Cards",
				desc = { "Playing cards are debuffed.", "Jokers are the whole engine." },
			},
			{ key = "all_eternal", label = "No Takebacks", desc = { "Every joker is eternal." } },
			{
				key = "shrinking_hand",
				label = "Heavy Pockets",
				desc = { "-1 hand size for every $10", "you're holding." },
			},
			{
				key = "shared_pockets",
				label = "Shared Pockets",
				desc = { "Hand, jokers and consumables", "share one pool of slots." },
			},
			{
				key = "score_instability",
				label = "Instability",
				desc = { "After scoring, chips and mult", "are dragged toward each other." },
			},
		},
	},
	{
		name = "HAZARDS",
		colour = G.C.RED,
		cells = {
			{ key = "gambling_opportunity", label = "No Easy Money", desc = { "No Gold or Lucky cards." } },
			{ key = "no_uncommons", label = "No Uncommons", desc = { "Uncommon jokers are out", "of the pool." } },
			{ key = "no_red_seals", label = "No Red Seals", desc = { "Red seals never appear." } },
			{ key = "bigger_shop", label = "Bigger Shop", desc = { "One extra card slot", "in the shop." } },
			{
				key = "chip_cap",
				label = "Cash Ceiling",
				desc = { "Chip score can't exceed your", "cash. Greed is the only way up." },
			},
		},
	},
	{
		name = "CHAOS",
		colour = G.C.ORANGE,
		cells = {
			{
				key = "glass_cannon",
				label = "Glass Cannon",
				desc = { "Only 2 hands a round — but", "every hand hits for 4x mult." },
			},
			{
				key = "smallworld",
				label = "Small World",
				desc = { "75% of the pool banned at", "random. Showman always on." },
			},
			{ key = "spartan", label = "Spartan", desc = { "No cash from Small or Big", "blinds." } },
			{
				key = "pricey_packs",
				label = "Pricey Packs",
				desc = { "Booster packs cost more", "for each ante you reach." },
			},
			{
				key = "polymorph_spam",
				label = "Polymorph",
				desc = { "Every blind, your jokers and", "consumables re-roll." },
			},
			{ key = "eeeee", label = "Eeeee", desc = { "~40% of random rolls lock to", "a fixed value each ante." } },
		},
	},
}

G.FUNCS.mp_toggle_mutator = function(e)
	local key = e.config.ref_table.key
	MP.MUTATORS_BLIND = false -- touching anything reveals the wall
	if MP.has_modifier(key) then
		MP.remove_modifier(key)
		play_sound("cardSlide2", 1.1, 0.4)
	else
		MP.add_modifier(key)
		play_sound("cardSlide1", 1.1, 0.5)
	end
	e:juice_up(0.2, 0.1)
end

-- Live recolour: bright when the modifier is active, dim-tinted otherwise.
-- In blind mode the wall lies — active cells read as off, so you go in blind.
G.FUNCS.mp_mutator_cell_colour = function(e)
	local rt = e.config.ref_table
	local lit = MP.has_modifier(rt.key) and not MP.MUTATORS_BLIND
	e.config.colour = lit and rt.on or rt.off
end

-- Roll a fresh random loadout across the whole wall (~1 in 3 odds per knob).
local function roll_mutators()
	for _, cat in ipairs(MUTATOR_WALL) do
		for _, cell in ipairs(cat.cells) do
			MP.remove_modifier(cell.key)
			if not cell.soon and math.random() < 0.35 then MP.add_modifier(cell.key) end
		end
	end
end

G.FUNCS.mp_randomize_mutators = function(e)
	MP.MUTATORS_BLIND = false
	roll_mutators()
	play_sound("generic1", 1.0, 0.5)
	e:juice_up(0.3, 0.1)
end

G.FUNCS.mp_blind_random_mutators = function(e)
	roll_mutators()
	MP.MUTATORS_BLIND = true -- keep the roll a secret
	play_sound("timpani", 1.0, 0.5)
	e:juice_up(0.3, 0.1)
end

local function mutator_cell(cell, colour, disabled)
	local on = colour
	local off = darken(colour, 0.72)
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.035 },
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cm",
					minw = 2.5,
					minh = 0.46,
					padding = 0.06,
					r = 0.1,
					emboss = 0.05,
					hover = true,
					shadow = not disabled,
					colour = disabled and G.C.UI.BACKGROUND_INACTIVE or off,
					button = not disabled and "mp_toggle_mutator" or nil,
					func = not disabled and "mp_mutator_cell_colour" or nil,
					ref_table = { key = cell.key, on = on, off = off },
					tooltip = disabled and { title = cell.label, text = { "Coming soon." } }
						or { title = cell.label, text = cell.desc },
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = cell.label,
							scale = 0.34,
							colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
		},
	}
end

local function mutator_column(cat)
	local nodes = {
		{
			n = G.UIT.R,
			config = { align = "cm", padding = 0.04, minh = 0.4 },
			nodes = { { n = G.UIT.T, config = { text = cat.name, scale = 0.4, colour = cat.colour, shadow = true } } },
		},
	}
	for _, cell in ipairs(cat.cells) do
		nodes[#nodes + 1] = mutator_cell(cell, cat.colour, cell.soon)
	end
	return { n = G.UIT.C, config = { align = "tm", padding = 0.06 }, nodes = nodes }
end

-- ---------------------------------------------------------------------------
-- Reusable builders (shared by overlays and the inline custom-ruleset editor —
-- one source of truth for the wall + timer controls).
-- ---------------------------------------------------------------------------
function MP.UI.build_timer_modifier_cycle()
	return MP.UI.Disableable_Option_Cycle({
		id = "modifier_timer_option",
		enabled_ref_table = { val = true },
		enabled_ref_value = "val",
		label = localize("k_opts_modifier_timer"),
		scale = 0.8,
		options = localize("ml_mp_modifier_timer_opt"),
		current_option = timer_modifier_to_index(),
		opt_callback = "change_modifier_timer",
		minw = 4,
		w = 4,
	})
end

function MP.UI.build_pvp_timer_toggle()
	return create_toggle({
		id = "modifier_pvp_timer_toggle",
		label = localize("b_opts_modifier_pvp_timer"),
		ref_table = { val = MP.has_modifier("pvp_timer") },
		ref_value = "val",
		callback = function(new_val)
			if new_val then
				MP.add_modifier("pvp_timer")
			else
				MP.remove_modifier("pvp_timer")
			end
		end,
	})
end

-- A variant cycle = the option-cycle plus a live one-line blurb stacked under it.
-- Shared shape for glass / shop-size (and any future "pick one of N" knob).
local function variant_cycle(args)
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.04 },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					create_option_cycle({
						id = args.id,
						label = args.label,
						scale = 0.7,
						options = args.options,
						current_option = args.current_option,
						opt_callback = args.opt_callback,
						w = 4,
						minw = 4,
					}),
				},
			},
			{
				n = G.UIT.R,
				config = { align = "cm", func = args.blurb_func, minh = 0.3 },
				nodes = { { n = G.UIT.T, config = { text = "", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE } } },
			},
		},
	}
end

function MP.UI.build_glass_cycle()
	return variant_cycle({
		id = "modifier_glass_option",
		label = "Glass",
		options = variant_labels(GLASS_VARIANTS),
		current_option = variant_index(GLASS_VARIANTS),
		opt_callback = "change_glass_variant",
		blurb_func = "mp_glass_blurb",
	})
end

-- The MUTATORS wall block: header + subtitle + themed columns + coming-soon line.
-- Returns one node (rows stack vertically since they're R children).
function MP.UI.build_mutators_wall()
	local columns = {}
	for _, cat in ipairs(MUTATOR_WALL) do
		columns[#columns + 1] = mutator_column(cat)
	end
	return {
		n = G.UIT.R,
		config = { align = "cm" },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.02 },
				nodes = {
					{
						n = G.UIT.T,
						config = { text = "MUTATORS", scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true },
					},
				},
			},
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.02 },
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = "stack freely · hover for details",
							scale = 0.3,
							colour = G.C.UI.TEXT_INACTIVE,
						},
					},
				},
			},
			{ n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = columns },
		},
	}
end

-- Randomize / Blind Random pair (operate on MP.MODIFIERS via the global FUNCS).
function MP.UI.build_mutator_randomize_row()
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.05 },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.05 },
				nodes = {
					UIBox_button({
						id = "mp_randomize_mutators_btn",
						button = "mp_randomize_mutators",
						label = { "Randomize" },
						colour = G.C.ORANGE,
						minw = 2.8,
						minh = 0.7,
						scale = 0.4,
						hover = true,
						shadow = true,
					}),
				},
			},
			{
				n = G.UIT.C,
				config = { align = "cm", padding = 0.05 },
				nodes = {
					UIBox_button({
						id = "mp_blind_random_mutators_btn",
						button = "mp_blind_random_mutators",
						label = { "Blind Random" },
						colour = G.C.PURPLE,
						minw = 2.8,
						minh = 0.7,
						scale = 0.4,
						hover = true,
						shadow = true,
					}),
				},
			},
		},
	}
end
