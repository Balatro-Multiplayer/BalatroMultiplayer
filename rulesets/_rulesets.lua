G.P_CENTER_POOLS.Ruleset = {}
MP.Rulesets = {}
MP.Ruleset = SMODS.GameObject:extend({
	obj_table = {},
	obj_buffer = {},
	required_params = {
		"key",
		"multiplayer_content",
		"banned_jokers",
		"banned_consumables",
		"banned_vouchers",
		"banned_enhancements",
	},
	class_prefix = "ruleset",
	inject = function(self)
		MP.Rulesets[self.key] = self
		if not G.P_CENTER_POOLS.Ruleset then
			G.P_CENTER_POOLS.Ruleset = {}
		end
		table.insert(G.P_CENTER_POOLS.Ruleset, self)
	end,
	process_loc_text = function(self)
		SMODS.process_loc_text(G.localization.descriptions["Ruleset"], self.key, self.loc_txt)
	end,
})

MP.BANNED_OBJECTS = {
	jokers = {},
	consumables = {},
	vouchers = {},
	enhancements = {},
	tags = {},
	blinds = {},
}

function MP.apply_rulesets()
	for _, ruleset in pairs(MP.Rulesets) do
		local function process_banned_items(banned_items, banned_table)
			if not banned_items then
				return
			end
			for _, item_key in ipairs(banned_items) do
				banned_table[item_key] = banned_table[item_key] or {}
				banned_table[item_key][ruleset.key] = true
			end
		end

		local banned_types = {
			{ items = ruleset.banned_jokers, table = MP.BANNED_OBJECTS.jokers },
			{ items = ruleset.banned_consumables, table = MP.BANNED_OBJECTS.consumables },
			{ items = ruleset.banned_vouchers, table = MP.BANNED_OBJECTS.vouchers },
			{ items = ruleset.banned_enhancements, table = MP.BANNED_OBJECTS.enhancements },
			{ items = ruleset.banned_tags, table = MP.BANNED_OBJECTS.tags },
			{ items = ruleset.banned_blinds, table = MP.BANNED_OBJECTS.blinds },
		}

		for _, banned_type in ipairs(banned_types) do
			process_banned_items(banned_type.items, banned_type.table)
		end
	end

	local object_types = {
		{ objects = MP.BANNED_OBJECTS.jokers, mod = SMODS.Joker, global_banned = MP.DECK.BANNED_JOKERS },
		{ objects = MP.BANNED_OBJECTS.consumables, mod = SMODS.Consumable, global_banned = MP.DECK.BANNED_CONSUMABLES },
		{ objects = MP.BANNED_OBJECTS.vouchers, mod = SMODS.Voucher, global_banned = MP.DECK.BANNED_VOUCHERS },
		{
			objects = MP.BANNED_OBJECTS.enhancements,
			mod = SMODS.Enhancement,
			global_banned = MP.DECK.BANNED_ENHANCEMENTS,
		},
		{ objects = MP.BANNED_OBJECTS.tags, mod = SMODS.Tag, global_banned = MP.DECK.BANNED_TAGS },
		{ objects = MP.BANNED_OBJECTS.blinds, mod = SMODS.Blind, global_banned = MP.DECK.BANNED_BLINDS },
	}

	for _, type in ipairs(object_types) do
		for obj_key, rulesets in pairs(type.objects) do
			type.mod:take_ownership(obj_key, {
				in_pool = function(self)
					return not (rulesets[MP.LOBBY.config.ruleset] and MP.LOBBY.code)
				end,
			}, true)
		end
		for obj_key, _ in pairs(type.global_banned) do
			type.mod:take_ownership(obj_key, {
				in_pool = function(self)
					return not MP.LOBBY.code
				end,
			}, true)
		end
	end
end
