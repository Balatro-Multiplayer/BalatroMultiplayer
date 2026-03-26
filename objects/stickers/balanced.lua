SMODS.Atlas({
	key = "sticker_balanced",
	path = "sticker_balanced.png",
	px = 71,
	py = 95,
})

SMODS.Sticker({
	key = "sticker_balanced",
	atlas = "sticker_balanced",
	badge_colour = G.C.MULTIPLAYER,
	default_compat = false,
	needs_enable_flag = true,
	hide_badge = false,
	loc_vars = function(self, info_queue, card)
		local key = "mp_sticker_balanced_" .. card.config.center_key
		if G.localization.descriptions.Other[key] then
			return { key = key }
		end
		return {}
	end,
})
