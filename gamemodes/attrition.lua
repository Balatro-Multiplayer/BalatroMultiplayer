MP.Gamemode({
    key = "attrition",
    get_blinds_by_ante = function(self, ante)
        if ante >= MP.LOBBY.config.pvp_start_round then
            if not MP.LOBBY.config.normal_bosses then
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
		"tag_boss"
	},
	banned_blinds = {
		"bl_wall",
		"bl_final_vessel"
	},
	reworked_jokers = {},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {},
	reworked_tags = {},
	reworked_blinds = {}
}):inject()
