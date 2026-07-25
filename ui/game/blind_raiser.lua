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
		return G and G.GAME and G.GAME.blind_on_deck == slot
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

function BR.score_for_slot(blind_choice, vanilla_amount, ante, expected_boss)
	if not blind_raiser_active() then return vanilla_amount end
	blind_choice = normalize_blind_choice(blind_choice)
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
-- Deterministic non-Showdown Boss selection
-------------------------------------------------------------------

local function blind_is_in_pool(blind)
	if type(blind.in_pool) ~= "function" then return true end
	local ok, result = pcall(blind.in_pool, blind)
	return ok and result ~= false
end

local function boss_is_valid(key)
	local blind = key and G.P_BLINDS and G.P_BLINDS[key]
	if key == "bl_mp_nemesis" then return false end
	if not (blind and blind.boss) then return false end
	if blind.boss.showdown then return false end
	if G.GAME.banned_keys and G.GAME.banned_keys[key] then return false end
	return true
end

local function choose_with_vanilla_boss_picker()
	if type(get_new_boss) ~= "function" then return nil end

	-- Let vanilla/SMODS decide ante eligibility and compatibility-pool rules,
	-- but evaluate the roll against a temporary usage table. This retains the
	-- exact normal Boss-selection semantics without allowing an optional Blind
	-- Raiser choice to alter future shared-seed Boss rolls.
	local original_uses = G.GAME.bosses_used
	local working_uses = {}
	for key, uses in pairs(original_uses or {}) do
		working_uses[key] = uses
	end
	for key, uses in pairs(raiser_bosses_used()) do
		working_uses[key] = (working_uses[key] or 0) + uses
	end
	G.GAME.bosses_used = working_uses

	-- get_new_boss advances the keyed pseudorandom stream it uses. Isolate that
	-- state too, otherwise one player pressing Upgrade Blind would change later
	-- normal Boss rolls while an opponent who did not upgrade keeps the original
	-- stream. The temporary table may be freely mutated by vanilla or SMODS.
	local original_pseudorandom = G.GAME.pseudorandom
	local working_pseudorandom = {}
	for key, value in pairs(original_pseudorandom or {}) do
		if type(value) == "table" then
			local nested = {}
			for nested_key, nested_value in pairs(value) do
				nested[nested_key] = nested_value
			end
			working_pseudorandom[key] = nested
		else
			working_pseudorandom[key] = value
		end
	end
	G.GAME.pseudorandom = working_pseudorandom

	-- On a Showdown Ante, vanilla would intentionally return a final Boss.
	-- Temporarily move win_ante beyond the current Ante so an upgraded Small
	-- or Big slot always receives an ordinary, non-Showdown Boss.
	local original_win_ante = G.GAME.win_ante
	if type(original_win_ante) == "number" then
		G.GAME.win_ante = math.max(original_win_ante + 1, current_ante() + 1)
	end

	local ok, boss = pcall(get_new_boss)
	G.GAME.win_ante = original_win_ante
	G.GAME.bosses_used = original_uses
	G.GAME.pseudorandom = original_pseudorandom

	if not ok then
		if sendWarnMessage then
			sendWarnMessage("Blind Raiser Boss selection failed: " .. tostring(boss), "MULTIPLAYER")
		end
		return nil
	end
	return boss_is_valid(boss) and boss or nil
end

local function choose_fallback_boss(blind_choice)
	local candidates = {}
	for key, blind in pairs(G.P_BLINDS or {}) do
		if boss_is_valid(key) and blind_is_in_pool(blind) then
			candidates[#candidates + 1] = key
		end
	end
	table.sort(candidates)
	if #candidates == 0 then return nil end

	local base_uses = G.GAME.bosses_used or {}
	local extra_uses = raiser_bosses_used()
	local minimum_uses = nil
	for _, key in ipairs(candidates) do
		local uses = (base_uses[key] or 0) + (extra_uses[key] or 0)
		if minimum_uses == nil or uses < minimum_uses then minimum_uses = uses end
	end

	local filtered = {}
	for _, key in ipairs(candidates) do
		local uses = (base_uses[key] or 0) + (extra_uses[key] or 0)
		if uses == minimum_uses then filtered[#filtered + 1] = key end
	end

	return pseudorandom_element(
		filtered,
		pseudoseed("mp_blind_raiser_" .. tostring(current_ante()) .. "_" .. tostring(blind_choice))
	)
end

function BR.choose_boss(blind_choice)
	if not (G and G.GAME and G.P_BLINDS) then return nil end
	return choose_with_vanilla_boss_picker() or choose_fallback_boss(blind_choice)
end

-------------------------------------------------------------------
-- Ante transition cleanup
-------------------------------------------------------------------

function BR.restore_stale_slots()
	if not blind_raiser_active() then return end
	if not (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_choices) then return end

	local ante = current_ante()
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
	if G.FUNCS.hover_tag_proxy then G.FUNCS.hover_tag_proxy(e) end
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
			align = "tm",
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
				n = G.UIT.C,
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
							hover = upgrade_active,
							one_press = true,
							button = upgrade_active and "mp_blind_raiser_upgrade" or nil,
							func = "mp_blind_raiser_update_upgrade_button",
							insta_func = true,
							ref_table = reward_tag,
							mp_blind_raiser_choice = blind_choice,
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
	local upgrade_index = (tonumber(G.GAME.mp_blind_raiser_upgrade_count) or 0) + 1
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
	G.GAME.mp_blind_raiser_upgrade_count = upgrade_index
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

