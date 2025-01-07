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
