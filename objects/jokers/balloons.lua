SMODS.Atlas({ key = "balloons", path = "j_balloons.png", px = 71, py = 95 })

SMODS.Joker({
	key = "balloons", atlas = "balloons", rarity = 2, cost = 6,
	unlocked = true, discovered = true, blueprint_compat = false,
	eternal_compat = false, perishable_compat = true,
	config = { extra = { max_tags = 3 } },
	loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.max_tags } } end,
	mp_include = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers and not MP.is_layer_active("sandbox")
	end,
	mp_credits = { art = { "Kars" } },
})

local BALLOONS_VANILLA_TAGS = {
	"tag_uncommon",
	"tag_foil",
	"tag_holo",
	"tag_polychrome",
	"tag_voucher",
	"tag_standard",
	"tag_charm",
	"tag_meteor",
	"tag_buffoon",
	"tag_handy",
	"tag_garbage",
	"tag_ethereal",
	"tag_coupon",
	"tag_double",
	"tag_d_six",
	"tag_top_up",
	"tag_skip",
	"tag_orbital",
	"tag_economy",
}

MP.PVP_SELL.register("j_mp_balloons", function(card)
	local count = math.min(card.ability.extra.max_tags, MP.PVP_SELL.empty_joker_slots_after_sale(card))
	if count < 1 then
		card_eval_status_text(card, "extra", nil, nil, nil, { message = "No empty slots", colour = G.C.RED })
		return
	end
	local pool = {}
	for _, tag_key in ipairs(BALLOONS_VANILLA_TAGS) do
		-- Exact whitelist: custom Multiplayer/modded Tags can never enter the pool.
		if G.P_TAGS and G.P_TAGS[tag_key] then pool[#pool + 1] = tag_key end
	end
	if #pool < 1 then return end
	for i = 1, count do
		local tag_key = pseudorandom_element(pool, pseudoseed("j_mp_balloons_" .. tostring(i)))
		MP.PVP_SELL.add_tag_with_sfx(tag_key)
	end
	card_eval_status_text(card, "extra", nil, nil, nil, {
		message = "+" .. tostring(count) .. " Tag" .. (count == 1 and "" or "s"), colour = G.C.FILTER,
	})
end)
