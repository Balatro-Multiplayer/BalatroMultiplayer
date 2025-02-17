function apply_phantom(card)
	card.ability.eternal = true
	card.ability.mp_sticker = true
end

function remove_phantom(card)
	card.ability.eternal = false
	card.ability.mp_sticker = false
end

SMODS.Edition({
	key = "phantom",
	shader = "voucher",
	discovered = true,
	unlocked = true,
	config = { card_limit = 1 },
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

SMODS.Joker:take_ownership("abstract", {
	loc_vars = function(self, info_queue, card)
		local jokers = G.MULTIPLAYER.UTILS.get_non_phantom_jokers()
		return {
			vars = { card.ability.extra, (#jokers or 0) * card.ability.extra },
		}
	end,
	calculate = function(self, card, context)
		local x = #G.MULTIPLAYER.UTILS.get_non_phantom_jokers()
		return {
			message = localize({ type = "variable", key = "a_mult", vars = { x * card.ability.extra } }),
			mult_mod = x * card.ability.extra,
		}
	end,
	in_pool = function(self)
		return not G.LOBBY.code
	end,
}, true)
