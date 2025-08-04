G.P_CENTER_POOLS.Gamemode = {}
MP.Gamemodes = {}
MP.Gamemode = SMODS.GameObject:extend({
	obj_table = {},
	obj_buffer = {},
	required_params = {
		"key",
		"get_blinds_by_ante", -- Define custom logic for determining Small, Big, and Boss Blind based on the ante number.
		"banned_jokers",
		"banned_consumables",
		"banned_vouchers",
		"banned_enhancements",
		"banned_tags",
		"banned_blinds",
		"reworked_jokers",
		"reworked_consumables",
		"reworked_vouchers",
		"reworked_enhancements",
		"reworked_tags",
		"reworked_blinds",
		"create_info_menu"
	},
	class_prefix = "gamemode",
	inject = function(self)
		MP.Gamemodes[self.key] = self
		if not G.P_CENTER_POOLS.Gamemode then G.P_CENTER_POOLS.Gamemode = {} end
		table.insert(G.P_CENTER_POOLS.Gamemode, self)
	end,
	process_loc_text = function(self)
		SMODS.process_loc_text(G.localization.descriptions["Gamemode"], self.key, self.loc_txt)
	end,
})
