MP.Ruleset({
	key = "standard",
	challenge_deck = "c_mp_standard"
})

MP.DECK.STANDARD = {}
MP.DECK.STANDARD.BANNED_CARDS = MP.UTILS.shallow_copy(MP.DECK.BANNED_CARDS)
MP.DECK.STANDARD.BANNED_TAGS = MP.UTILS.shallow_copy(MP.DECK.BANNED_TAGS)
MP.DECK.STANDARD.BANNED_BLINDS = MP.UTILS.shallow_copy(MP.DECK.BANNED_BLINDS)
MP.DECK.STANDARD.TYPE = MP.DECK.TYPE .. ""

table.insert(MP.DECK.STANDARD.BANNED_CARDS, { id = "j_hanging_chad" })
table.insert(MP.DECK.STANDARD.BANNED_CARDS, { id = "m_glass" })
table.insert(MP.DECK.STANDARD.BANNED_CARDS, { id = "c_justice" })

SMODS.Challenge({
	key = "standard",
	name = "Standard",
	rules = {
		custom = {
			{ id = "hanging_chad_rework"},
			{ id = "glass_cards_rework"},
		},
		modifiers = {},
	},
	jokers = {},
	consumeables = {},
	vouchers = {},
	restrictions = {
		banned_cards = MP.DECK.STANDARD.BANNED_CARDS,
		banned_tags = MP.DECK.STANDARD.BANNED_TAGS,
		banned_other = MP.DECK.STANDARD.BANNED_BLINDS,
	},
	deck = {
		type = MP.DECK.STANDARD.TYPE,
	},
	unlocked = function(self)
		return false
	end,
})

SMODS.Joker({
	key = "hanging_chad",
	no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 1,
	cost = 4,
	pos = { x = 9, y = 6 },
	config = { extra = 1, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		return { vars = {
			card.ability.extra
		}}
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.play and context.repetition then
			if context.other_card == context.scoring_hand[1] then
				return {
					message = localize('k_again_ex'),
					repetitions = card.ability.extra,
					card = card
				}
			end
			if context.other_card == context.scoring_hand[2] then
				return {
					message = localize('k_again_ex'),
					repetitions = card.ability.extra,
					card = card
				}
			end
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_standard" and MP.LOBBY.code
	end,
})

SMODS.Enhancement({
	key = "glass",
	no_collection = true,
	config = {
		Xmult = 1.5,
		extra = 4,
	},
	shatters = true,
	loc_vars = function(self, info_queue, card)
		return { vars = {
			card.ability.Xmult, 
			G.GAME.probabilities.normal, 
			card.ability.extra
		}}
	end,
	pos = { x = 5, y = 1 },
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_standard" and MP.LOBBY.code
	end,
	calculate = function(self, card, context)
		if context.destroy_card and context.cardarea == G.play  then
			if pseudorandom('glass') < G.GAME.probabilities.normal/card.ability.extra then
				return {
					remove = true
				}
			end
		end
	end,
})