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

	unlocked = true,
	discovered = true,
	blueprint_compat = true,
	rarity = 1,
	cost = 4,
	atlas = "mail_sandbox",
	config = { extra = { dollars = 8, rank = nil }, mp_sticker_balanced = true },
	loc_vars = function(self, info_queue, card)
		local rank = card.ability.extra.rank or (G.GAME.current_round.mail_card or {}).rank or "Ace"
		return {
			vars = {
				card.ability.extra.dollars,
				localize(rank, "ranks"),
			},
		}
	end,
	add_to_deck = function(self, card, from_debuff)
		-- Don't overwrite rank if card is re-added after debuff
		if card.ability.extra.rank == nil then card.ability.extra.rank = G.GAME.current_round.mail_card.rank end
	end,
	calculate = function(self, card, context)
		if
			context.discard
			and not context.other_card.debuff
			and context.other_card:get_id() == card.ability.extra.rank
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
