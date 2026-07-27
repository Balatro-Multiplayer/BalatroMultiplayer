function apply_phantom(card)
	card.ability.eternal = true
	card.ability.mp_sticker_nemesis = true
end

function remove_phantom(card)
	card.ability.eternal = false
	card.ability.mp_sticker_nemesis = false
end

SMODS.Edition({
	key = "phantom",
	shader = "voucher",
	discovered = true,
	unlocked = true,
	config = {},
	in_shop = false,
	apply_to_float = true,
	badge_colour = G.C.PURPLE,
	sound = { sound = "negative", per = 1.5, vol = 0.4 },
	disable_shadow = false,
	disable_base_shader = true,
	extra_cost = 0, -- Min sell value is set to -1 by Multiplayer (1 by default) so this is a hack to make the card this is applied to not have a sell value
	on_apply = apply_phantom,
	on_remove = remove_phantom,
	on_load = apply_phantom,
	prefix_config = { shader = false },
	mp_credits = {
		idea = { "Virtualized" },
		art = { "Carter" },
		code = { "Virtualized" },
	},
})

local get_card_areas_ref = SMODS.get_card_areas
function SMODS.get_card_areas(_type, _context)
	if _type == "jokers" and MP.shared then
		local t = get_card_areas_ref(_type, _context)
		table.insert(t, MP.shared)
		return t
	end
	return get_card_areas_ref(_type, _context)
end
