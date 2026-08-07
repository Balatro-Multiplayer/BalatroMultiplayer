SMODS.Atlas({ key = "dynamic_duo", path = "j_dynamic_duo.png", px = 71, py = 95 })

SMODS.Joker({
	key = "dynamic_duo", atlas = "dynamic_duo", rarity = 2, cost = 5,
	unlocked = true, discovered = true, blueprint_compat = false,
	eternal_compat = false, perishable_compat = true,
	loc_vars = function(self, info_queue, card)
		local has_negative = false
		if G and G.jokers and G.jokers.cards then
			for _, joker in ipairs(G.jokers.cards) do
				if joker and joker.edition
					and (joker.edition.negative or joker.edition.type == "negative") then
					has_negative = true
					break
				end
			end
		end
		return { key = has_negative and "j_mp_dynamic_duo_overflow" or "j_mp_dynamic_duo" }
	end,
	mp_include = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers and not MP.is_layer_active("sandbox")
	end,
	mp_credits = { art = { "Kars" } },
})

MP.PVP_SELL.register("j_mp_dynamic_duo", function(card)
	local changed = MP.PVP_SELL.clear_area(G.jokers, card)
	changed = changed + MP.PVP_SELL.clear_nemesis_display_stickers()
	MP.PVP_SELL.send_to_nemesis("pvp_dynamic_duo")
	card_eval_status_text(card, "extra", nil, nil, nil, {
		message = changed > 0 and "Stripped!" or "No modifiers", colour = changed > 0 and G.C.FILTER or G.C.RED,
	})
end)
