MP.Ruleset({
	key = "vanilla",
	challenge_deck = "c_mp_vanilla"
})

MP.DECK.VANILLA = {}
MP.DECK.VANILLA.BANNED_CARDS = MP.UTILS.shallow_copy(MP.DECK.BANNED_CARDS)
MP.DECK.VANILLA.BANNED_TAGS = MP.UTILS.shallow_copy(MP.DECK.BANNED_TAGS)
MP.DECK.VANILLA.BANNED_BLINDS = MP.UTILS.shallow_copy(MP.DECK.BANNED_BLINDS)
MP.DECK.VANILLA.TYPE = MP.DECK.TYPE .. ""

SMODS.Challenge({
	key = "vanilla",
	name = "Vanilla",
	rules = {
		custom = {},
		modifiers = {},
	},
	jokers = {},
	consumeables = {},
	vouchers = {},
	restrictions = {
		banned_cards = MP.DECK.VANILLA.BANNED_CARDS,
		banned_tags = MP.DECK.VANILLA.BANNED_TAGS,
		banned_other = MP.DECK.VANILLA.BANNED_BLINDS,
	},
	deck = {
		type = MP.DECK.VANILLA.TYPE,
	},
	unlocked = function(self)
		return false
	end,
})