SMODS.Challenge({
	key = "polymorph_spam",
	rules = {
		custom = {
			{ id = "mp_polymorph_spam" },
			{ id = "mp_polymorph_spam_EXTENDED" },
		},
	},
	restrictions = {
		banned_cards = function()
			local ret = {}
			local add = {
				j_campfire = true,
				j_invisible = true,
				j_caino = true,
				j_yorick = true,
			}
			for i, v in ipairs(G.P_CENTER_POOLS.Joker) do
				if (not v.perishable_compat) or add[v.key] then
					ret[#ret+1] = { id = v.key }
				end
			end
			return ret
		end,
	},
	unlocked = function(self)
		return true
	end,
})

local function included(key)
	if G.GAME.banned_keys[key] then
		return false
	elseif G.P_CENTERS[key].mp_include and type(G.P_CENTERS[key].mp_include) == "function" then
		return G.P_CENTERS[key].mp_include()
	end
	return true
end

local function mass_polymorph(area)
	for _, card in ipairs(area) do
		local done = false
		local swap = false
		while not done do
			for i, v in ipairs(G.P_CENTER_POOLS[card.config.center.set]) do
				if swap and included(v.key) then
					card:set_ability(v)
					done = true
					break
				elseif v == card.config.center then
					swap = true
				end
			end
		end
	end
end

local calculate_context_ref = SMODS.calculate_context
function SMODS.calculate_context(context, return_table, no_resolve)
	if G.GAME.modifiers.mp_polymorph_spam and context and type(context) == "table" and context.setting_blind then
		mass_polymorph(G.jokers.cards)
		mass_polymorph(G.consumeables.cards)
	end
	return calculate_context_ref(context, return_table, no_resolve)
end

local set_ability_ref = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
	local ret = set_ability_ref(self, center, initial, delay_sprites)
	if G.GAME.modifiers.mp_polymorph_spam and G.OVERLAY_MENU then
		if not included(center.key) then
			self.ability.perma_debuff = true
		end
	end
end