-- Pausing this because baby steps
SMODS.Atlas({
	key = "mail_sandbox",
	path = "j_mail_sandbox.png",
	px = 71,
	py = 95,
})

SMODS.Joker({
	key = "mail_sandbox",
	no_collection = MP.sandbox_no_collection,
	blueprint_compat = true,
	rarity = 1,
	cost = 4,
	atlas = "mail_sandbox",
	config = { extra = { dollars = 8 } },
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.dollars,
				localize((G.GAME.current_round.mail_card or {}).rank or "Ace", "ranks"),
			},
		}
	end,
	-- TODO actually implemnt add_to_deck behaviour
	calculate = function(self, card, context)
		if
			context.discard
			and not context.other_card.debuff
			and context.other_card:get_id() == G.GAME.current_round.mail_card.id
		then
			G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
			return {
				dollars = card.ability.extra.dollars,
				func = function() -- This is for timing purposes, it runs after the dollar manipulation
					G.E_MANAGER:add_event(Event({
						func = function()
							G.GAME.dollar_buffer = 0
							return true
						end,
					}))
				end,
			}
		end
	end,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
