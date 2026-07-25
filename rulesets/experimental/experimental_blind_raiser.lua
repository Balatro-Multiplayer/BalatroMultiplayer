local BLIND_RAISER_LAYER = "experimental_blind_raiser"
local BLIND_RAISER_RULESET = "ruleset_mp_experimental_blind_raiser"

local function blind_raiser_ruleset_active()
	if not MP then return false end
	if MP.get_active_ruleset then
		return MP.get_active_ruleset() == BLIND_RAISER_RULESET
	end
	return MP.LOBBY
		and MP.LOBBY.config
		and MP.LOBBY.config.ruleset == BLIND_RAISER_RULESET
end

local function blind_raiser_upgrade_count()
	return G and G.GAME and math.max(0, tonumber(G.GAME.mp_blind_raiser_upgrade_count) or 0) or 0
end

local function investment_payout(tag_or_center)
	local config = tag_or_center and tag_or_center.config or {}
	local per_upgrade = tonumber(config.dollars_per_upgrade) or 5
	return per_upgrade * blind_raiser_upgrade_count(), per_upgrade
end

local function is_common_joker(card)
	local center = card and card.config and card.config.center
	local rarity = center and center.rarity
	return rarity == 1 or rarity == "Common" or rarity == "common"
end

local function is_base_edition_shop_common_joker(card)
	return card
		and card.ability
		and card.ability.set == "Joker"
		and is_common_joker(card)
		and not card.edition
		and not card.temp_edition
end

local function apply_investment_tag(tag, context)
	if not (context and context.type == "immediate") then return nil end

	local dollars = investment_payout(tag)
	tag:yep("+", G.C.GOLD, function()
		if dollars ~= 0 then ease_dollars(dollars) end
		return true
	end)
	tag.triggered = true
	return true
end

local function apply_negative_tag(tag, context)
	if not (context and context.type == "store_joker_modify") then return nil end
	if not is_base_edition_shop_common_joker(context.card) then
		-- Deliberately do not call vanilla here. The Tag must remain available
		-- until a base-edition Common shop Joker is encountered.
		return nil
	end

	local card = context.card
	local lock = "mp_blind_raiser_negative_" .. tostring(tag.ID)
	G.CONTROLLER.locks[lock] = true
	card.temp_edition = true
	tag:yep("+", G.C.DARK_EDITION, function()
		card.temp_edition = nil
		card:set_edition({ negative = true }, true)
		G.CONTROLLER.locks[lock] = nil
		return true
	end)
	tag.triggered = true
	return true
end

local function create_rare_shop_joker(tag, context)
	if not (context and context.type == "store_joker_create" and context.area) then return nil end

	local rares_owned = { 0 }
	for _, joker in ipairs((G.jokers and G.jokers.cards) or {}) do
		local center = joker.config and joker.config.center
		if center and center.rarity == 3 and not rares_owned[center.key] then
			rares_owned[1] = rares_owned[1] + 1
			rares_owned[center.key] = true
		end
	end

	local rare_pool = G.P_JOKER_RARITY_POOLS and G.P_JOKER_RARITY_POOLS[3]
	if not rare_pool or #rare_pool <= rares_owned[1] then
		tag:nope()
		tag.triggered = true
		return nil
	end

	local card = create_card("Joker", context.area, nil, 1, nil, nil, nil, "rta")
	create_shop_card_ui(card, "Joker", context.area)
	card.states.visible = false
	tag:yep("+", G.C.RED, function()
		card.ability.couponed = true
		card.ability.mp_blind_raiser_zero_money_on_buy = true
		card:set_cost()
		card:start_materialize()
		return true
	end)
	tag.triggered = true
	return card
end

MP.Ruleset({
	key = BLIND_RAISER_LAYER,
	layers = { "standard", "ranked", "pvp_timer" },
	forced_gamemode = "gamemode_mp_attrition",
	reworked_tags = {
		"tag_investment",
		"tag_negative",
		"tag_rare",
	},
}):inject()

MP.ReworkCenter("tag_investment", {
	layers = BLIND_RAISER_LAYER,
	center_table = "P_TAGS",
	loc_key = "tag_mp_investment_blind_raiser",
	config = {
		type = "immediate",
		dollars_per_upgrade = 5,
	},
	loc_vars = function(self, info_queue, tag)
		local payout, per_upgrade = investment_payout(tag or self)
		return { vars = { per_upgrade, payout } }
	end,
	apply = function(self, tag, context)
		return apply_investment_tag(tag, context)
	end,
})

MP.ReworkCenter("tag_negative", {
	layers = BLIND_RAISER_LAYER,
	center_table = "P_TAGS",
	loc_key = "tag_mp_negative_blind_raiser",
	apply = function(self, tag, context)
		return apply_negative_tag(tag, context)
	end,
})

MP.ReworkCenter("tag_rare", {
	layers = BLIND_RAISER_LAYER,
	center_table = "P_TAGS",
	loc_key = "tag_mp_rare_blind_raiser",
	min_ante = 2,
	apply = function(self, tag, context)
		return create_rare_shop_joker(tag, context)
	end,
})

-- Steamodded dispatches Tag logic through SMODS.Tags[self.key]. Vanilla Tags
-- are not guaranteed to be registered there. Point the dispatch table at the
-- live vanilla prototypes so ReworkCenter's active ruleset properties are used.
for _, key in ipairs({ "tag_investment", "tag_negative", "tag_rare" }) do
	if G.P_TAGS and G.P_TAGS[key] then SMODS.Tags[key] = G.P_TAGS[key] end
end

-- A direct wrapper is retained as the authoritative ruleset gate. It also
-- prevents vanilla Negative Tag logic from consuming itself on a non-Common
-- Joker when our Common-only condition is not satisfied.
if Tag and type(Tag.apply_to_run) == "function" and not MP._blind_raiser_tag_wrapper_installed then
	MP._blind_raiser_tag_wrapper_installed = true
	local tag_apply_to_run_ref = Tag.apply_to_run

	function Tag:apply_to_run(context)
		if blind_raiser_ruleset_active() and not self.triggered and context then
			if self.key == "tag_investment" and context.type == "immediate" then
				return apply_investment_tag(self, context)
			elseif self.key == "tag_negative" and context.type == "store_joker_modify" then
				return apply_negative_tag(self, context)
			elseif self.key == "tag_rare" and context.type == "store_joker_create" then
				return create_rare_shop_joker(self, context)
			end
		end
		return tag_apply_to_run_ref(self, context)
	end
end
