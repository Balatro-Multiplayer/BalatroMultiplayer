G.MULTIPLAYER.DECK = {}

G.MULTIPLAYER.DECK.BANNED_CARDS = {
	{ id = "j_mr_bones" },
	{ id = "j_luchador" },
	{ id = "j_matador" },
	{ id = "j_chicot" },
	{ id = "v_hieroglyph" },
	{ id = "v_petroglyph" },
	{ id = "v_directors_cut" },
	{ id = "v_retcon" },
}

G.MULTIPLAYER.DECK.BANNED_TAGS = {
	{ id = "tag_boss" },
}

function G.MULTIPLAYER.DECK.ban_card(card_id)
	table.insert(G.MULTIPLAYER.DECK.BANNED_CARDS, { id = card_id })
end

function G.MULTIPLAYER.DECK.ban_tag(tag_id)
	table.insert(G.MULTIPLAYER.DECK.BANNED_TAGS, { id = tag_id })
end

local j_broken = {
	order = 1,
	unlocked = true,
	start_alerted = true,
	discovered = true,
	blueprint_compat = true,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 4,
	cost = 10000,
	name = "BROKEN",
	pos = { x = 9, y = 9 },
	set = "Joker",
	effect = "",
	cost_mult = 1.0,
	config = {},
	key = "j_broken",
}

local card_init_ref = Card.init
function Card:init(X, Y, W, H, card, center, params)
	if center == nil then
		center = j_broken
	end
	card_init_ref(self, X, Y, W, H, card, center, params)
end

G.MULTIPLAYER.DECK_TYPE = "Challenge Deck"
