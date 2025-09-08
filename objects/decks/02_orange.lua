SMODS.Back({
	key = "orange",
	config = { consumables = { "c_hanged_man", "c_hanged_man" } },
	atlas = "mp_decks",
	pos = { x = 2, y = 0 },
	mp_credits = { art = { "aura!" }, code = { "Toneblock" } },
	apply = function(self)
		stop_use()
		local lock = self.key
		G.CONTROLLER.locks[lock] = true
		-- "yeah just triple layer the event surely that works...WHAT THE SHIT"
		G.E_MANAGER:add_event(Event({
			func = function()
				G.E_MANAGER:add_event(Event({
					func = function()
						G.E_MANAGER:add_event(Event({
							func = function()
								local key = "p_arcana_mega_" .. (math.random(1, 2))
								local card = Card(
									G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2,
									G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2,
									G.CARD_W * 1.27,
									G.CARD_H * 1.27,
									G.P_CARDS.empty,
									G.P_CENTERS["p_mp_standard_giga"],
									{ bypass_discovery_center = true, bypass_discovery_ui = true }
								)
								card.cost = 0
								card.from_tag = true
								delay(0.2)
								G.FUNCS.use_card({ config = { ref_table = card } })
								card:start_materialize()
								G.CONTROLLER.locks[lock] = nil
								return true
							end,
						}))
						return true
					end,
				}))
				return true
			end,
		}))
	end,
})
