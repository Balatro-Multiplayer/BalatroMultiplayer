SMODS.Atlas({
	key = "sandbox_error",
	path = "j_ERROR_sandbox.png",
	px = 71,
	py = 95,
})

for i = 1, 21 do
	SMODS.Joker({
		key = "preview_disabled_sandbox_" .. i,
		loc_vars = function(self, info_queue, card)
			local r_mults = {}
			for i = 1, 333 do
				r_mults[#r_mults + 1] = tostring(i)
			end
			local loc_mult = "$"
			main_start = {
				{ n = G.UIT.T, config = { text = "NO PREVIEW", colour = G.C.GREEN, scale = 0.58 } },
				{
					n = G.UIT.O,
					config = {
						object = DynaText({
							string = r_mults,
							colours = { G.C.MONEY },
							pop_in_rate = 9999999,
							silent = true,
							random_element = true,
							pop_delay = 1.2,
							scale = 0.32,
							min_cycle_time = 0,
						}),
					},
				},
				{
					n = G.UIT.O,
					config = {
						object = DynaText({
							string = {
								{ string = "rand()", colour = G.C.JOKER_GREY },
								{
									string = "#@"
										.. (G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.id or 11)
										.. (
											G.deck
												and G.deck.cards[1]
												and G.deck.cards[#G.deck.cards].base.suit:sub(1, 1)
											or "D"
										),
									colour = G.C.MONEY,
								},
								"$",
								"€",
								"¥",
								"despair",
								"£",
								"₹",
								"₽",
								"₩",
								"¢",
								"₿",
								"◊",
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
								-- loc_mult,
							},
							colours = { G.C.UI.TEXT_DARK },
							pop_in_rate = 9999999,
							silent = true,
							random_element = true,
							pop_delay = 0.5333,
							scale = 0.32,
							min_cycle_time = 0,
						}),
					},
				},
			}
			return {
				main_start = main_start,
				-- modified localization key trickery to ensure we always use this localization, thanks toneblock
				key = "j_mp_preview_disabled_sandbox",
			}
		end,

		atlas = "sandbox_error",
		no_collection = MP.sandbox_no_collection,
		unlocked = true,
		discovered = true,
		in_pool = false,
		mp_credits = { art = { "aura?" } },
	})
end
