SMODS.Atlas({
	key = "defensive_joker",
	path = "j_defensive_joker.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "defensive_joker",
	atlas = "defensive_joker",
	rarity = 1,
	cost = 4,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { t_chips = 0, extra = { extra = 125 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.extra, card.ability.t_chips } }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	update = function(self, card, dt)
		if MP.LOBBY.code then
			if G.STAGE == G.STAGES.RUN then
				card.ability.t_chips = math.max((MP.GAME.enemy.lives - MP.GAME.lives) * card.ability.extra.extra, 0)
			end
		else
			card.ability.t_chips = 0
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers and context.joker_main then
			return {
				message = localize({
					type = "variable",
					key = "a_chips",
					vars = { card.ability.t_chips },
				}),
				chip_mod = card.ability.t_chips,
			}
		end
	end,
	mp_credits = {
		idea = { "didon't" },
		art = { "TheTrueRaven" },
		code = { "Virtualized" },
	},
})
