SMODS.Atlas({ key = "line_cutter", path = "j_line_cutter.png", px = 71, py = 95 })

SMODS.Joker({
	key = "line_cutter", atlas = "line_cutter", rarity = 2, cost = 4,
	unlocked = true, discovered = true, blueprint_compat = false,
	eternal_compat = false, perishable_compat = true,
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = { key = "tag_voucher", set = "Tag" }
		return { vars = {} }
	end,
	mp_include = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers and not MP.is_layer_active("sandbox")
	end,
	mp_credits = { art = { "Kars" }},
})

MP.PVP_SELL.register("j_mp_line_cutter", function(card)
	MP.PVP_SELL.add_tag_with_sfx("tag_voucher")
	card_eval_status_text(card, "extra", nil, nil, nil, { message = "+1 Voucher Tag!", colour = G.C.FILTER })
end)
