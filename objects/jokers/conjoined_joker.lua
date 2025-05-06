SMODS.Atlas({
	key = "conjoined_joker",
	path = "j_conjoined_joker.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "conjoined_joker",
	atlas = "conjoined_joker",
	rarity = 2,
	cost = 6,
	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,
	config = { extra = { x_mult_gain = 0.5, max_x_mult = 3, x_mult = 1 } },
	loc_vars = function(self, info_queue, card)
		add_nemesis_info(info_queue)
		return { vars = { card.ability.extra.x_mult_gain, card.ability.extra.max_x_mult, card.ability.extra.x_mult } }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.multiplayer_jokers
	end,
	add_to_deck = function(self, card, from_debuffed)
		if not from_debuffed and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.send_phantom("j_mp_conjoined_joker")
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not from_debuff and (not card.edition or card.edition.type ~= "mp_phantom") then
			MP.ACTIONS.remove_phantom("j_mp_conjoined_joker")
		end
	end,
	update = function(self, card, dt)
		if MP.LOBBY.code then
			if G.STAGE == G.STAGES.RUN then
				card.ability.extra.x_mult = math.max(
					math.min(1 + (MP.GAME.enemy.hands * card.ability.extra.x_mult_gain), card.ability.extra.max_x_mult),
					1
				)
			end
		else
			card.ability.extra.x_mult = 1
		end
	end,
	calculate = function(self, card, context)
		if context.cardarea == G.jokers 
		    and context.joker_main 
	            and MP.is_pvp_boss() 
	            and (not card.edition or card.edition.type ~= "mp_phantom")
		      then
			return {
				x_mult = card.ability.extra.x_mult,
			}
		end
	end,
	mp_credits = {
		idea = { "Zilver" },
		art = { "Nas4xou" },
		code = { "Virtualized" },
	},
})
