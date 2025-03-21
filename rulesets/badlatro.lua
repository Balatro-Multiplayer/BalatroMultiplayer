MP.Ruleset({
	key = "badlatro",
	challenge_deck = "c_mp_badlatro"
})

MP.DECK.BADLATRO = {}
MP.DECK.BADLATRO.BANNED_CARDS = MP.UTILS.shallow_copy(MP.DECK.BANNED_CARDS)
MP.DECK.BADLATRO.BANNED_TAGS = MP.UTILS.shallow_copy(MP.DECK.BANNED_TAGS)
MP.DECK.BADLATRO.BANNED_BLINDS = MP.UTILS.shallow_copy(MP.DECK.BANNED_BLINDS)
MP.DECK.BADLATRO.TYPE = MP.DECK.TYPE .. ""

table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_caino" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_perkeo" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_triboulet" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_yorick" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_blueprint" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_ancient" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_baron" })	
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_baseball" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_dna" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_family" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_trio" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_vagabond" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_acrobat" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_card_sharp" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_cartomancer" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_certificate" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_dusk" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_fibonacci" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_hologram" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_loyalty_card" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_lucky_cat" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_midas_mask" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_bloodstone" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_arrowhead" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_onyx_agate" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_selzer" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_trading" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_abstract" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_blue_joker" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_cavendish" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_photograph" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_hanging_chad" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_mail" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_brainstorm" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_mime" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_steel_joker" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_reserved_parking" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "j_mp_defensive_joker" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "c_justice" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "c_deja_vu" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "c_trance" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "v_magic_trick" })
table.insert(MP.DECK.BADLATRO.BANNED_CARDS, { id = "m_glass" })

table.insert(MP.DECK.BADLATRO.BANNED_TAGS, { id = "tag_uncommon" })
table.insert(MP.DECK.BADLATRO.BANNED_TAGS, { id = "tag_meteor" })
table.insert(MP.DECK.BADLATRO.BANNED_TAGS, { id = "tag_garbage" })
table.insert(MP.DECK.BADLATRO.BANNED_TAGS, { id = "tag_top_up" })
table.insert(MP.DECK.BADLATRO.BANNED_TAGS, { id = "tag_handy" })

SMODS.Challenge({
	key = "badlatro",
	name = "Badlatro",
	rules = {
		custom = {},
		modifiers = {},
	},
	jokers = {},
	consumeables = {},
	vouchers = {},
	restrictions = {
		banned_cards = MP.DECK.BADLATRO.BANNED_CARDS,
		banned_tags = MP.DECK.BADLATRO.BANNED_TAGS,
		banned_other = MP.DECK.BADLATRO.BANNED_BLINDS,
	},
	deck = {
		type = MP.DECK.BADLATRO.TYPE,
	},
	unlocked = function(self)
		return false
	end,
})
