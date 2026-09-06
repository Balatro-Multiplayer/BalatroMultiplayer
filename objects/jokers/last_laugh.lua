SMODS.Atlas({ key = "last_laugh", path = "j_last_laugh.png", px = 71, py = 95 })

SMODS.Joker({
	key = "last_laugh", atlas = "last_laugh", rarity = 2, cost = 5,
	unlocked = true, discovered = true, blueprint_compat = false,
	eternal_compat = false, perishable_compat = true,
	config = { extra = { destroy = 5 } },
	loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.destroy } } end,
	mp_include = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers and not MP.is_layer_active("sandbox")
	end,
	mp_credits = { art = { "Kars" } },
})

MP.PVP_SELL.register("j_mp_last_laugh", function(card)
	local targets = MP.PVP_SELL.random_hand_cards(card.ability.extra.destroy, "j_mp_last_laugh")
	if #targets < 1 then
		card_eval_status_text(card, "extra", nil, nil, nil, { message = "No cards", colour = G.C.RED })
		return
	end
	for _, target in ipairs(targets) do
		G.E_MANAGER:add_event(Event({ func = function()
			if target and not target.destroyed then
				play_sound("tarot1")
				target.T.r = -0.2
				target:juice_up(0.3, 0.4)
			end
			return true
		end }))
	end
	SMODS.destroy_cards(targets)
	card_eval_status_text(card, "extra", nil, nil, nil, { message = "Destroyed " .. tostring(#targets), colour = G.C.RED })
end)
