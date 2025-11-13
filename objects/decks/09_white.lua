
--[[
SMODS.Back({
	key = "white",
	config = {},
	atlas = "mp_decks",
	pos = { x = 2, y = 1 },
	mp_credits = { art = { "aura!" }, code = { "Toneblock" } },
	apply = function(self)
		if MP.LOBBY.code then
			G.GAME.modifiers.view_nemesis_deck = true
		end
	end,
})

-- new global table for white deck stuff because there's a lot of things and i want it to be as clean as possible
-- some may argue it's worse. perhaps it is
MP.WHITE = {
	state = {
		client = {},
		nemesis = {},
	}

}

function MP.WHITE.save_state()
	local save = MP.WHITE.state.client
	
	save.ante = G.GAME.round_resets.ante
	
	local jokers_save = G.jokers:save()
	save.jokers = MP.UTILS.str_pack_and_encode(jokers_save)
	
	local deck_save = G.deck:save() -- gotta be careful that every card is actually in the deck at this point
	save.deck = MP.UTILS.str_pack_and_encode(deck_save)
end

function MP.WHITE.send_state()
end

function MP.WHITE.request_state() -- need another function for "request until received"
end
]]
