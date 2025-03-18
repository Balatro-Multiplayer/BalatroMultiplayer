G.P_CENTER_POOLS.Ruleset = {}
MP.Rulesets = {}
MP.Ruleset = SMODS.GameObject:extend({
	obj_table = {},
	obj_buffer = {},
	required_params = {
		"key",
		"challenge_deck",
	},
	class_prefix = "ruleset",
	inject = function(self)
        MP.Rulesets[self.key] = self
		if not G.P_CENTER_POOLS.Ruleset then G.P_CENTER_POOLS.Ruleset = {} end
		table.insert(G.P_CENTER_POOLS.Ruleset, self)
	end,
	process_loc_text = function(self)
		SMODS.process_loc_text(G.localization.descriptions["Ruleset"], self.key, self.loc_txt)
	end,
})