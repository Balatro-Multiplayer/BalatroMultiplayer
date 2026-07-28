SMODS.Atlas({ key = "occultist", path = "j_occultist.png", px = 71, py = 95 })

SMODS.Joker({
	key = "occultist", atlas = "occultist", rarity = 2, cost = 6,
	unlocked = true, discovered = true, blueprint_compat = false,
	eternal_compat = false, perishable_compat = true,
	config = { extra = { max_tags = 3 } },
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = { key = "tag_charm", set = "Tag" }
		return { vars = { card.ability.extra.max_tags } }
	end,
	mp_include = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers and not MP.is_layer_active("sandbox")
	end,
	mp_credits = { art = { "Kars" } },
})

MP.PVP_SELL.register("j_mp_occultist", function(card)
	local count = math.min(card.ability.extra.max_tags, MP.PVP_SELL.empty_joker_slots_after_sale(card))
	for i = 1, count do MP.PVP_SELL.add_tag_with_sfx("tag_charm") end
	card_eval_status_text(card, "extra", nil, nil, nil, {
		message = count > 0 and ("+" .. tostring(count) .. " Charm Tag" .. (count == 1 and "" or "s")) or "No empty slots",
		colour = count > 0 and G.C.FILTER or G.C.RED,
	})
end)
