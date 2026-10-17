-- Chaos Clock: draws Off mutator cells (plus a few one-shot events of its own)
-- into the run. Design notes: .context/wild_tiers_design.md (not tracked).
--
-- An entry opts in with `mutator = { clock = { at, lasts, severity } }`:
--   at        "blind" | "ante"   when it can be drawn: each blind start, or the
--                                ante going up (after the boss, so the ante's
--                                first shop is covered)
--   lasts     "instant"          fires once (needs `run`)
--             "blind" | "ante"   switches the layer on until the next blind /
--                                ante starts, so it covers the shop after it
--   severity  1 | 2 | 3          rarity only; the preset sets each one's chance
--   preset    optional preset key restricting which setting can draw it
-- Ante instants run immediately; blind instants wait for the first hand.
-- On Mayhem, severity 3 windows last the rest of the run instead.
--
-- Cells that are On, or that the ruleset already brings in, are skipped:
-- they're running anyway. Every roll is keyed on (run seed, ante, blind slot)
-- via MP.rng, so both players get the same draw at the same point. The slot
-- (Small / Big / Boss), not a counter, so skipping a blind doesn't shift later
-- rolls.
--
-- The whole ante is rolled as it starts (the forecast): the ante draw applies
-- at once, each blind's draw when that blind starts. Blind select shows each
-- blind's draw, instants as "?". Skipping a blind dodges its draw.

MP.CHAOS_CLOCK = {}

-- Chance per roll that each severity draws one entry. Placeholders until
-- playtested. severe_for_run: severity 3 windows last the rest of the run.
local PRESETS = {
	calm = {
		label = "Calm",
		blurb = "Occasional twists",
		desc = { "Occasional twists." },
		rates = { 0.25, 0.15, 0 },
	},
	normal = {
		label = "Normal",
		blurb = "More frequent effects",
		desc = { "More frequent effects,", "with harsher rules possible." },
		rates = { 0.35, 0.25, 0.10 },
	},
	mayhem = {
		label = "Mayhem",
		blurb = "Some rules last the run",
		desc = { "Frequent effects. Some rules last", "for the rest of the run." },
		rates = { 0.5, 0.4, 0.2 },
		severe_for_run = true,
	},
}
local PRESET_ORDER = { "calm", "normal", "mayhem" }
MP.CHAOS_CLOCK.PRESETS = PRESETS

MP.CHAOS_CLOCK.AT = { blind = true, ante = true }
MP.CHAOS_CLOCK.LASTS = { instant = true, blind = true, ante = true }

local SUITS = { "Spades", "Hearts", "Clubs", "Diamonds" }
local SEALS = { "Red", "Blue", "Gold", "Purple" }

local function flip_all(cards, sound, base_pitch)
	for i, card in ipairs(cards) do
		local pitch = base_pitch + (i - 0.999) / (#cards - 0.998) * 0.3
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.12,
			func = function()
				card:flip()
				play_sound(sound, pitch, 0.6)
				card:juice_up(0.3, 0.3)
				return true
			end,
		}))
	end
end

-- Vanilla tarot shape: flip face-down, change, flip back.
local function transform(cards, fn)
	flip_all(cards, "card1", 0.85)
	for i, card in ipairs(cards) do
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.08,
			func = function()
				fn(card, i)
				return true
			end,
		}))
	end
	flip_all(cards, "tarot2", 0.85)
end

-- One-shot events. They have no "on" meaning, so they aren't wall cells; they
-- live only in the clock's pool. `run` returns an optional detail for the banner.
local EVENTS = {
	suit_storm = {
		label = "Suit Storm",
		clock = {
			at = "blind",
			lasts = "instant",
			severity = 1,
			run = function(rng, coord)
				local suit = rng:element(SUITS, "suit_storm", coord)
				transform(G.hand.cards, function(card)
					SMODS.change_base(card, suit)
				end)
				return "All cards in hand become " .. localize(suit, "suits_plural")
			end,
		},
	},
	seal_the_deal = {
		label = "Seal the Deal",
		clock = {
			at = "blind",
			lasts = "instant",
			severity = 1,
			run = function(rng, coord)
				local seals = {}
				for _, s in ipairs(SEALS) do
					if not (s == "Red" and G.GAME.modifiers.mp_no_red_seals) then seals[#seals + 1] = s end
				end
				local targets = rng:pick(G.hand.cards, 2, "seal_cards", coord)
				for i, card in ipairs(targets) do
					local seal = rng:element(seals, "seal", coord, i)
					G.E_MANAGER:add_event(Event({
						trigger = "after",
						delay = 0.3,
						func = function()
							card:set_seal(seal, nil, true)
							card:juice_up(0.3, 0.5)
							play_sound("gold_seal", 1.2, 0.4)
							return true
						end,
					}))
				end
				return "Gives " .. #targets .. " cards in hand random Seals"
			end,
		},
	},
	wild_enhancement = {
		label = "Touch-Up",
		clock = {
			at = "blind",
			lasts = "instant",
			severity = 1,
			run = function(rng, coord)
				local pool = {}
				for _, center in ipairs(G.P_CENTER_POOLS.Enhanced) do
					if not G.GAME.banned_keys[center.key] then pool[#pool + 1] = center.key end
				end
				table.sort(pool)
				local key = rng:element(pool, "enhancement", coord)
				local card = rng:element(G.hand.cards, "enhance_card", coord)
				if not (key and card) then return end
				transform({ card }, function(c)
					c:set_ability(G.P_CENTERS[key], nil, true)
				end)
				return "1 card in hand becomes " .. localize({ type = "name_text", set = "Enhanced", key = key })
			end,
		},
	},
}
MP.CHAOS_CLOCK.EVENTS = EVENTS

-- The clock's control: one cycle on the custom editor's action row (not a wall
-- cell, since it draws from the wall's Off cells), one layer per preset so the
-- choice rides the MP.MODIFIERS sync string like every other cell.
local variants = { { label = "Off", mod = nil } }
for _, key in ipairs(PRESET_ORDER) do
	MP.Layer("clock_" .. key, {})
	variants[#variants + 1] = { label = PRESETS[key].label, mod = "clock_" .. key, preset = key }
end

MP.CHAOS_CLOCK.CYCLE = {
	label = "Chaos Clock",
	desc = {
		"Random effects may trigger at the",
		"start of each Blind and Ante.",
		"Rules marked with a purple dot",
		"can be chosen.",
		"Check each Blind for upcoming effects.",
		"Skip it to avoid them.",
		"Changes to cards can remain",
		"after an effect ends.",
	},
	variants = variants,
}

function MP.CHAOS_CLOCK.preset_key()
	return (MP.variant_of(MP.CHAOS_CLOCK.CYCLE)).preset
end

-- Clock spec for a pool key: an event's, or a wall cell's `mutator.clock`.
function MP.CHAOS_CLOCK.spec(key)
	if EVENTS[key] then return EVENTS[key].clock end
	local m = MP.MUTATORS[key]
	return m and m.clock
end

local function label_of(key)
	if EVENTS[key] then return EVENTS[key].label end
	local m = MP.MUTATORS[key]
	return m and m.label or key
end

-- Can this cell's spec actually be honoured? Instants need `run`; windows need a
-- layer the clock can switch off again.
function MP.CHAOS_CLOCK.eligible(key, spec)
	if spec.lasts == "instant" then return type(spec.run) == "function" end
	return MP.is_switchable(key)
end

-- Pure (exposed for tests): at -> "s<severity>" -> sorted keys. `skip(key)` says
-- a cell is already running (On, or brought in by the ruleset).
function MP.CHAOS_CLOCK.build_pool(skip)
	local pool = {}
	for at in pairs(MP.CHAOS_CLOCK.AT) do
		pool[at] = { s1 = {}, s2 = {}, s3 = {} }
	end
	local function add(key, spec)
		table.insert(pool[spec.at]["s" .. spec.severity], key)
	end
	for key, def in pairs(MP.MUTATORS) do
		if def.clock and MP.CHAOS_CLOCK.eligible(key, def.clock) and not skip(key) then add(key, def.clock) end
	end
	for key, ev in pairs(EVENTS) do
		add(key, ev.clock)
	end
	for _, by_sev in pairs(pool) do
		for _, list in pairs(by_sev) do
			table.sort(list)
		end
	end
	return pool
end

-- Pure schedule (exposed for tests): one roll at a roll point. Each severity
-- draws one entry from its list with the preset's chance. Coordinates after
-- `at` key the roll (ante, or ante + blind slot).
function MP.CHAOS_CLOCK.roll(rng, preset, by_sev, at, ...)
	local picks = {}
	for sev, rate in ipairs(PRESETS[preset].rates) do
		local list = {}
		for _, key in ipairs(by_sev["s" .. sev]) do
			local spec = MP.CHAOS_CLOCK.spec(key)
			if not spec or (spec.at == at and (not spec.preset or spec.preset == preset)) then list[#list + 1] = key end
		end
		if rate > 0 and #list > 0 and rng:chance(rate, "chaos_clock", at, sev, ...) then
			picks[#picks + 1] = rng:element(list, "chaos_clock", at, "pick", sev, ...)
		end
	end
	return picks
end

-- Switch a window's live layers to `want` (a set). Layers that drop out go off,
-- new ones go on. With `grow`, nothing goes off (the "run" window).
-- `mid_round` also moves the current round's hands / discards.
local function switch(window, want, grow, mid_round)
	local clock = G.GAME.mp_clock
	local live = clock.live[window]
	if grow then
		for key in pairs(live) do
			want[key] = true
		end
	end
	for key in pairs(live) do
		if not want[key] then MP.write_layer_modifiers(key, false, mid_round) end
	end
	for key in pairs(want) do
		if not live[key] then MP.write_layer_modifiers(key, true, mid_round) end
	end
	clock.live[window] = want
	if MP.UI and MP.UI.refresh_chaos_clock_hud then MP.UI.refresh_chaos_clock_hud() end
end

-- Entries already drawn for the rest of the run can't be drawn again. Keyed on
-- the draw, not on what went live, so a player who skipped past one still rolls
-- from the same pool as everyone else.
local function available(at)
	local clock = G.GAME.mp_clock
	local out = {}
	for sev, list in pairs(clock.pool[at]) do
		out[sev] = {}
		for _, key in ipairs(list) do
			if not clock.drawn_run[key] then out[sev][#out[sev] + 1] = key end
		end
	end
	return out
end

-- One roll point -> { { key, window } }. window is the spec's `lasts`, or "run"
-- for a severity 3 window on a severe_for_run preset.
local function draw(at, ...)
	local clock = G.GAME.mp_clock
	local preset = PRESETS[clock.preset]
	local picks = {}
	for _, key in ipairs(MP.CHAOS_CLOCK.roll(MP.rng.game(), clock.preset, available(at), at, ...)) do
		local spec = MP.CHAOS_CLOCK.spec(key)
		local window = spec.lasts
		if window ~= "instant" and preset.severe_for_run and spec.severity == 3 then
			window = "run"
			clock.drawn_run[key] = true
		end
		picks[#picks + 1] = { key = key, window = window }
	end
	return picks
end

local SLOTS = { "Small", "Big", "Boss" }

local function log_picks(coord, picks)
	local keys = {}
	for i, p in ipairs(picks) do
		keys[i] = p.key
	end
	sendDebugMessage("Chaos Clock " .. coord .. ": " .. table.concat(keys, ","), "MULTIPLAYER")
end

-- The whole ante, rolled up front: the ante draw plus one per blind slot, in a
-- fixed order so every player gets the same forecast. Blind draws only apply
-- when their blind starts, so skipping a blind dodges its draw.
local function forecast_ante(ante)
	local clock = G.GAME.mp_clock
	local f = { ante = ante, ante_picks = draw("ante", ante), blinds = {} }
	log_picks("ante " .. ante, f.ante_picks)
	for _, slot in ipairs(SLOTS) do
		f.blinds[slot] = draw("blind", ante, slot)
		log_picks("forecast " .. ante .. "_" .. slot, f.blinds[slot])
	end
	clock.forecast = f
end

-- Apply drawn picks: `window` ("ante" / "blind") is replaced by the new set,
-- which is what expires the previous one; "run" only grows. Everything drawn
-- queues for the banner. Ante instants fire now; blind instants wait for a hand.
local function apply(picks, window, coord, mid_round)
	local clock = G.GAME.mp_clock
	local want = { blind = {}, ante = {}, run = {} }
	for _, p in ipairs(picks) do
		if p.window ~= "instant" then want[p.window][p.key] = true end
		local item = { key = p.key, coord = coord, suffix = p.window == "run" and "rest of run" or nil }
		if p.window == "instant" and window == "ante" then
			item.detail = MP.CHAOS_CLOCK.spec(p.key).run(MP.rng.game(), coord)
			item.instant_done = true
		end
		clock.pending[#clock.pending + 1] = item
	end
	switch(window, want[window], false, mid_round)
	switch("run", want.run, true, mid_round)
end

-- Run start (from MP.ApplyGameModifiers). No preset = no clock this run.
-- Ante 1 is forecast and its ante draw applied right away, so the first blind
-- select already shows it.
function MP.CHAOS_CLOCK.start_run()
	local preset = MP.CHAOS_CLOCK.preset_key()
	if not preset then
		G.GAME.mp_clock = nil
		return
	end
	local pool = MP.CHAOS_CLOCK.build_pool(MP.is_layer_active)
	local windows = {}
	for _, by_sev in pairs(pool) do
		for _, list in pairs(by_sev) do
			for _, key in ipairs(list) do
				if MP.CHAOS_CLOCK.spec(key).lasts ~= "instant" then windows[#windows + 1] = key end
			end
		end
	end
	MP.snapshot_baseline(windows)
	G.GAME.mp_clock = {
		preset = preset,
		pool = pool,
		live = { blind = {}, ante = {}, run = {} },
		drawn_run = {},
		pending = {},
		done = {},
	}
	local parts = {}
	for _, at in ipairs({ "blind", "ante" }) do
		for sev = 1, 3 do
			parts[#parts + 1] = at .. sev .. "=" .. table.concat(pool[at]["s" .. sev], ",")
		end
	end
	sendDebugMessage("Chaos Clock " .. preset .. ": " .. table.concat(parts, " "), "MULTIPLAYER")
	MP.CHAOS_CLOCK.on_ante_start(false)
end

-- Ante start, once per ante number: forecast the ante and apply its ante draw.
-- Fired as the ante goes up after the boss, so the window covers the ante's
-- first shop; a save loaded mid-ante catches up at the next blind.
function MP.CHAOS_CLOCK.on_ante_start(mid_round)
	local clock = G.GAME.mp_clock
	local ante = G.GAME.round_resets.ante
	if clock.ante == ante then return false end
	clock.ante = ante
	if not (clock.forecast and clock.forecast.ante == ante) then forecast_ante(ante) end
	apply(clock.forecast.ante_picks, "ante", "ante " .. ante, mid_round)
	return true
end

-- Blind start, before setting_blind fires: apply this slot's forecast draw.
function MP.CHAOS_CLOCK.on_blind_start()
	local clock = G.GAME.mp_clock
	local ante = G.GAME.round_resets.ante
	local slot = G.GAME.blind_on_deck or "?"
	local blind_key = ante .. "_" .. slot
	if clock.done[blind_key] then return end
	clock.done[blind_key] = true

	MP.CHAOS_CLOCK.on_ante_start(true)
	apply(clock.forecast.blinds[slot] or {}, "blind", "blind " .. blind_key, true)
end

-- Skipping a blind dodges its draw, and ends the previous blind's window (it
-- covered the shop before this blind, and there's no shop after a skip).
function MP.CHAOS_CLOCK.on_blind_skipped(slot)
	local clock = G.GAME.mp_clock
	clock.done[G.GAME.round_resets.ante .. "_" .. slot] = true
	switch("blind", {}, false, false)
end

-- What the UI shows for a slot this ante: { text, severity, window } per pick.
-- Instants stay a surprise: "?" with their severity.
function MP.CHAOS_CLOCK.forecast_for(slot)
	local clock = G.GAME and G.GAME.mp_clock
	local f = clock and clock.forecast
	if not (f and f.ante == G.GAME.round_resets.ante) then return nil end
	local out = {}
	for i, p in ipairs(f.blinds[slot] or {}) do
		local spec = MP.CHAOS_CLOCK.spec(p.key)
		out[i] = {
			text = p.window == "instant" and "?" or label_of(p.key),
			severity = spec.severity,
			window = p.window,
		}
	end
	return out
end

-- Live windows for the HUD, ordered blind / ante / run then by label:
-- { text, window }.
function MP.CHAOS_CLOCK.live()
	local clock = G.GAME and G.GAME.mp_clock
	local out = {}
	if not clock then return out end
	for _, window in ipairs({ "blind", "ante", "run" }) do
		local rows = {}
		for key in pairs(clock.live[window]) do
			rows[#rows + 1] = { text = label_of(key), window = window }
		end
		table.sort(rows, function(a, b)
			return a.text < b.text
		end)
		for _, r in ipairs(rows) do
			out[#out + 1] = r
		end
	end
	return out
end

local function announce(lines)
	G.E_MANAGER:add_event(Event({
		func = function()
			attention_text({
				scale = 1,
				maxw = 12,
				text = "CHAOS CLOCK: " .. table.concat(lines, ", "),
				hold = 2.5,
				align = "cm",
				offset = { x = 0, y = -2.7 },
				major = G.play,
			})
			play_sound("timpani", 0.8, 0.6)
			return true
		end,
	}))
end

-- Announce windows and completed ante instants now; hand effects stay queued.
local function announce_windows()
	local clock = G.GAME.mp_clock
	local lines, keep = {}, {}
	for _, item in ipairs(clock.pending) do
		if MP.CHAOS_CLOCK.spec(item.key).lasts == "instant" and not item.instant_done then
			keep[#keep + 1] = item
		else
			local detail = item.detail or item.suffix
			lines[#lines + 1] = label_of(item.key) .. (detail and (" (" .. detail .. ")") or "")
		end
	end
	clock.pending = keep
	if #lines > 0 then announce(lines) end
end

-- After the first hand of a blind is drawn: fire queued instants (several touch
-- the hand) and announce everything drawn at blind start, in one line.
function MP.CHAOS_CLOCK.on_hand_drawn()
	local clock = G.GAME.mp_clock
	if #clock.pending == 0 or #G.hand.cards == 0 then return end
	local pending = clock.pending
	clock.pending = {}
	local lines = {}
	for _, item in ipairs(pending) do
		local detail = item.detail or item.suffix
		local spec = MP.CHAOS_CLOCK.spec(item.key)
		if spec.lasts == "instant" and not item.instant_done then
			detail = spec.run(MP.rng.game(), item.coord) or detail
		end
		lines[#lines + 1] = label_of(item.key) .. (detail and (" (" .. detail .. ")") or "")
	end
	announce(lines)
end

-- The ante goes up inside an event (vanilla's, or MP's in ui/game/round.lua), so
-- roll in an event queued after it. An ante going down (Hieroglyph) rolls too, so
-- the lower ante still gets a forecast before its blinds; repeats are no-ops.
local ease_ante_ref = ease_ante
function ease_ante(mod)
	local ret = ease_ante_ref(mod)
	G.E_MANAGER:add_event(Event({
		func = function()
			if G.GAME and G.GAME.mp_clock and MP.CHAOS_CLOCK.on_ante_start(false) then announce_windows() end
			return true
		end,
	}))
	return ret
end

local skip_blind_ref = G.FUNCS.skip_blind
G.FUNCS.skip_blind = function(e)
	local slot = G.GAME.blind_on_deck or "Small"
	skip_blind_ref(e)
	if G.GAME.mp_clock then MP.CHAOS_CLOCK.on_blind_skipped(slot) end
end

local set_blind_ref = Blind.set_blind
function Blind:set_blind(blind, reset, silent)
	-- blind is nil on save load and reset re-applies the same blind; neither is a
	-- new blind.
	if blind and not reset and G.GAME and G.GAME.mp_clock then MP.CHAOS_CLOCK.on_blind_start() end
	return set_blind_ref(self, blind, reset, silent)
end

local calculate_context_ref = SMODS.calculate_context
function SMODS.calculate_context(context, return_table, no_resolve)
	local ret = calculate_context_ref(context, return_table, no_resolve)
	if type(context) == "table" and (context.hand_drawn or context.first_hand_drawn) and G.GAME and G.GAME.mp_clock then
		MP.CHAOS_CLOCK.on_hand_drawn()
	end
	return ret
end
