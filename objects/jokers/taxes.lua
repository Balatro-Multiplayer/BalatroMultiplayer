local function calculate_taxes_mult(card)
	return MP.GAME.enemy.sells * card.ability.extra.mult_gain
end

SMODS.Atlas({
	key = "taxes",
	path = "j_taxes.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "taxes",
	atlas = "taxes",
	rarity = 1,
	cost = 5,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = false,
	config = { extra = { mult_gain = 4, mult = 0} },
	loc_vars = function(self, info_queue, card)
		MP.UTILS.add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.mult_gain, card.ability.extra.mult, calculate_taxes_mult(card)} }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				mult = card.ability.extra.mult,
			}
		elseif context.setting_blind and context.blind.key == "bl_mp_nemesis" then
			card.ability.extra.mult = calculate_taxes_mult(card)
			card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_filed_ex')})
		end
	end,
	mp_credits = {
		idea = { "Zwei" },
		art = { "Kittyknight" },
		code = { "Virtualized" },
	},
})
