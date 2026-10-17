-- Mutators: the registry behind the custom editor's wall, and the runtime side
-- of mutator layers (G.GAME.modifiers wiring, plus switching a layer on and off
-- mid-run for the Chaos Clock, layers/chaos_clock.lua).

-- Mutator registry: one entry per cell on the custom editor's mutators wall.
-- A layer describes its own cell via `mutator = { category, order, label, desc,
-- credits? }`; MP.Layer registers it under the layer's name. Cells that
-- aren't a single layer (e.g. the idol picker, which drives several) call
-- MP.Mutator directly with `variants`.
MP.MUTATORS = {}
local by_category = {} -- mutators_in cache; the wall reads it every frame

function MP.Mutator(def)
	assert(def.key, "MP.Mutator needs a key")
	MP.MUTATORS[def.key] = def
	by_category = {}
end

-- Mutators in a category, wall order. Shared list: don't mutate it.
function MP.mutators_in(category)
	if by_category[category] then return by_category[category] end
	local out = {}
	for _, def in pairs(MP.MUTATORS) do
		if def.category == category then out[#out + 1] = def end
	end
	table.sort(out, function(a, b)
		if (a.order or 0) ~= (b.order or 0) then return (a.order or 0) < (b.order or 0) end
		return a.key < b.key
	end)
	by_category[category] = out
	return out
end

-- A layer can be switched on and off mid-run (so the Chaos Clock can draw it)
-- only if its whole effect is state: `flag` / `game_modifiers` /
-- `round_deltas`. Bans and start-of-run setup can't be undone, so those layers
-- stay plain on/off cells.
function MP.is_switchable(name)
	local layer = MP.Layers[name]
	if not layer then return false end
	if layer.on_apply_bans then return false end
	for _, field in ipairs(MP._LAYER_ARRAY_FIELDS) do
		if layer[field] and #layer[field] > 0 then return false end
	end
	return layer.flag ~= nil or layer.game_modifiers ~= nil or layer.round_deltas ~= nil
end

-- Variant cycles: one control (a wall cell or an editor knob) choosing between
-- mutually exclusive modifier sets. `variants[1]` is the default and usually
-- has no mod; `secret` is an optional extra reached outside the normal cycle.
-- A variant's `mod` is one modifier name or a list (Pressure+ is
-- pressure_timer + pressure_timer_plus).
local function mods_of(variant)
	if type(variant.mod) == "table" then return variant.mod end
	return { variant.mod }
end

local function all_on(mods)
	for _, mod in ipairs(mods) do
		if not MP.has_modifier(mod) then return false end
	end
	return true
end

-- The current variant and its index (0 for the secret). When several match,
-- the one with the most mods wins, so Pressure+ isn't read as Pressure.
function MP.variant_of(cycle)
	local best, best_i, best_n = cycle.variants[1], 1, 0
	local function consider(v, i)
		local mods = mods_of(v)
		if #mods > best_n and all_on(mods) then
			best, best_i, best_n = v, i, #mods
		end
	end
	if cycle.secret then consider(cycle.secret, 0) end
	for i, v in ipairs(cycle.variants) do
		consider(v, i)
	end
	return best, best_i
end

function MP.set_variant(cycle, chosen)
	for _, v in ipairs(cycle.variants) do
		for _, mod in ipairs(mods_of(v)) do
			MP.remove_modifier(mod)
		end
	end
	if cycle.secret then
		for _, mod in ipairs(mods_of(cycle.secret)) do
			MP.remove_modifier(mod)
		end
	end
	for _, mod in ipairs(chosen and mods_of(chosen) or {}) do
		MP.add_modifier(mod)
	end
end

-- `round_deltas` nudge G.GAME.round_resets (hands, discards) by a fixed amount
-- rather than setting them, so they stack with the deck: Glass Cannon's -2 hands
-- on Black Deck leaves 1. What was actually applied is recorded per layer, so a
-- second "on" is a no-op and "off" undoes exactly that, even when a floor
-- clipped it. Mid-round (the Chaos Clock switching a layer at blind start) the
-- current round's count moves too, since new_round already copied it.
local ROUND_DELTA_FLOOR = { hands = 1, discards = 0 }
local ROUND_DELTA_EASE = { hands = "ease_hands_played", discards = "ease_discard" }

local function write_round_deltas(name, layer, on, mid_round)
	if not layer.round_deltas then return end
	G.GAME.mp_round_deltas = G.GAME.mp_round_deltas or {}
	local applied = G.GAME.mp_round_deltas[name]
	if (applied ~= nil) == (on and true or false) then return end
	local resets = G.GAME.round_resets
	local moved = {}
	if on then
		applied = {}
		for k, d in pairs(layer.round_deltas) do
			local cur = resets[k] or 0
			applied[k] = math.max(ROUND_DELTA_FLOOR[k] or 0, cur + d) - cur
			moved[k] = applied[k]
		end
		G.GAME.mp_round_deltas[name] = applied
	else
		for k, a in pairs(applied) do
			moved[k] = -a
		end
		G.GAME.mp_round_deltas[name] = nil
	end
	for k, m in pairs(moved) do
		resets[k] = (resets[k] or 0) + m
		if mid_round and m ~= 0 and ROUND_DELTA_EASE[k] then _G[ROUND_DELTA_EASE[k]](m) end
	end
end

-- Write (or clear) one layer's G.GAME.modifiers state. `flag` is the layer's own
-- boolean (read by its hooks); `game_modifiers` are vanilla challenge modifiers
-- (inflation, no_interest, discard_cost, ...) that vanilla already reads.
-- Table values (no_blind_reward = { Small = true }) merge key-by-key so a stake
-- that already set Small isn't clobbered. Turning off restores the value from
-- MP.snapshot_baseline rather than nil.
function MP.write_layer_modifiers(name, on, mid_round)
	local layer = MP.Layers[name]
	local baseline = G.GAME.mp_switch_baseline
	write_round_deltas(name, layer, on, mid_round)
	local mods = G.GAME.modifiers
	if layer.flag then mods[layer.flag] = on or nil end
	for k, v in pairs(layer.game_modifiers or {}) do
		if type(v) == "table" then
			mods[k] = mods[k] or {}
			for kk, vv in pairs(v) do
				if on then
					mods[k][kk] = vv
				else
					local was = baseline and baseline[k] and baseline[k].v
					mods[k][kk] = type(was) == "table" and was[kk] or nil
				end
			end
		elseif on then
			mods[k] = v
		else
			mods[k] = baseline and baseline[k] and baseline[k].v
		end
	end
end

-- Values the run had before any switched layer touched them, so turning a layer
-- off restores the deck/stake value rather than nil. Boxed as { v = ... } so
-- "was nil" survives the save file. Call before the first switch.
function MP.snapshot_baseline(names)
	G.GAME.mp_switch_baseline = G.GAME.mp_switch_baseline or {}
	local base = G.GAME.mp_switch_baseline
	for _, name in ipairs(names) do
		local layer = MP.Layers[name]
		for k in pairs(layer and layer.game_modifiers or {}) do
			if base[k] == nil then
				local cur = G.GAME.modifiers[k]
				base[k] = { v = type(cur) == "table" and copy_table(cur) or cur }
			end
		end
	end
end

-- Called once at run start, right after ApplyBans. Every layer in the active
-- chain (ruleset layers + "on" modifiers) gets its modifiers written, then the
-- Chaos Clock builds its pool from what's left.
function MP.ApplyGameModifiers()
	for _, name in ipairs(MP.active_layer_chain()) do
		if MP.Layers[name] then MP.write_layer_modifiers(name, true) end
	end
	if MP.CHAOS_CLOCK then MP.CHAOS_CLOCK.start_run() end
end
