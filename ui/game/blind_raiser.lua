-------------------------------------------------------------------
-- EXPERIMENTAL (BLIND RAISER)
--
-- Ports the Blind Raiser feature from Handsome Devils into a
-- Multiplayer ruleset. While the ruleset is active, the current
-- Small or Big Blind may be upgraded into a random non-Showdown
-- Boss Blind. The displayed Skip Tag is granted immediately, but
-- the Blind slot itself is not skipped.
--
-- This implementation deliberately keeps its boss-use bookkeeping
-- separate from vanilla's G.GAME.bosses_used. A player choosing to
-- upgrade a Blind therefore does not alter future normal Boss rolls,
-- preserving Multiplayer's shared-seed behaviour between opponents
-- who make different Blind Raiser choices.
-------------------------------------------------------------------

MP.BLIND_RAISER = MP.BLIND_RAISER or {}
local BR = MP.BLIND_RAISER

local RULESET_KEY = "ruleset_mp_experimental_blind_raiser"

local function blind_raiser_active()
	return MP
		and MP.get_active_ruleset
		and MP.get_active_ruleset() == RULESET_KEY
end

BR.is_active = blind_raiser_active

-- Lovely progression patches use the physical Blind slot while Blind Raiser
-- is active, but preserve vanilla's original condition in every other ruleset.
function BR.slot_matches(slot, vanilla_result)
	if blind_raiser_active() then
		local live_blind = G and G.GAME and G.GAME.blind
		local physical_slot = live_blind
			and live_blind.mp_blind_raiser_replacement_slot
			or (G and G.GAME and G.GAME.blind_on_deck)
		return physical_slot == slot
	end
	return vanilla_result
end

local function current_ante()
	return G
		and G.GAME
		and G.GAME.round_resets
		and G.GAME.round_resets.ante
		or 0
end

-- blind_ante is the Ante attached to the physical Blind-select row. It is the
-- authoritative value for Blind Raiser records because a replacement Boss
-- definition must never make a Small/Big slot inherit Boss Ante progression.
local function current_slot_ante()
	local round_resets = G and G.GAME and G.GAME.round_resets
	return tonumber(round_resets and round_resets.blind_ante)
		or tonumber(round_resets and round_resets.ante)
		or 0
end

local function upgrade_key(blind_choice)
	return tostring(current_slot_ante()) .. ":" .. tostring(blind_choice)
end

local function upgraded_blinds()
	if not (G and G.GAME) then return {} end
	G.GAME.mp_blind_raiser_upgraded = G.GAME.mp_blind_raiser_upgraded or {}
	return G.GAME.mp_blind_raiser_upgraded
end

local function replacement_records()
	if not (G and G.GAME) then return {} end
	G.GAME.mp_blind_raiser_replacements = G.GAME.mp_blind_raiser_replacements or {}
	return G.GAME.mp_blind_raiser_replacements
end

local function raiser_bosses_used()
	if not (G and G.GAME) then return {} end
	G.GAME.mp_blind_raiser_bosses_used = G.GAME.mp_blind_raiser_bosses_used or {}
	return G.GAME.mp_blind_raiser_bosses_used
end

local function normalize_blind_choice(blind_choice)
	if type(blind_choice) ~= "string" then return nil end
	local normalized = blind_choice:lower()
	if normalized == "small" then return "Small" end
	if normalized == "big" then return "Big" end
	if normalized == "boss" then return "Boss" end
	return nil
end

local function record_key(ante, blind_choice)
	return tostring(ante) .. ":" .. tostring(blind_choice)
end

local function blind_key_from_definition(blind)
	if type(blind) ~= "table" then return nil end
	return blind.key
		or (blind.config and blind.config.key)
		or (blind.config and blind.config.blind and blind.config.blind.key)
end

local function current_choice_key(blind_choice)
	return G
		and G.GAME
		and G.GAME.round_resets
		and G.GAME.round_resets.blind_choices
		and G.GAME.round_resets.blind_choices[blind_choice]
		or nil
end

local function replacement_record(blind_choice, ante, expected_boss)
	blind_choice = normalize_blind_choice(blind_choice)
	if blind_choice ~= "Small" and blind_choice ~= "Big" then return nil end

	local records = replacement_records()
	local candidate_antes = {}
	local seen_antes = {}
	local function add_ante(value)
		value = tonumber(value)
		if value and not seen_antes[value] then
			seen_antes[value] = true
			candidate_antes[#candidate_antes + 1] = value
		end
	end

	add_ante(ante)
	add_ante(G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_ante)
	add_ante(current_ante())

	local selected_boss = expected_boss or current_choice_key(blind_choice)
	for _, candidate_ante in ipairs(candidate_antes) do
		local record = records[record_key(candidate_ante, blind_choice)]
		-- The physical slot + Ante is the primary identity. Do not reject its
		-- record merely because blind_choices is between animation states; doing
		-- so falls back to the replacement Boss multiplier in the select preview.
		if type(record) == "table" then return record end
	end

	-- Save migration and timing fallback: during select/start transitions,
	-- round_resets.ante, blind_ante and blind_on_deck can briefly disagree.
	-- Match the replacement Boss itself so the correct per-upgrade exponent is
	-- still used rather than falling back to the Boss Blind's normal multiplier.
	local best_record = nil
	local best_ante = -math.huge
	for key, record in pairs(records) do
		if type(record) == "table" then
			local key_ante, key_choice = key:match("^(-?%d+):([%a_]+)$")
			local record_choice = normalize_blind_choice(record.blind_choice or key_choice)
			local record_ante = tonumber(record.ante) or tonumber(key_ante)
			if record_choice == blind_choice
				and (not selected_boss or not record.boss or record.boss == selected_boss)
				and record_ante
				and record_ante >= best_ante
			then
				best_record = record
				best_ante = record_ante
			end
		end
	end
	return best_record
end

-------------------------------------------------------------------
-- Boss effect records
-------------------------------------------------------------------

local STACKABLE_BOSS_EFFECTS = {
	bl_hook = "bl_hook_the_hook",
	bl_ox = "bl_hook_the_ox",
	bl_house = "bl_hook_the_house",
	bl_wheel = "bl_hook_the_wheel",
	bl_arm = "bl_hook_the_arm",
	bl_club = "bl_hook_the_club",
	bl_fish = "bl_hook_the_fish",
	bl_psychic = "bl_hook_the_psychic",
	bl_goad = "bl_hook_the_goad",
	bl_window = "bl_hook_the_window",
	bl_manacle = "bl_hook_the_manacle",
	bl_eye = "bl_hook_the_eye",
	bl_mouth = "bl_hook_the_mouth",
	bl_plant = "bl_hook_the_plant",
	bl_serpent = "bl_hook_the_serpent",
	bl_pillar = "bl_hook_the_pillar",
	bl_head = "bl_hook_the_head",
	bl_mark = "bl_hook_the_mark",
	bl_flint = "bl_hook_the_flint",
	bl_water = "bl_hook_the_water",
	bl_tooth = "bl_hook_the_tooth",
}

BR.STACKABLE_BOSS_EFFECTS = STACKABLE_BOSS_EFFECTS

local function boss_choice()
	return G
		and G.GAME
		and G.GAME.round_resets
		and G.GAME.round_resets.blind_choices
		and G.GAME.round_resets.blind_choices.Boss
		or nil
end

function BR.boss_effects_for_ante(ante)
	ante = tonumber(ante) or current_slot_ante()
	local effects = {}
	local seen = {}
	local records = replacement_records()
	for _, blind_choice in ipairs({ "Small", "Big" }) do
		local record = records[record_key(ante, blind_choice)]
		local key = type(record) == "table" and record.boss or nil
		if key and STACKABLE_BOSS_EFFECTS[key] and not seen[key] then
			seen[key] = true
			effects[#effects + 1] = key
		end
	end
	return effects
end

function BR.boss_upgrade_count_for_ante(ante)
	return #BR.boss_effects_for_ante(ante)
end

local function append_plus_to_name(loc_name)
	if type(loc_name) == "string" then
		return loc_name:match("%+$") and loc_name or (loc_name .. "+")
	end
	if type(loc_name) == "table" then
		local copy = {}
		for key, value in pairs(loc_name) do copy[key] = value end
		local function append_last_string(node)
			local last_numeric = nil
			for key in pairs(node) do
				if type(key) == "number" and (not last_numeric or key > last_numeric) then
					last_numeric = key
				end
			end
			if not last_numeric then return false end
			local value = node[last_numeric]
			if type(value) == "string" then
				node[last_numeric] = value:match("%+$") and value or (value .. "+")
				return true
			elseif type(value) == "table" then
				local nested = {}
				for key, nested_value in pairs(value) do nested[key] = nested_value end
				node[last_numeric] = nested
				return append_last_string(nested)
			end
			return false
		end
		append_last_string(copy)
		return copy
	end
	return loc_name
end

function BR.display_name(blind_choice, loc_name)
	if blind_raiser_active()
		and blind_choice == "Boss"
		and BR.boss_upgrade_count_for_ante(current_slot_ante()) > 0
	then
		return append_plus_to_name(loc_name)
	end
	return loc_name
end

function BR.regular_score_for_slot(blind_choice, ante)
	blind_choice = normalize_blind_choice(blind_choice)
	if blind_choice ~= "Small" and blind_choice ~= "Big" then return nil end
	if not (G and G.GAME and G.P_BLINDS and type(get_blind_amount) == "function") then return nil end

	local base_blind = G.P_BLINDS["bl_" .. blind_choice:lower()]
	if not (base_blind and base_blind.mult) then return nil end

	local score_ante = tonumber(ante) or current_slot_ante()
	local ante_scaling = G.GAME.starting_params and G.GAME.starting_params.ante_scaling or 1
	return get_blind_amount(score_ante) * base_blind.mult * ante_scaling
end

function BR.upgrade_count()
	return G and G.GAME
		and math.max(0, tonumber(G.GAME.mp_blind_raiser_upgrade_count) or 0)
		or 0
end

-- The next score exponent is deliberately separate from the number of Blind
-- upgrades bought. Record hands skip exponent steps in complete groups of
-- three, repeating for as many full groups as the highest hand can clear,
-- without granting Investment Tag money or creating phantom Boss effects.
function BR.next_exponent_step()
	if not (G and G.GAME) then return BR.upgrade_count() + 1 end
	local minimum = BR.upgrade_count() + 1
	local stored = math.floor(tonumber(G.GAME.mp_blind_raiser_next_exponent) or minimum)
	stored = math.max(1, minimum, stored)
	G.GAME.mp_blind_raiser_next_exponent = stored
	return stored
end

function BR.set_next_exponent_step(step)
	if not (G and G.GAME) then return end
	local minimum = BR.upgrade_count() + 1
	G.GAME.mp_blind_raiser_next_exponent = math.max(1, minimum, math.floor(tonumber(step) or minimum))
end

local function normalized_insane_int(value)
	if value == nil or not (MP and MP.INSANE_INT and MP.INSANE_INT.create) then return nil end

	local raw = tostring(value):lower():gsub(",", ""):gsub("%s+", "")
	if raw == "" then return nil end

	-- Multiplayer's old parser stores plain 10000 as coefficient 10000/e0 but
	-- scientific 1e4 as coefficient 1/e4, which makes equal values compare as
	-- different magnitudes. Normalize every representation to scientific form.
	local e_count = 0
	while raw:sub(1, 1) == "e" do
		e_count = e_count + 1
		raw = raw:sub(2)
	end

	local coefficient_text, explicit_exponent = raw:match("^([%+%-]?[%d%.]+)e([%+%-]?%d+)$")
	if not coefficient_text then
		coefficient_text = raw
		explicit_exponent = 0
	else
		explicit_exponent = tonumber(explicit_exponent) or 0
	end

	local sign = 1
	if coefficient_text:sub(1, 1) == "-" then
		sign = -1
		coefficient_text = coefficient_text:sub(2)
	elseif coefficient_text:sub(1, 1) == "+" then
		coefficient_text = coefficient_text:sub(2)
	end

	local integer, fraction = coefficient_text:match("^(%d*)%.?(%d*)$")
	if integer == nil then return nil end
	integer = integer or ""
	fraction = fraction or ""

	local nonzero_integer = integer:match("^0*(%d.*)$")
	local significant
	local exponent
	if nonzero_integer and nonzero_integer:find("[1-9]") then
		nonzero_integer = nonzero_integer:gsub("^0+", "")
		significant = nonzero_integer .. fraction
		exponent = #nonzero_integer - 1 + explicit_exponent
	else
		local first_nonzero = fraction:find("[1-9]")
		if not first_nonzero then return MP.INSANE_INT.empty() end
		significant = fraction:sub(first_nonzero)
		exponent = explicit_exponent - first_nonzero
	end

	-- Fifteen significant digits are ample for ordering thresholds while
	-- avoiding floating-point overflow from very long Big-number strings.
	local head = significant:sub(1, 1)
	local tail = significant:sub(2, 15)
	local coefficient = tonumber(head .. (tail ~= "" and ("." .. tail) or "")) or 0
	return MP.INSANE_INT.create(sign * coefficient, exponent, e_count)
end

local function insane_int_at_least(left, right)
	if not (left and right and MP and MP.INSANE_INT) then return false end
	return MP.INSANE_INT.greater_than(left, right) or MP.INSANE_INT.equal(left, right)
end

local function exponent_threshold(base_score, step)
	local threshold_value
	if type(to_big) == "function" then
		local ok, result = pcall(function()
			return to_big(base_score) * (to_big(2) ^ step)
		end)
		if ok then threshold_value = result end
	end
	if threshold_value == nil then threshold_value = base_score * (2 ^ step) end
	return normalized_insane_int(threshold_value)
end

local function stored_highest_hand()
	if not (G and G.GAME) then return nil end
	local stored = G.GAME.mp_blind_raiser_highest_hand_score
	if type(stored) == "table"
		and stored.coeffiocient ~= nil
		and stored.exponent ~= nil
		and stored.e_count ~= nil
	then
		return stored
	end
	return normalized_insane_int(stored)
end

-- Called from the universal completed-hand scoring path. This deliberately
-- does not use MP.ACTIONS.play_hand: that networking action only runs during
-- the PvP Blind, which left Small/Big/Boss hands completely unobserved.
function BR.on_hand_scored(hand_score)
	if not blind_raiser_active() or hand_score == nil or not (G and G.GAME) then return end

	local normalized_score = normalized_insane_int(hand_score)
	if not normalized_score then return end
	local zero = MP.INSANE_INT.empty()
	if not MP.INSANE_INT.greater_than(normalized_score, zero) then return end

	-- Keep the best hand seen this run, but always re-evaluate the stored best
	-- score. This recovers correctly if a compatibility mod replaced a score
	-- hook for one hand and our wrapper is restored before the next hand.
	local previous = stored_highest_hand() or zero
	local highest = previous
	if MP.INSANE_INT.greater_than(normalized_score, previous) then
		highest = normalized_score
		G.GAME.mp_blind_raiser_highest_hand_score = normalized_score
	end

	-- During a played Blind, round_resets.ante is authoritative. blind_ante is
	-- a Blind-select preview field and can remain stale across Ante transitions.
	local next_ante = math.max(1, current_ante() + 1)
	local base_score = BR.regular_score_for_slot("Small", next_ante)
	if not base_score then return end

	local step = BR.next_exponent_step()
	local original_step = step

	-- Catch-up advances in complete groups of three exponent steps. Passing the
	-- last threshold of a group guarantees its two lower thresholds were also
	-- passed, so a group is atomic: either all three steps are skipped or none
	-- are. Successful groups repeat until the next complete group fails.
	local function full_groups_pass(group_count)
		if group_count < 1 then return true end
		local final_step = step + (group_count * 3) - 1
		local threshold = exponent_threshold(base_score, final_step)
		return threshold ~= nil and insane_int_at_least(highest, threshold)
	end

	local passed_groups = 0
	if full_groups_pass(1) then
		-- Find a failing upper bound exponentially, then binary-search the exact
		-- number of complete three-step groups. This keeps giant-score catch-up
		-- fast while preserving the same stop-on-first-failed-group behaviour.
		local lower = 1
		local upper = 2
		local max_safe_groups = 1073741824 -- 2^30 groups; avoids Lua integer drift.

		while upper < max_safe_groups and full_groups_pass(upper) do
			lower = upper
			upper = upper * 2
		end

		if upper >= max_safe_groups and full_groups_pass(max_safe_groups) then
			passed_groups = max_safe_groups
		else
			local lo = lower + 1
			local hi = math.min(upper - 1, max_safe_groups)
			passed_groups = lower
			while lo <= hi do
				local mid = math.floor((lo + hi) / 2)
				if full_groups_pass(mid) then
					passed_groups = mid
					lo = mid + 1
				else
					hi = mid - 1
				end
			end
		end
	end

	if passed_groups > 0 then
		step = step + (passed_groups * 3)
	end

	if step > original_step then BR.set_next_exponent_step(step) end
end

-- Backwards-compatible name for any add-on that already calls this hook with
-- an actual hand score. Multiplayer's cumulative network score no longer does.
BR.on_new_highest_hand = BR.on_hand_scored

-- Hook both authoritative completed-hand signals instead of relying on a
-- Lovely injection inside evaluate_play. Multiplayer/Steamodded can replace
-- that function after Lovely applies, but a completed scoring hand still calls
-- check_and_set_high_score("hand", score) and check_for_unlock({type =
-- "chip_score", chips = score}). Either path is sufficient; duplicate calls are
-- harmless because the first call advances through every complete batch the
-- stored highest hand can clear, leaving the second call at the same failure.
local function install_hand_score_hooks()
    local installed = false

    if type(check_and_set_high_score) == "function"
        and check_and_set_high_score ~= BR._hand_high_score_hook
    then
        local previous_high_score = check_and_set_high_score
        local high_score_wrapper
        high_score_wrapper = function(score_type, amount, ...)
            local result = previous_high_score(score_type, amount, ...)
            if score_type == "hand" and BR.on_hand_scored then
                BR.on_hand_scored(amount)
            end
            return result
        end
        BR._hand_high_score_hook = high_score_wrapper
        BR._hand_high_score_hook_previous = previous_high_score
        check_and_set_high_score = high_score_wrapper
        installed = true
    elseif check_and_set_high_score == BR._hand_high_score_hook then
        installed = true
    end

    if type(check_for_unlock) == "function"
        and check_for_unlock ~= BR._chip_score_unlock_hook
    then
        local previous_check_for_unlock = check_for_unlock
        local unlock_wrapper
        unlock_wrapper = function(args, ...)
            local result = previous_check_for_unlock(args, ...)
            if type(args) == "table"
                and args.type == "chip_score"
                and args.chips ~= nil
                and BR.on_hand_scored
            then
                BR.on_hand_scored(args.chips)
            end
            return result
        end
        BR._chip_score_unlock_hook = unlock_wrapper
        BR._chip_score_unlock_hook_previous = previous_check_for_unlock
        check_for_unlock = unlock_wrapper
        installed = true
    elseif check_for_unlock == BR._chip_score_unlock_hook then
        installed = true
    end

    return installed
end

BR.install_hand_score_hooks = install_hand_score_hooks
install_hand_score_hooks()

if Game and type(Game.start_run) == "function" and not BR._start_run_score_hook_installed then
    BR._start_run_score_hook_installed = true
    local game_start_run_ref = Game.start_run
    function Game:start_run(...)
        -- Install before and after start_run: after wins over wrappers that are
        -- installed during run initialization by compatibility modules.
        install_hand_score_hooks()
        local result = game_start_run_ref(self, ...)
        install_hand_score_hooks()
        return result
    end
end

function BR.next_upgrade_score_for_slot(blind_choice, ante)
	if not blind_raiser_active() then return nil end
	blind_choice = normalize_blind_choice(blind_choice)
	if blind_choice ~= "Small" and blind_choice ~= "Big" then return nil end

	local base_score = BR.regular_score_for_slot(blind_choice, ante or current_slot_ante())
	if not base_score then return nil end
	return base_score * (2 ^ BR.next_exponent_step())
end

local function dictionary_text(key, vars, fallback)
	local text = localize(key)
	if type(text) == "table" then text = text[1] end
	if type(text) ~= "string" or text == "" or text == key then text = fallback end
	for i, value in ipairs(vars or {}) do
		text = text:gsub("#" .. tostring(i) .. "#", tostring(value))
	end
	return text
end

function BR.upgrade_button_tooltip(blind_choice)
	local upgrade_count = BR.upgrade_count()
	local next_score = BR.next_upgrade_score_for_slot(blind_choice, current_slot_ante())
	local formatted_score = next_score and number_format(next_score) or "?"

	return {
		text = {
			dictionary_text(
				"mp_blind_raiser_tooltip_upgrades",
				{ upgrade_count },
				"Blind upgrades this game: " .. tostring(upgrade_count)
			),
			dictionary_text(
				"mp_blind_raiser_tooltip_score",
				{ formatted_score },
				"Score if upgraded: " .. tostring(formatted_score)
			),
		},
	}
end

local function upgrade_index_for(blind_choice, ante, expected_boss)
	local record = replacement_record(blind_choice, ante, expected_boss)
	if type(record) ~= "table" then return nil, nil end

	local index = tonumber(record.upgrade_index)
	if not index or index < 1 then
		-- Migration for saves created before escalating score requirements were
		-- added. Prefer the stored run-wide count, then fall back to the first
		-- upgrade so old saves remain playable.
		index = tonumber(G.GAME.mp_blind_raiser_upgrade_count) or 1
		record.upgrade_index = math.max(1, index)
	end
	return math.max(1, index), record
end

local function score_from_record(blind_choice, ante, record, upgrade_index)
	local base_score = tonumber(record and record.base_score)
	if not base_score then
		base_score = BR.regular_score_for_slot(
			blind_choice,
			(record and tonumber(record.ante)) or ante
		)
		if record and base_score then record.base_score = base_score end
	end
	if not base_score then return nil end

	local multiplier = 2 ^ upgrade_index
	if record then
		record.score_multiplier = multiplier
		record.score_chips = base_score * multiplier
	end
	return base_score * multiplier
end

local function slot_is_pvp(blind_choice, blind)
	local key = blind_key_from_definition(blind)
	if key == "bl_mp_nemesis" then return true end
	local resets = G and G.GAME and G.GAME.round_resets
	if resets and resets.pvp_blind_choices
		and resets.pvp_blind_choices[blind_choice]
	then
		return true
	end
	local live = G and G.GAME and G.GAME.blind
	if live and live.pvp == true then
		local live_key = blind_key_from_definition(live.config and live.config.blind)
		return not blind or not key or key == live_key
	end
	return false
end

function BR.real_boss_score(vanilla_amount, ante, blind)
	if not blind_raiser_active() then return vanilla_amount end
	if slot_is_pvp("Boss", blind) then return vanilla_amount end
	local upgrades_this_ante = BR.boss_upgrade_count_for_ante(ante or current_slot_ante())
	if upgrades_this_ante < 1 then return vanilla_amount end
	return vanilla_amount * (2 ^ upgrades_this_ante)
end

function BR.score_for_slot(blind_choice, vanilla_amount, ante, expected_boss)
	if not blind_raiser_active() then return vanilla_amount end
	blind_choice = normalize_blind_choice(blind_choice)
	if blind_choice == "Boss" then
		return BR.real_boss_score(vanilla_amount, ante, expected_boss and G.P_BLINDS and G.P_BLINDS[expected_boss])
	end
	if blind_choice ~= "Small" and blind_choice ~= "Big" then return vanilla_amount end

	local upgrade_index, record = upgrade_index_for(blind_choice, ante, expected_boss)
	if not upgrade_index then return vanilla_amount end
	return score_from_record(blind_choice, ante, record, upgrade_index) or vanilla_amount
end

-- Blind-select UI must use the score saved for the physical slot, never the
-- replacement Boss definition's mult. This direct path deliberately ignores
-- the transient blind_choices value while the old UIBox is being replaced.
function BR.preview_score_for_slot(blind_choice, vanilla_amount)
	if not blind_raiser_active() then return vanilla_amount end
	blind_choice = normalize_blind_choice(blind_choice)
	if blind_choice == "Boss" then
		local key = current_choice_key("Boss")
		local blind = key and G.P_BLINDS and G.P_BLINDS[key]
		return BR.real_boss_score(vanilla_amount, current_slot_ante(), blind)
	end
	if blind_choice ~= "Small" and blind_choice ~= "Big" then return vanilla_amount end

	local record = replacement_record(blind_choice, current_slot_ante())
	if type(record) ~= "table" then return vanilla_amount end
	local index = math.max(1, tonumber(record.upgrade_index) or 1)
	return score_from_record(blind_choice, record.ante or current_slot_ante(), record, index) or vanilla_amount
end

function BR.score_for_blind(blind, preferred_choice, vanilla_amount, ante)
	if not blind_raiser_active() then return vanilla_amount end
	local blind_key = blind_key_from_definition(blind)
	local blind_choice = normalize_blind_choice(preferred_choice)

	-- The replacement Boss key is the strongest identity while Blind:set_blind
	-- is running because blind_on_deck can briefly point at the next slot. If
	-- both rows somehow share the same Boss, retain the preferred physical slot.
	local matching_choices = {}
	if blind_key then
		for _, candidate in ipairs({ "Small", "Big" }) do
			if current_choice_key(candidate) == blind_key
				and replacement_record(candidate, ante, blind_key)
			then
				matching_choices[#matching_choices + 1] = candidate
			end
		end
	end
	if #matching_choices == 1 then
		blind_choice = matching_choices[1]
	elseif not (blind_choice and replacement_record(blind_choice, ante)) and #matching_choices > 0 then
		blind_choice = matching_choices[1]
	end

	if blind_choice == "Boss" then
		return BR.real_boss_score(vanilla_amount, ante, blind)
	end
	return BR.score_for_slot(blind_choice, vanilla_amount, ante, blind_key)
end

local function parse_upgrade_key(key)
	if type(key) ~= "string" then return nil, nil end
	local ante, blind_choice = key:match("^(-?%d+):([%a_]+)$")
	return tonumber(ante), blind_choice
end

local function blind_state(blind_choice)
	return G
		and G.GAME
		and G.GAME.round_resets
		and G.GAME.round_resets.blind_states
		and G.GAME.round_resets.blind_states[blind_choice]
end

local function blind_is_finished(blind_choice)
	local state = blind_state(blind_choice)
	return state == "Defeated" or state == "Skipped"
end

local function blind_was_upgraded(blind_choice)
	return upgraded_blinds()[upgrade_key(blind_choice)] == true
end

local function blind_is_current(blind_choice)
	if not blind_raiser_active() or blind_is_finished(blind_choice) then return false end

	-- Steamodded beta-1620a advances the selectable slot by changing its
	-- state to Select. blind_on_deck can lag during the Skip animation.
	local state = blind_state(blind_choice)
	if state == "Select" then return true end

	-- Defensive fallback for modded Blind-select screens that initialize the
	-- state table after constructing the UI.
	return state == nil
		and G
		and G.GAME
		and G.GAME.blind_on_deck == blind_choice
end

local function can_upgrade(blind_choice)
	return (blind_choice == "Small" or blind_choice == "Big")
		and blind_is_current(blind_choice)
		and not blind_was_upgraded(blind_choice)
end

-------------------------------------------------------------------
-- Deterministic, Ante-legal Boss selection
-------------------------------------------------------------------

local STATIC_UPGRADE_BANS = {
	bl_wall = true,
	bl_needle = true,
}

local function blind_is_in_pool(blind)
	if type(blind.in_pool) ~= "function" then return true end
	local ok, result = pcall(blind.in_pool, blind)
	return ok and result ~= false
end

local function candidate_is_ante_eligible(blind, ante)
	local boss = blind and blind.boss
	if not boss then return false end
	ante = tonumber(ante) or current_slot_ante()
	if boss.min and ante < boss.min then return false end
	if boss.max and ante > boss.max then return false end
	return true
end

local function upgraded_bosses_for_ante(ante)
	local used = {}
	for _, key in ipairs(BR.boss_effects_for_ante(ante)) do used[key] = true end
	return used
end

local CARD_DEBUFFER_BOSSES = {
	bl_plant = true,
	bl_club = true,
	bl_goad = true,
	bl_window = true,
	bl_head = true,
	bl_mark = true,
	bl_psychic = true,
	bl_pillar = true,
}

local CARD_FLIPPER_BOSSES = {
	bl_house = true,
	bl_wheel = true,
	bl_fish = true,
	bl_mark = true,
}

local FORBIDDEN_BOSS_PAIRS = {
	{ "bl_plant", "bl_mark" },
	{ "bl_needle", "bl_wall" },
	{ "bl_needle", "bl_water" },
	{ "bl_eye", "bl_mouth" },
}

local function boss_combo_invalid(existing, candidate)
	local present = {}
	local debuffers = 0
	local flippers = 0

	for _, key in ipairs(existing or {}) do
		if key and not present[key] then
			present[key] = true
			if CARD_DEBUFFER_BOSSES[key] then debuffers = debuffers + 1 end
			if CARD_FLIPPER_BOSSES[key] then flippers = flippers + 1 end
		end
	end

	if candidate then
		if present[candidate] then return true end
		present[candidate] = true
		if CARD_DEBUFFER_BOSSES[candidate] then debuffers = debuffers + 1 end
		if CARD_FLIPPER_BOSSES[candidate] then flippers = flippers + 1 end
	end

	if debuffers > 1 or flippers > 1 then return true end
	for _, pair in ipairs(FORBIDDEN_BOSS_PAIRS) do
		if present[pair[1]] and present[pair[2]] then return true end
	end
	return false
end

BR.boss_combo_invalid = boss_combo_invalid

local function upgrade_combo_bosses(ante)
	local existing = {}
	local current = boss_choice()
	if current then existing[#existing + 1] = current end
	for _, key in ipairs(BR.boss_effects_for_ante(ante)) do
		existing[#existing + 1] = key
	end
	return existing
end

local function boss_is_valid(key, ante, relaxed_pool)
	local blind = key and G.P_BLINDS and G.P_BLINDS[key]
	if not STACKABLE_BOSS_EFFECTS[key] then return false end
	if key == "bl_mp_nemesis" then return false end
	if STATIC_UPGRADE_BANS[key] then return false end
	if not (blind and blind.boss) or blind.boss.showdown then return false end
	if G.GAME.banned_keys and G.GAME.banned_keys[key] then return false end
	if key == boss_choice() then return false end
	if upgraded_bosses_for_ante(ante)[key] then return false end
	if boss_combo_invalid(upgrade_combo_bosses(ante), key) then return false end
	if not candidate_is_ante_eligible(blind, ante) then return false end
	if not relaxed_pool and not blind_is_in_pool(blind) then return false end
	return true
end

local function choose_from_eligible_pool(blind_choice, relaxed_pool)
	local ante = current_slot_ante()
	local candidates = {}
	local base_uses = G.GAME.bosses_used or {}
	local extra_uses = raiser_bosses_used()
	local minimum_uses = nil

	for key in pairs(STACKABLE_BOSS_EFFECTS) do
		if boss_is_valid(key, ante, relaxed_pool) then
			local uses = (base_uses[key] or 0) + (extra_uses[key] or 0)
			if minimum_uses == nil or uses < minimum_uses then minimum_uses = uses end
			candidates[#candidates + 1] = { key = key, uses = uses }
		end
	end

	local filtered = {}
	for _, candidate in ipairs(candidates) do
		if candidate.uses == minimum_uses then filtered[#filtered + 1] = candidate.key end
	end
	table.sort(filtered)
	if #filtered == 0 then return nil end

	return pseudorandom_element(
		filtered,
		pseudoseed(
			"mp_blind_raiser_" .. tostring(ante)
				.. "_" .. tostring(blind_choice)
				.. "_" .. tostring(BR.boss_upgrade_count_for_ante(ante) + 1)
		)
	)
end

function BR.choose_boss(blind_choice)
	if not (G and G.GAME and G.P_BLINDS) then return nil end
	return choose_from_eligible_pool(blind_choice, false)
		or choose_from_eligible_pool(blind_choice, true)
end

-- A Boss reroll replaces the real Boss, so validate the candidate against
-- only the already-upgraded Small/Big components. Wall and Needle remain legal
-- real Bosses; they are banned only as upgrade targets.
function BR.reroll_boss_candidate_is_compatible(key, ante)
	if not (G and G.GAME) then return true end
	ante = tonumber(ante) or current_slot_ante()
	local upgraded = upgraded_bosses_for_ante(ante)
	if not next(upgraded) then return true end
	if upgraded[key] then return false end

	local existing = {}
	for upgraded_key in pairs(upgraded) do existing[#existing + 1] = upgraded_key end
	return not boss_combo_invalid(existing, key)
end

function BR.call_with_reroll_bans(selector)
	if type(selector) ~= "function" then return nil end
	if not blind_raiser_active() or not (G and G.GAME and G.P_BLINDS) then
		return selector()
	end

	local ante = current_slot_ante()
	local upgraded = upgraded_bosses_for_ante(ante)
	if not next(upgraded) then return selector() end

	local had_banned_table = type(G.GAME.banned_keys) == "table"
	local banned = had_banned_table and G.GAME.banned_keys or {}
	G.GAME.banned_keys = banned
	local temporarily_banned = {}

	for key, blind in pairs(G.P_BLINDS) do
		if blind and blind.boss
			and not blind.boss.showdown
			and not banned[key]
			and not BR.reroll_boss_candidate_is_compatible(key, ante)
		then
			banned[key] = true
			temporarily_banned[#temporarily_banned + 1] = key
		end
	end

	local ok, result = pcall(selector)
	for _, key in ipairs(temporarily_banned) do banned[key] = nil end
	if not had_banned_table and next(banned) == nil then G.GAME.banned_keys = nil end
	if not ok then error(result) end
	return result
end

-- Boss Reroll voucher/tag callbacks both call get_new_boss(). Filtering at this
-- shared boundary keeps their normal UI/update flow intact and also covers
-- other compatible reroll sources.
if not BR._unrestricted_get_new_boss then
	BR._unrestricted_get_new_boss = get_new_boss
	function get_new_boss()
		return BR.call_with_reroll_bans(BR._unrestricted_get_new_boss)
	end
end

-------------------------------------------------------------------
-- Ante transition cleanup
-------------------------------------------------------------------

function BR.restore_stale_slots()
	if not blind_raiser_active() then return end
	if not (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_choices) then return end

	local ante = current_ante()
	if G.GAME.mp_blind_raiser_boss_stack_active
		and tonumber(G.GAME.mp_blind_raiser_boss_stack_ante) ~= tonumber(ante)
		and BR.stop_boss_stack
	then
		BR.stop_boss_stack()
	end
	local choices = G.GAME.round_resets.blind_choices
	local upgrades = upgraded_blinds()
	local records = replacement_records()

	local stale_record_keys = {}
	for key, record in pairs(records) do
		local key_ante, key_choice = parse_upgrade_key(key)
		local blind_choice = type(record) == "table" and record.blind_choice or key_choice
		local record_ante = type(record) == "table" and tonumber(record.ante) or key_ante

		if record_ante and record_ante ~= ante
			and (blind_choice == "Small" or blind_choice == "Big")
		then
			if type(record) == "table" and choices[blind_choice] == record.boss then
				choices[blind_choice] = record.original or ("bl_" .. blind_choice:lower())
			end
			stale_record_keys[#stale_record_keys + 1] = key
		end
	end
	for _, key in ipairs(stale_record_keys) do
		records[key] = nil
	end

	-- Migration/failsafe for saves from a partially applied build: a stale
	-- per-Ante lock on a Boss-filled Small/Big slot restores the vanilla slot.
	for key, was_upgraded in pairs(upgrades) do
		local key_ante, blind_choice = parse_upgrade_key(key)
		if was_upgraded and key_ante and key_ante ~= ante
			and (blind_choice == "Small" or blind_choice == "Big")
		then
			local choice = choices[blind_choice]
			local blind = choice and G.P_BLINDS and G.P_BLINDS[choice]
			if blind and blind.boss then
				choices[blind_choice] = "bl_" .. blind_choice:lower()
			end
		end
	end

	local stale_upgrade_keys = {}
	for key in pairs(upgrades) do
		local key_ante = parse_upgrade_key(key)
		if key_ante and key_ante ~= ante then stale_upgrade_keys[#stale_upgrade_keys + 1] = key end
	end
	for _, key in ipairs(stale_upgrade_keys) do
		upgrades[key] = nil
	end
end

function BR.skip_is_locked(blind_choice)
	return blind_raiser_active()
		and blind_choice ~= nil
		and blind_was_upgraded(blind_choice)
end

-- This wrapper is loaded before ui/game/round.lua. Multiplayer's later
-- reset_blinds wrapper therefore calls through this cleanup before applying
-- its gamemode-specific Blind replacements.
if type(reset_blinds) == "function" then
	local reset_blinds_ref = reset_blinds
	function reset_blinds(...)
		BR.restore_stale_slots()
		return reset_blinds_ref(...)
	end
end

if type(create_UIBox_blind_select) == "function" then
	local create_UIBox_blind_select_ref = create_UIBox_blind_select
	function create_UIBox_blind_select(...)
		BR.restore_stale_slots()
		return create_UIBox_blind_select_ref(...)
	end
end

-------------------------------------------------------------------
-- Blind tag UI
-------------------------------------------------------------------

local function set_runtime_button(button, active, callback)
	if not (button and button.config) then return end

	button.config.button = active and callback or nil
	button.config.hover = active
	button.config.colour = active and G.C.RED or G.C.UI.BACKGROUND_INACTIVE

	-- UIElement:set_values only enables collision/click states when a button
	-- exists during construction. Future Blind actions are initially inactive,
	-- so synchronize those runtime states as the current slot advances.
	if button.states then
		if button.states.collide then button.states.collide.can = active end
		if button.states.click then button.states.click.can = active end
		if button.states.hover then button.states.hover.can = active end
	end

	local label = button.children and button.children[1]
	if label and label.config then
		label.config.colour = active and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE
	end
end

local function ui_root_candidates(e, blind_choice)
	local roots = {}

	if e and e.UIBox then roots[#roots + 1] = e.UIBox end

	local blind_option = G
		and G.blind_select_opts
		and blind_choice
		and G.blind_select_opts[blind_choice:lower()]

	if blind_option then
		roots[#roots + 1] = blind_option
		if blind_option.parent then
			roots[#roots + 1] = blind_option.parent
			if blind_option.parent.config and blind_option.parent.config.object then
				roots[#roots + 1] = blind_option.parent.config.object
			end
		end
	end

	return roots
end

local function get_runtime_element(e, blind_choice, id)
	for _, root in ipairs(ui_root_candidates(e, blind_choice)) do
		if root and root.get_UIE_by_ID then
			local element = root:get_UIE_by_ID(id)
			if element then return element end
		end
	end
	return nil
end

function BR.sync_tag_ui(e)
	if not (blind_raiser_active() and e and e.config) then return end

	local blind_choice = e.config.id
	if not blind_choice then return end

	local upgraded = blind_was_upgraded(blind_choice)
	local current = blind_is_current(blind_choice)

	local upgrade_button = get_runtime_element(
		e,
		blind_choice,
		"mp_blind_raiser_upgrade_button_" .. blind_choice
	)
	set_runtime_button(
		upgrade_button,
		current and not upgraded,
		"mp_blind_raiser_upgrade"
	)

	local skip_button = get_runtime_element(
		e,
		blind_choice,
		"mp_blind_raiser_skip_button_" .. blind_choice
	)
	set_runtime_button(skip_button, current and not upgraded, "skip_blind")
end

G.FUNCS.mp_blind_raiser_update_skip_button = function(e)
	if not (e and e.config) then return end

	local blind_choice = e.config.mp_blind_raiser_choice
	local active = blind_choice
		and blind_is_current(blind_choice)
		and not blind_was_upgraded(blind_choice)
	set_runtime_button(e, active, "skip_blind")
	if G.FUNCS.hover_tag_proxy then G.FUNCS.hover_tag_proxy(e) end
end

G.FUNCS.mp_blind_raiser_update_upgrade_button = function(e)
	if not (e and e.config) then return end

	local blind_choice = e.config.mp_blind_raiser_choice
	set_runtime_button(e, blind_choice and can_upgrade(blind_choice), "mp_blind_raiser_upgrade")
	-- Keep the tooltip live so an untouched Big Blind button immediately reflects
	-- an upgrade made to the Small Blind without rebuilding the whole screen.
	e.config.tooltip = BR.upgrade_button_tooltip(blind_choice)
end

local create_UIBox_blind_tag_ref = create_UIBox_blind_tag

function create_UIBox_blind_tag(blind_choice, run_info)
	if run_info or not blind_raiser_active() then
		return create_UIBox_blind_tag_ref(blind_choice, run_info)
	end

	G.GAME.round_resets.blind_tags = G.GAME.round_resets.blind_tags or {}
	local tag_key = G.GAME.round_resets.blind_tags[blind_choice]
	if not tag_key then return create_UIBox_blind_tag_ref(blind_choice, run_info) end

	local reward_tag = Tag(tag_key, nil, blind_choice)
	local tag_ui, tag_sprite = reward_tag:generate_UI()

	if tag_sprite and tag_sprite.states and tag_sprite.states.collide then
		tag_sprite.states.collide.can = false
	end

	local upgrade_active = can_upgrade(blind_choice)
	local skip_active = blind_is_current(blind_choice) and not blind_was_upgraded(blind_choice)

	-- Preserve the vanilla/BlindRaiser child order. beta-1620a's Blind-select
	-- callback accesses the tag description and Skip button by fixed index.
	return {
		n = G.UIT.R,
		config = {
			id = "tag_container",
			ref_table = reward_tag,
			align = "cm",
		},
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "tm", minh = 0.65 },
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_or"),
							scale = 0.55,
							colour = G.C.WHITE,
							shadow = true,
						},
					},
				},
			},
			{
				n = G.UIT.R,
				config = {
					id = "tag_" .. blind_choice,
					align = "cm",
					r = 0.1,
					padding = 0.1,
					minw = 2.2,
					can_collide = true,
					ref_table = tag_sprite,
				},
				nodes = {
					{
						n = G.UIT.R,
						config = {
							id = "tag_desc",
							align = "cm",
							minh = 1,
						},
						nodes = { tag_ui },
					},
					{
						n = G.UIT.R,
						config = {
							id = "mp_blind_raiser_skip_button_" .. blind_choice,
							align = "cm",
							colour = skip_active and G.C.RED or G.C.UI.BACKGROUND_INACTIVE,
							minh = 0.6,
							minw = 2,
							maxw = 2,
							padding = 0.07,
							r = 0.1,
							shadow = true,
							hover = skip_active,
							one_press = true,
							button = skip_active and "skip_blind" or nil,
							func = "mp_blind_raiser_update_skip_button",
							insta_func = true,
							ref_table = reward_tag,
							mp_blind_raiser_choice = blind_choice,
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = localize("b_skip_blind"),
									scale = 0.4,
									colour = skip_active and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE,
								},
							},
						},
					},
					{
						n = G.UIT.R,
						config = {
							id = "mp_blind_raiser_upgrade_button_" .. blind_choice,
							align = "cm",
							colour = upgrade_active and G.C.RED or G.C.UI.BACKGROUND_INACTIVE,
							minh = 0.6,
							minw = 2,
							maxw = 2,
							padding = 0.07,
							r = 0.1,
							shadow = true,
							hover = true,
							one_press = true,
							button = upgrade_active and "mp_blind_raiser_upgrade" or nil,
							func = "mp_blind_raiser_update_upgrade_button",
							insta_func = true,
							ref_table = reward_tag,
							mp_blind_raiser_choice = blind_choice,
							tooltip = BR.upgrade_button_tooltip(blind_choice),
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = localize("mp_upgrade_blind"),
									scale = 0.4,
									colour = upgrade_active and G.C.UI.TEXT_LIGHT
										or G.C.UI.TEXT_INACTIVE,
								},
							},
						},
					},
				},
			},
		},
	}
end

-------------------------------------------------------------------
-- Upgrade action
-------------------------------------------------------------------

G.FUNCS.mp_blind_raiser_upgrade = function(e)
	if not (e and e.config and G and G.GAME) then return end

	local blind_choice = e.config.mp_blind_raiser_choice
	if not blind_choice or not can_upgrade(blind_choice) then return end

	local reward_tag = e.config.ref_table
	local blind_option = G.blind_select_opts and G.blind_select_opts[blind_choice:lower()]
	local parent = blind_option and blind_option.parent
	if not (reward_tag and reward_tag.key) then return end
	if not (blind_option and parent) then return end

	local boss = BR.choose_boss(blind_choice)
	if not (boss and G.P_BLINDS and G.P_BLINDS[boss]) then return end

	local upgrade_ante = current_slot_ante()
	local current_upgrade_key = record_key(upgrade_ante, blind_choice)
	local actual_upgrade_count = BR.upgrade_count() + 1
	local upgrade_index = BR.next_exponent_step()
	local base_score = BR.regular_score_for_slot(blind_choice, upgrade_ante)
	replacement_records()[current_upgrade_key] = {
		ante = upgrade_ante,
		blind_choice = blind_choice,
		original = G.GAME.round_resets.blind_choices[blind_choice],
		boss = boss,
		upgrade_index = upgrade_index,
		base_score = base_score,
		score_multiplier = 2 ^ upgrade_index,
		score_chips = base_score and (base_score * (2 ^ upgrade_index)) or nil,
	}

	stop_use()

	upgraded_blinds()[current_upgrade_key] = true
	G.GAME.mp_blind_raiser_upgrade_count = actual_upgrade_count
	BR.set_next_exponent_step(upgrade_index + 1)
	local uses = raiser_bosses_used()
	uses[boss] = (uses[boss] or 0) + 1

	-- Disable both actions before any animation/event begins. A Lovely guard
	-- also rejects stale controller input inside vanilla's Skip callback.
	set_runtime_button(e, false, "mp_blind_raiser_upgrade")
	local skip_button = get_runtime_element(
		e,
		blind_choice,
		"mp_blind_raiser_skip_button_" .. blind_choice
	)
	set_runtime_button(skip_button, false, "skip_blind")

	local preexisting_tags = {}
	for _, tag in ipairs(G.GAME.tags or {}) do
		preexisting_tags[tag] = true
	end

	add_tag(reward_tag)

	local granted_tags = {}
	for _, tag in ipairs(G.GAME.tags or {}) do
		if not preexisting_tags[tag] then granted_tags[#granted_tags + 1] = tag end
	end

	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		func = function()
			play_sound("other1")

			if blind_option and blind_option.set_role and blind_option.alignment then
				blind_option:set_role({ xy_bond = "Weak" })
				blind_option.alignment.offset.y = 20
			end

			return true
		end,
	}))

	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.3,
		func = function()
			local current_option = G.blind_select_opts
				and G.blind_select_opts[blind_choice:lower()]
			local current_parent = current_option and current_option.parent

			if not (current_option and current_parent) then
				save_run()
				return true
			end

			G.GAME.round_resets.blind_choices[blind_choice] = boss

			current_option:remove()
			G.blind_select_opts[blind_choice:lower()] = UIBox({
				T = { current_parent.T.x, 0, 0, 0 },
				definition = {
					n = G.UIT.ROOT,
					config = { align = "cm", colour = G.C.CLEAR },
					nodes = {
						UIBox_dyn_container(
							{ create_UIBox_blind_choice(blind_choice) },
							false,
							get_blind_main_colour(boss),
							mix_colours(G.C.BLACK, get_blind_main_colour(boss), 0.8)
						),
					},
				},
				config = {
					align = "bmi",
					offset = { x = 0, y = G.ROOM.T.y + 9 },
					major = current_parent,
					xy_bond = "Weak",
				},
			})

			local new_option = G.blind_select_opts[blind_choice:lower()]
			current_parent.config.object = new_option
			current_parent.config.object:recalculate()
			new_option.parent = current_parent
			new_option.alignment.offset.y = 0

			BR.sync_tag_ui({
				config = { id = blind_choice },
				UIBox = new_option,
			})
			if BR.rebuild_boss_option then BR.rebuild_boss_option() end

			if SMODS and SMODS.calculate_context then
				SMODS.calculate_context({
					mp_blind_raiser_upgrade = true,
					blind_type = blind_choice,
					blind_key = boss,
				})
			end

			for _, tag in ipairs(granted_tags) do
				tag:apply_to_run({ type = "immediate" })
			end
			for _, tag in ipairs(granted_tags) do
				if tag:apply_to_run({ type = "new_blind_choice" }) then break end
			end

			save_run()
			return true
		end,
	}))
end

-------------------------------------------------------------------
-- Real Boss effect stacking and Boss badge tooltips
-------------------------------------------------------------------

local function tooltip_vars(blind_key, blind_config)
	if blind_key == "bl_wheel" and SMODS and SMODS.get_probability_vars then
		local numerator, denominator = SMODS.get_probability_vars(
			blind_config or G.P_BLINDS[blind_key], 1, 7, "mp_blind_raiser_wheel_tooltip"
		)
		return { numerator, denominator }
	end
	if blind_key == "bl_ox" then
		local hand = G.GAME.current_round and G.GAME.current_round.most_played_poker_hand
		return { hand and localize(hand, "poker_hands") or "?" }
	end
	if blind_config and type(blind_config.loc_vars) == "function" then
		local ok, result = pcall(blind_config.loc_vars, blind_config)
		if ok and type(result) == "table" and type(result.vars) == "table" then
			return result.vars
		end
	end
	return {}
end

local function rows_node(rows, formatter)
	if type(formatter) == "function" then return formatter(rows) end
	return { n = G.UIT.C, config = { align = "cm" }, nodes = rows or {} }
end

local function create_effect_box(blind_key)
	local blind_config = blind_key and G.P_BLINDS and G.P_BLINDS[blind_key]
	if not blind_config then return nil end

	local name_nodes = localize({ type = "name", key = blind_key, set = "Blind" })
	local desc_nodes = {}
	localize({
		type = "descriptions",
		key = blind_key,
		set = "Blind",
		nodes = desc_nodes,
		vars = tooltip_vars(blind_key, blind_config),
	})

	local colour = blind_config.boss_colour or G.C.RED
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.025 },
		nodes = {
			{
				n = G.UIT.R,
				config = {
					align = "cm", minw = 3.45, maxw = 3.45,
					padding = 0.055, r = 0.1,
					colour = lighten(G.C.JOKER_GREY, 0.5), emboss = 0.05,
				},
				nodes = {
					{
						n = G.UIT.C,
						config = {
							align = "cm", minw = 3.3, maxw = 3.3,
							padding = 0.07, r = 0.08,
							colour = adjust_alpha(darken(colour, 0.2), 0.96),
						},
						nodes = {
							rows_node(name_nodes, name_from_rows),
							rows_node(desc_nodes, desc_from_rows),
						},
					},
				},
			},
		},
	}
end

function BR.create_boss_tooltip(ante)
	if not (blind_raiser_active() and G and G.GAME) then return nil end
	ante = tonumber(ante) or current_slot_ante()
	local nodes = {}
	local base_box = create_effect_box(boss_choice())
	if base_box then nodes[#nodes + 1] = base_box end
	for _, key in ipairs(BR.boss_effects_for_ante(ante)) do
		local box = create_effect_box(key)
		if box then nodes[#nodes + 1] = box end
	end
	if #nodes < 2 then return nil end
	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR, padding = 0.04 },
		nodes = nodes,
	}
end

function BR.attach_boss_tooltip(target, blind_config)
	if not (target and blind_config and blind_raiser_active()) then return end
	if blind_config.key ~= boss_choice() then return end
	if BR.boss_upgrade_count_for_ante(current_slot_ante()) < 1 then return end

	target.states.hover.can = true
	target.states.drag.can = false
	target.states.collide.can = true
	target.config = target.config or {}
	target.config.force_focus = true
	target.config.mp_blind_raiser_tooltip_ante = current_slot_ante()

	target.hover = function(self)
		if (not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch)
			and not self.hovering and self.states.visible
		then
			local popup = BR.create_boss_tooltip(
				self.config.mp_blind_raiser_tooltip_ante or current_slot_ante()
			)
			if not popup then return end
			self.hovering = true
			self.hover_tilt = 3
			self:juice_up(0.05, 0.02)
			play_sound("chips1", math.random() * 0.1 + 0.55, 0.12)
			self.config.h_popup = popup
			self.config.h_popup_config = {
				align = "cr", offset = { x = 0.1, y = 0 }, parent = self,
			}
			Node.hover(self)
		end
	end

	target.stop_hover = function(self)
		self.hovering = false
		self.hover_tilt = 0
		Node.stop_hover(self)
	end
end

function BR.rebuild_boss_option()
	if not (G and G.blind_select and G.blind_select_opts and G.blind_select_opts.boss) then return end
	local current_option = G.blind_select_opts.boss
	local parent = current_option.parent
	local boss = boss_choice()
	if not (parent and boss) then return end

	current_option:remove()
	G.blind_select_opts.boss = UIBox({
		T = { parent.T.x, 0, 0, 0 },
		definition = {
			n = G.UIT.ROOT,
			config = { align = "cm", colour = G.C.CLEAR },
			nodes = {
				UIBox_dyn_container(
					{ create_UIBox_blind_choice("Boss") },
					false,
					get_blind_main_colour(boss),
					mix_colours(G.C.BLACK, get_blind_main_colour(boss), 0.8)
				),
			},
		},
		config = {
			align = "bmi", offset = { x = 0, y = G.ROOM.T.y + 9 },
			major = parent, xy_bond = "Weak",
		},
	})

	local new_option = G.blind_select_opts.boss
	parent.config.object = new_option
	parent.config.object:recalculate()
	new_option.parent = parent
	new_option.alignment.offset.y = 0
end

local function active_effect_hooks()
	local hooks = {}
	local ante = G and G.GAME and G.GAME.mp_blind_raiser_boss_stack_ante or current_slot_ante()
	for _, blind_key in ipairs(BR.boss_effects_for_ante(ante)) do
		local hook_key = STACKABLE_BOSS_EFFECTS[blind_key]
		if hook_key then hooks[#hooks + 1] = hook_key end
	end
	return hooks
end

local function live_physical_slot(blind)
	return blind and blind.mp_blind_raiser_replacement_slot
		or (G and G.GAME and G.GAME.blind_on_deck)
end

function BR.start_boss_stack(blind)
	if not (blind_raiser_active() and G and G.GAME and blind) then return end
	if live_physical_slot(blind) ~= "Boss"
		or BR.boss_upgrade_count_for_ante(current_slot_ante()) < 1
	then
		G.GAME.mp_blind_raiser_boss_stack_active = nil
		return
	end

	G.GAME.mp_blind_raiser_boss_stack_active = true
	G.GAME.mp_blind_raiser_boss_stack_ante = current_slot_ante()

	local base_key = blind.config and blind.config.blind and blind.config.blind.key
	local needs_draw_context = false
	for _, hook_key in ipairs(active_effect_hooks()) do
		if hook_key == "bl_hook_the_fish" or hook_key == "bl_hook_the_serpent" then
			needs_draw_context = true
			break
		end
	end
	if needs_draw_context and base_key and SMODS and SMODS.Blinds and SMODS.Blinds.modifies_draw then
		G.GAME.mp_blind_raiser_draw_key = base_key
		G.GAME.mp_blind_raiser_draw_original = SMODS.Blinds.modifies_draw[base_key]
		SMODS.Blinds.modifies_draw[base_key] = true
	end

	for _, hook_key in ipairs(active_effect_hooks()) do
		local component = MP.BLIND_RAISER_COMPONENTS and MP.BLIND_RAISER_COMPONENTS[hook_key]
		if component then
			if component.set_blind then component:set_blind() end
			if component.debuff then
				blind.debuff = blind.debuff or {}
				-- Suit debuffs are evaluated through component contexts so multiple
				-- stacked suit Bosses cannot overwrite the natural Boss's own suit.
				if component.debuff.h_size_ge then blind.debuff.h_size_ge = component.debuff.h_size_ge end
			end
			if component.calculate then component:calculate(blind, { setting_blind = true }) end
		end
	end

	-- Blind:set_blind debuffed the deck before the stack was active. Re-evaluate
	-- once so stacked card-debuff effects apply immediately at fight start.
	for _, card in ipairs(G.playing_cards or {}) do
		blind:debuff_card(card)
	end

	blind.loc_name = append_plus_to_name(blind.loc_name)

	local function attach_live_tooltip()
		if not (G and G.GAME and G.GAME.blind == blind) then return end
		local config = blind.config and blind.config.blind
		BR.attach_boss_tooltip(blind, config)
		if blind.children and blind.children.animatedSprite then
			BR.attach_boss_tooltip(blind.children.animatedSprite, config)
		end
	end
	attach_live_tooltip()
	if G.E_MANAGER and Event then
		G.E_MANAGER:add_event(Event({
			trigger = "after", delay = 0.2,
			blockable = false, blocking = false,
			func = function()
				attach_live_tooltip()
				return true
			end,
		}))
	end
end

function BR.calculate_boss_stack(context)
	if not (G and G.GAME and G.GAME.mp_blind_raiser_boss_stack_active and context) then return nil end
	-- Blind:debuff_card below is authoritative; mod-level debuff results are not
	-- consumed consistently by every Multiplayer/Steamodded calculation layer.
	if context.debuff_card then return nil end
	local blind = G.GAME.blind
	if not blind then return nil end

	-- Luchador and Chicot disable the live Blind. Delegated Boss effects must
	-- stop immediately as well; only lifecycle cleanup contexts may pass.
	local cleanup_context = context.blind_disabled or context.blind_defeated
	if blind.disabled and not cleanup_context then return nil end

	local result = nil
	for _, hook_key in ipairs(active_effect_hooks()) do
		local component = MP.BLIND_RAISER_COMPONENTS and MP.BLIND_RAISER_COMPONENTS[hook_key]
		if component and component.calculate then
			local component_result = component:calculate(blind, context)
			if type(component_result) == "table" then
				result = result or {}
				for key, value in pairs(component_result) do result[key] = value end
			elseif component_result ~= nil and result == nil then
				result = component_result
			end
		end
	end
	return result
end

local function component_debuffs_card(component, blind, card)
	if not (component and blind and card) then return false end
	if G and G.jokers and card.area == G.jokers then return false end

	local debuff = component.debuff
	if debuff then
		if debuff.suit and card.is_suit and card:is_suit(debuff.suit, true) then return true end
		if debuff.is_face and card.is_face and card:is_face(true) then return true end
		if debuff.value and card.base and card.base.value == debuff.value then return true end
		if debuff.nominal and card.base and card.base.nominal == debuff.nominal then return true end
	end

	if component.calculate then
		local result = component:calculate(blind, {
			debuff_card = card,
			debuff_source = blind,
		})
		return result == true or (type(result) == "table" and result.debuff == true)
	end
	return false
end

local function active_stacked_components_debuff_card(blind, card)
	if not (G and G.GAME and G.GAME.mp_blind_raiser_boss_stack_active) then return false end
	if not (blind and card) or blind.disabled then return false end

	for _, hook_key in ipairs(active_effect_hooks()) do
		local component = MP.BLIND_RAISER_COMPONENTS and MP.BLIND_RAISER_COMPONENTS[hook_key]
		if component_debuffs_card(component, blind, card) then return true end
	end
	return false
end

local Blind_debuff_card_ref = Blind.debuff_card
function Blind:debuff_card(card, from_blind)
	-- Resolve the natural Boss first, then OR every stacked component on top.
	-- This preserves the natural suit/type and prevents one component from
	-- overwriting another or being lost through Multiplayer's context merger.
	local result = Blind_debuff_card_ref(self, card, from_blind)
	if active_stacked_components_debuff_card(self, card) then
		card:set_debuff(true)
	end
	return result
end

function BR.stop_boss_stack(cleanup_context)
	if not (G and G.GAME and G.GAME.mp_blind_raiser_boss_stack_active) then return end

	local blind = G.GAME.blind
	local hooks = active_effect_hooks()
	local context = type(cleanup_context) == "table"
		and cleanup_context
		or { blind_disabled = true }

	-- Stop delegation before component cleanup. Some Steamodded builds emit a
	-- second blind_disabled context from Blind:disable(); this prevents duplicate
	-- restores, while the component itself also guards The Manacle idempotently.
	G.GAME.mp_blind_raiser_boss_stack_active = nil

	for _, hook_key in ipairs(hooks) do
		local component = MP.BLIND_RAISER_COMPONENTS and MP.BLIND_RAISER_COMPONENTS[hook_key]
		if component then
			if component.calculate then component:calculate(blind, context) end
			if component.disable then component:disable() end
		end
	end

	local draw_key = G.GAME.mp_blind_raiser_draw_key
	if draw_key and SMODS and SMODS.Blinds and SMODS.Blinds.modifies_draw then
		SMODS.Blinds.modifies_draw[draw_key] = G.GAME.mp_blind_raiser_draw_original
	end
	G.GAME.mp_blind_raiser_draw_key = nil
	G.GAME.mp_blind_raiser_draw_original = nil
	G.GAME.mp_blind_raiser_boss_stack_ante = nil
end

local Blind_set_text_ref = Blind.set_text
function Blind:set_text(...)
	local ret = Blind_set_text_ref(self, ...)
	if blind_raiser_active()
		and live_physical_slot(self) == "Boss"
		and BR.boss_upgrade_count_for_ante(current_slot_ante()) > 0
	then
		self.loc_name = append_plus_to_name(self.loc_name)
	end
	return ret
end

local Blind_set_blind_ref = Blind.set_blind
function Blind:set_blind(blind, reset, silent)
	local ret = Blind_set_blind_ref(self, blind, reset, silent)
	self.mp_blind_raiser_replacement_slot = nil
	self.mp_blind_raiser_replacement_ante = nil

	if blind_raiser_active() and G and G.GAME then
		local key = blind_key_from_definition(blind or (self.config and self.config.blind))
		for _, slot in ipairs({ "Small", "Big" }) do
			local record = replacement_record(slot, current_slot_ante(), key)
			if type(record) == "table" and record.boss == key then
				self.mp_blind_raiser_replacement_slot = slot
				self.mp_blind_raiser_replacement_ante = tonumber(record.ante) or current_slot_ante()
				break
			end
		end
		if not self.mp_blind_raiser_replacement_slot and G.GAME.blind_on_deck == "Boss" then
			BR.start_boss_stack(self)
		end
	end
	return ret
end

local Blind_disable_ref = Blind.disable
function Blind:disable(...)
	-- Luchador/Chicot disable every component of Boss+, then the wrapped
	-- Multiplayer/vanilla method handles the natural Boss effect.
	if G and G.GAME and G.GAME.mp_blind_raiser_boss_stack_active then
		BR.stop_boss_stack({ blind_disabled = true })
	end
	return Blind_disable_ref(self, ...)
end

local Blind_defeat_ref = Blind.defeat
function Blind:defeat(...)
	if G and G.GAME and G.GAME.mp_blind_raiser_boss_stack_active then
		BR.stop_boss_stack({ blind_defeated = true })
	end
	return Blind_defeat_ref(self, ...)
end

local MP_calculate_ref = MP.calculate
MP.calculate = function(self, context)
	local original = MP_calculate_ref and MP_calculate_ref(self, context) or nil
	local stacked = BR.calculate_boss_stack(context)
	if type(original) == "table" and type(stacked) == "table" then
		for key, value in pairs(stacked) do original[key] = value end
		return original
	end
	return stacked or original
end

-------------------------------------------------------------------
-- Rare Tag purchase penalty
-------------------------------------------------------------------

if G.FUNCS and type(G.FUNCS.buy_from_shop) == "function" then
	local buy_from_shop_ref = G.FUNCS.buy_from_shop
	function G.FUNCS.buy_from_shop(e)
		local card = e and e.config and e.config.ref_table
		local zero_money = blind_raiser_active()
			and card
			and card.ability
			and card.ability.mp_blind_raiser_zero_money_on_buy

		local ret = buy_from_shop_ref(e)

		if zero_money then
			if card.ability then card.ability.mp_blind_raiser_zero_money_on_buy = nil end
			local dollars = G and G.GAME and tonumber(G.GAME.dollars) or 0
			if dollars ~= 0 then ease_dollars(-dollars, true) end
		end

		return ret
	end
end

