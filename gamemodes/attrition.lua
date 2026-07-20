MP.Gamemode({
	key = "attrition",
	get_blinds_by_ante = function(self, ante)
		if ante >= MP.LOBBY.config.pvp_start_round then
			-- MP.current_target_id() is always non-nil for 1v1 (sole opponent). For
			-- Nemesis (rotating pairing), nil means byed this ante -- fall through to a
			-- normal boss instead of the nemesis one, the entire bye mechanism. Royale
			-- has no bye/sit-out concept (referee.lua's rank-and-cut ranks every alive
			-- player every PvP round), and MP.GAME.royale_target_id only ever latches as
			-- a side effect of a multiplayer joker/consumable interaction (Asteroid/
			-- Taxes/Penny Pincher) -- which can't happen before the first PvP blind ever
			-- runs. Treating an unresolved Royale target as a bye would mean a match with
			-- no multiplayer jokers owned/used never reaches a PvP blind at all, so only
			-- Nemesis-pairing's real bye gates on it.
			local byed = MP.LOBBY.config.nemesis_pairing and MP.current_target_id() == nil
			if not MP.LOBBY.config.normal_bosses and not byed then
				return nil, nil, "bl_mp_nemesis"
			else
				G.GAME.round_resets.pvp_blind_choices.Boss = true
			end
		end
		return nil, nil, nil
	end,
	banned_jokers = {
		"j_mr_bones",
		"j_luchador",
		"j_matador",
		"j_chicot",
	},
	banned_consumables = {},
	banned_vouchers = {
		"v_hieroglyph",
		"v_petroglyph",
		"v_directors_cut",
		"v_retcon",
	},
	banned_enhancements = {},
	banned_tags = {
		"tag_boss",
	},
	banned_blinds = {
		"bl_wall",
		"bl_final_vessel",
	},
	reworked_jokers = {},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {},
	reworked_tags = {},
	reworked_blinds = {},
}):inject()
