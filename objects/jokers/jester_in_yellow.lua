SMODS.Atlas({ key = "jester_in_yellow", path = "j_jester_in_yellow.png", px = 71, py = 95 })

SMODS.Joker({
	key = "jester_in_yellow", atlas = "jester_in_yellow", rarity = 2, cost = 4,
	unlocked = true, discovered = true, blueprint_compat = false,
	eternal_compat = false, perishable_compat = true,
	mp_include = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers and not MP.is_layer_active("sandbox")
	end,
	mp_credits = { art = { "Kars" } },
})

MP.PVP_SELL.register("j_mp_jester_in_yellow", function(card)
	local area = MP.shared
	if not (area and area.cards and #area.cards > 0) then
		card_eval_status_text(card, "extra", nil, nil, nil, { message = "No Nemesis Joker", colour = G.C.RED })
		return
	end
	local candidates = {}
	for i, joker in ipairs(area.cards) do
		if joker and not joker.REMOVED and not (joker.ability and joker.ability.rental) then
			candidates[#candidates + 1] = { index = i, card = joker }
		end
	end
	if #candidates < 1 then
		card_eval_status_text(card, "extra", nil, nil, nil, { message = "Already Rental", colour = G.C.RED })
		return
	end
	local selected = pseudorandom_element(candidates, pseudoseed("j_mp_jester_in_yellow"))
	MP.PVP_SELL.apply_rental(selected.card)
	MP.PVP_SELL.send_to_nemesis("pvp_jester_rental", { index = selected.index })
	card_eval_status_text(card, "extra", nil, nil, nil, { message = "Rental!", colour = G.C.MONEY })
end)
