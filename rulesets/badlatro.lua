MP.Ruleset({
	key = "badlatro",
	multiplayer_content = true,
	banned_jokers = {
		"j_caino",
		"j_perkeo",
		"j_triboulet",
		"j_yorick",
		"j_blueprint",
		"j_ancient",
		"j_dna",
		"j_family",
		"j_trio",
		"j_acrobat",
		"j_card_sharp",
		"j_cartomancer",
		"j_certificate",
		"j_dusk",
		"j_fibonacci",
		"j_hologram",
		"j_loyalty_card",
		"j_midas_mask",
		"j_bloodstone",
		"j_onyx_agate",
		"j_selzer",
		"j_trading",
		"j_abstract",
		"j_cavendish",
		"j_photograph",
		"j_hanging_chad",
		"j_mail",
		"j_brainstorm",
		"j_mime",
		"j_reserved_parking",
		"j_mp_defensive_joker",
		"j_idol",
		"j_invisible",
		"j_mp_penny_pincher",
	},
	banned_consumables = {
		"c_justice",
		"c_deja_vu",
		"c_trance",
	},
	banned_vouchers = {
		"v_magic_trick",
	},
	banned_enhancements = {
		"m_glass",
	},
	banned_tags = {
		"tag_uncommon",
		"tag_meteor",
		"tag_garbage",
		"tag_top_up",
		"tag_handy",
		"tag_d_six",
	},
	banned_blinds ={},

	reworked_jokers = {},
	reworked_consumables = {
		"c_mp_asteroid"
	},
	reworked_vouchers = {},
	reworked_enhancements = {},
	reworked_tags = {},
	reworked_blinds = {
		"bl_mp_nemesis"
	},

}):inject()

-- SMODS.Tag:take_ownership("tag_negative", {
-- 	if MP.LOBBY.config.ruleset == "ruleset_mp_badlatro" then
--     	if MP.LOBBY.code or MP.LOBBY.ruleset_preview then
--         	print("[DEBUG] code or ruleset_preview exists")
--         	min_ante = 1
--     	else
--         	print("[DEBUG] code and ruleset_preview are nil/false")
--         	min_ante = 2
--     	end
-- 	if MP.LOBBY.config.ruleset ~= "ruleset_mp_badlatro" then
--     	print("[DEBUG] ruleset is not badlatro, actual value:", MP.LOBBY.config.ruleset)
--     	min_ante = 2
-- 	end
-- }, true)

SMODS.Tag:take_ownership("tag_negative", {
	
	min_ante = 1;
},true)

	

SMODS.Tag:take_ownership("tag_orbital", {
        min_ante = 1,
	},true)





SMODS.Tag:take_ownership("tag_skip", {
        min_ante = 2,
	},true)



SMODS.Tag:take_ownership("tag_rare", {
        min_ante = 2,
	},true)



SMODS.Tag:take_ownership("tag_voucher", {
        min_ante = 2,
	},true)


SMODS.Tag:take_ownership("tag_juggle", {
        min_ante = 2,
	},true)

SMODS.Joker:take_ownership('j_lucky_cat',{
    cost = 20,
	rarity = 4
    },true)

SMODS.Joker:take_ownership('j_baseball',{
    cost = 20,
	rarity = 4
    },true)

SMODS.Joker:take_ownership('j_vagabond',{
    cost = 20,
	rarity = 4
    },true)

SMODS.Joker:take_ownership('j_joker',{
    cost = 20,
	rarity = 4
    },true)

SMODS.Joker:take_ownership('j_baron',{
    cost = 20,
	rarity = 4
    },true)

-- SMODS.Tag:take_ownership("tag_orbital", {
--         if (MP.LOBBY.config.ruleset == "ruleset_mp_badlatro");
-- 			min_ante = 2
-- 		else
-- 		min_ante = 5
-- }, true)

-- SMODS.Tag:take_ownership("tag_rare", {
--         min_ante = (MP.LOBBY.config.ruleset == "ruleset_mp_badlatro") and 2 or nil
-- }, true)

-- SMODS.Tag:take_ownership("tag_skip", {
--         min_ante = MP.LOBBY.config.ruleset == "ruleset_mp_badlatro" and (MP.LOBBY.code or MP.LOBBY.ruleset_preview) and 2 or nil
-- }, true)

-- SMODS.Tag:take_ownership("tag_voucher", {
--         min_ante = MP.LOBBY.config.ruleset == "ruleset_mp_badlatro" and (MP.LOBBY.code or MP.LOBBY.ruleset_preview) and 2 or nil
-- }, true)

-- SMODS.Tag:take_ownership("tag_juggle", {
--         min_ante = MP.LOBBY.config.ruleset == "ruleset_mp_badlatro" and (MP.LOBBY.code or MP.LOBBY.ruleset_preview) and 2 or nil
-- }, true)
