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

G.MULTIPLAYER.MAX_STAKE = 0

local stake_queue = {}

function G.MULTIPLAYER.set_max_stake(stake_key)
	if not SMODS.booted then
		stake_queue[stake_key] = true
		return
	end
	local stake = 1
	repeat
		local key = SMODS.stake_from_index(stake)
		if key == stake_key then
			sendTraceMessage("Setting max stake to " .. stake, "MULTIPLAYER")
			G.MULTIPLAYER.MAX_STAKE = math.max(stake, G.MULTIPLAYER.MAX_STAKE)
			return
		end
		stake = stake + 1
	until key == "error"
end

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	game_update_ref(self, dt)

	if next(stake_queue) and SMODS.booted then
		for key, _ in pairs(stake_queue) do
			G.MULTIPLAYER.set_max_stake(key)
			stake_queue[key] = nil
		end
	end
end
