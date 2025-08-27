SMODS.Joker({
	key = "cloud_9_sandbox",
	-- no_collection = true,
	unlocked = true,
	discovered = true,
	blueprint_compat = false,
	perishable_compat = true,
	eternal_compat = true,
	rarity = 2,
	cost = 7,
	pos = { x = 7, y = 12 },
	config = { extra = 2, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		local nine_tally = 0
		if G.playing_cards ~= nil then
			for k, v in pairs(G.playing_cards) do
				if v:get_id() == 9 then nine_tally = nine_tally + 1 end
			end
		end

		return {
			vars = {
				card.ability.extra,
				(math.min(nine_tally, 4) + math.max(nine_tally - 4, 0) * card.ability.extra) or 0,
			},
		}
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
	calc_dollar_bonus = function(self, card)
		local nine_tally = 0
		for k, v in pairs(G.playing_cards) do
			if v:get_id() == 9 then nine_tally = nine_tally + 1 end
		end
		return (math.min(nine_tally, 4) + math.max(nine_tally - 4, 0) * card.ability.extra) or 0
	end,
})
