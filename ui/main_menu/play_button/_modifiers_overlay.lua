-- Modifier toggles render inline inside the ruleset info panel. The handlers
-- write MP.MODIFIERS directly (no network) — the host's lobby_options push at
-- start_lobby carries the serialized list to the guest.
--
-- Top section keeps the original descriptive rows (timer cycle + PvP timer, each
-- with their inline blurb). Below that, the rest of the mutators are a wall of
-- toggle "pills" grouped into themed columns: dim-tinted when off, full category
-- colour when on, description on hover. Cells recolour live via a per-frame
-- `func` (engine reads config.colour each draw) so nothing rebuilds.

local function timer_modifier_to_index()
	if MP.has_modifier("pressure_timer_plus") then return 4 end
	if MP.has_modifier("pressure_timer") then return 3 end
	if MP.has_modifier("no_animation_timer") then return 2 end
	return 1
end

-- Indices line up with localization ml_mp_modifier_timer_opt: 1=default, 2=no_anim, 3=pressure
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

-- One-line blurb per timer option (indices match timer_modifier_to_index).
-- Shown next to the cycle instead of all four at once; updated live as you cycle.
local TIMER_BLURBS = {
	"Regular 150s timer.",
	"100s timer, animations off.",
	"100s, no anim, starts at once.",
	"Pressure, +15s per hand played.",
}

-- Live-update the timer blurb to match the current cycle selection. Mirrors
-- display_custom_seed: mutate the child text node and recalculate only on change.
G.FUNCS.mp_timer_blurb = function(e)
	local txt = TIMER_BLURBS[timer_modifier_to_index()] or ""
	if e.children[1] and e.children[1].config.text ~= txt then
		e.children[1].config.text = txt
		e.UIBox:recalculate(true)
	end
end

-- A compact descriptive row: control on the left, a single text node on the right.
-- `desc_node` may carry its own `func` (e.g. the timer's live blurb).
local function compact_entry(option, desc_node)
	return {
		n = G.UIT.R,
		config = {
			padding = 0.12,
			align = "cm",
			r = 0.25,
			colour = { 1, 1, 1, 0.1 },
		},
		nodes = {
			{
				n = G.UIT.C,
				config = { minw = 5, align = "cm" },
				nodes = { option },
			},
			{
				n = G.UIT.C,
				config = { align = "cm", maxw = 8.5 },
				nodes = { desc_node },
			},
		},
	}
end

-- ---------------------------------------------------------------------------
-- The wall
-- ---------------------------------------------------------------------------
-- View config only — `key` is the layer name (what MP.MODIFIERS stores). Names
-- and blurbs are inline for now; trivially swappable to localize() later.
-- Each column shares a colour; cells tint dark when off, bright when on.
local MUTATOR_WALL = {
	{
		name = "ECONOMY",
		colour = G.C.MONEY,
		cells = {
			{ key = "inflation", label = "Inflation", desc = { "Shop prices creep up $1 with", "every card you buy." } },
			{ key = "no_interest", label = "No Interest", desc = { "Savings earn nothing.", "Spend it or lose the edge." } },
			{ key = "discard_tax", label = "Discard Tax", desc = { "Every discard costs $1.", "Think before you toss." } },
			{ key = "frugal", label = "Frugal", desc = { "Unspent discards pay out,", "like leftover hands do." } },
		},
	},
	{
		name = "MAYHEM",
		colour = G.C.PURPLE,
		cells = {
			{ key = "flipped_cards", label = "Blind Poker", desc = { "Your hand is dealt face-down.", "Play by memory and nerve." } },
			{ key = "debuff_played_cards", label = "Dead Cards", desc = { "Played cards score zero.", "Jokers are the whole engine." } },
			{ key = "all_eternal", label = "No Takebacks", desc = { "Every joker is eternal —", "unsellable, undestroyable." } },
			{ key = "shrinking_hand", label = "Heavy Pockets", desc = { "-1 hand size for every $10", "you're holding. Rich, clumsy." } },
		},
	},
	{
		name = "HAZARDS",
		colour = G.C.RED,
		cells = {
			{ key = "gambling_opportunity", label = "No Easy Money", desc = { "No Gold or Lucky cards.", "Earn it the hard way." } },
			{ key = "no_legendaries", label = "No Legends", desc = { "The five legendary jokers", "are out of the pool." } },
			{ key = "sticker_shop", label = "Risky Shelf", desc = { "Shop stocks eternal, perishable", "and rental jokers. Beware." } },
			{ key = "chip_cap", label = "Cash Ceiling", desc = { "Chip score can't exceed your", "cash. Greed is the only way up." } },
		},
	},
	{
		name = "CHAOS",
		colour = G.C.ORANGE,
		cells = {
			{ key = "glass_cannon", label = "Glass Cannon", desc = { "Only 2 hands a round — but", "every hand hits for 4x mult." } },
			{ key = "smallworld", label = "Small World", desc = { "75% of the pool banned at", "random. Showman always on." } },
			{ key = "spartan", label = "Spartan", desc = { "No cash from Small or Big", "blinds. Lean times." } },
			{ key = "pricey_packs", label = "Pricey Packs", desc = { "Booster packs cost more", "for each ante you reach." } },
		},
	},
}

local SOON = {
	colour = G.C.GREY,
	cells = {
		{ key = "pvp_reward_draft", label = "Reward Draft", desc = { "Win a PvP blind, draft 1 of 3", "rewards.", "(coming soon)" } },
		{ key = "rubber_band", label = "Rubber Band", desc = { "Falling behind grants", "escalating buffs.", "(coming soon)" } },
		{ key = "score_tax", label = "Score Tax", desc = { "Each hand you play raises", "your opponent's target.", "(coming soon)" } },
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
			if math.random() < 0.35 then MP.add_modifier(cell.key) end
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
					tooltip = { title = cell.label, text = cell.desc },
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
		nodes[#nodes + 1] = mutator_cell(cell, cat.colour)
	end
	return { n = G.UIT.C, config = { align = "tm", padding = 0.06 }, nodes = nodes }
end

-- ---------------------------------------------------------------------------
-- Reusable builders (shared by the standalone overlay and the inline custom-
-- ruleset editor — one source of truth for the wall + timer controls).
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

-- The MUTATORS wall block: header + subtitle + themed columns + coming-soon line.
-- Returns one node (rows stack vertically since they're R children).
function MP.UI.build_mutators_wall()
	local columns = {}
	for _, cat in ipairs(MUTATOR_WALL) do
		columns[#columns + 1] = mutator_column(cat)
	end
	local soon_labels = {}
	for _, cell in ipairs(SOON.cells) do
		soon_labels[#soon_labels + 1] = cell.label
	end
	local soon_line = "coming soon · " .. table.concat(soon_labels, " · ")
	return {
		n = G.UIT.R,
		config = { align = "cm" },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.02 },
				nodes = { { n = G.UIT.T, config = { text = "MUTATORS", scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true } } },
			},
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.02 },
				nodes = { { n = G.UIT.T, config = { text = "stack freely · hover for details", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE } } },
			},
			{ n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = columns },
			{ n = G.UIT.R, config = { minh = 0.06 } },
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.02 },
				nodes = { { n = G.UIT.T, config = { text = soon_line, scale = 0.3, colour = G.C.UI.TEXT_INACTIVE } } },
			},
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

G.FUNCS.mp_open_modifiers_overlay = function(e)
	local timer_cycle = MP.UI.build_timer_modifier_cycle()
	local pvp_timer_toggle = MP.UI.build_pvp_timer_toggle()

	-- timer blurb: a single line that re-reads the current selection each frame
	local timer_blurb = {
		n = G.UIT.R,
		config = { align = "cm", func = "mp_timer_blurb" },
		nodes = {
			{
				n = G.UIT.T,
				config = {
					text = TIMER_BLURBS[timer_modifier_to_index()],
					scale = 0.34,
					colour = G.C.UI.TEXT_LIGHT,
				},
			},
		},
	}

	local pvp_blurb = {
		n = G.UIT.T,
		config = { text = "Live timer during PvP blinds.", scale = 0.34, colour = G.C.UI.TEXT_LIGHT },
	}

	local back_func = MP.is_practice_mode() and "mp_open_practice_options_overlay" or "create_lobby"

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			back_func = back_func,
			contents = {
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.18, colour = G.C.BLACK, r = 0.25 },
					nodes = {
						-- compact descriptive rows (timer blurb updates as you cycle)
						compact_entry(timer_cycle, timer_blurb),
						{ n = G.UIT.R, config = { minh = 0.08 } },
						compact_entry(pvp_timer_toggle, pvp_blurb),
						{ n = G.UIT.R, config = { minh = 0.12 } },
						-- shared mutators wall (header + subtitle + columns + coming-soon)
						MP.UI.build_mutators_wall(),
						{ n = G.UIT.R, config = { minh = 0.1 } },
						-- randomize · blind · play
						{
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
											minh = 0.8,
											scale = 0.42,
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
											minh = 0.8,
											scale = 0.42,
											hover = true,
											shadow = true,
										}),
									},
								},
								{
									n = G.UIT.C,
									config = { align = "cm", padding = 0.05 },
									nodes = {
										MP.UI.get_continue_button(e.config.ref_table.ruleset, e.config.ref_table.mode),
									},
								},
							},
						},
					},
				},
			},
		}),
	})
end
