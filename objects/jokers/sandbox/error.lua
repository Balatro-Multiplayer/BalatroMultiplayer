SMODS.Atlas({
	key = "error_sandbox",
	path = "j_ERROR_sandbox.png",
	px = 71,
	py = 95,
})

for i = 1, 21 do
	SMODS.Joker({
		key = "error_sandbox_" .. i,
		loc_vars = function(self, info_queue, card)
			local r_mults = {}
			for i = 1, 333 do
				r_mults[#r_mults + 1] = tostring(i)
			end
			local loc_mult = "(CURRENTLY " .. math.random(1, 333) .. ")"
			main_end = {
				{ n = G.UIT.T, config = { text = loc_mult, colour = lighten(G.C.PURPLE, 0.4), scale = 0.32 } },
				{
					n = G.UIT.O,
					config = {
						object = DynaText({
							string = r_mults,
							colours = { G.C.MONEY },
							pop_in_rate = 9999999,
							silent = true,
							random_element = true,
							pop_delay = 0.3,
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
								{ string = "segfault", colour = G.C.RED },
								{ string = "NullPointerException", colour = lighten(G.C.ORANGE, 0.3) },
								{ string = "undefined is not a function", colour = lighten(G.C.PURPLE, 0.4) },
								{ string = "malloc(): corrupted top size", colour = G.C.RED },
								{ string = "stack overflow", colour = G.C.VOUCHER },
								{ string = "memory leak detected", colour = lighten(G.C.GOLD, 0.2) },
								{ string = "FATAL ERROR", colour = G.C.SUITS.Hearts },
								{ string = "core dumped", colour = G.C.UI.TEXT_DARK },
								{ string = "buffer overflow", colour = G.C.IMPORTANT },
								{ string = "access violation", colour = lighten(G.C.RED, 0.1) },
								{ string = "cannot read property of null", colour = lighten(G.C.BOOSTER, 0.3) },
								{ string = "division by zero", colour = G.C.GOLD },
								{ string = "infinite recursion", colour = G.C.FILTER },
								{ string = "out of memory", colour = G.C.ETERNAL },
								{ string = "reference before assignment", colour = lighten(G.C.PURPLE, 0.2) },
								{ string = "index out of bounds", colour = lighten(G.C.CHANCE, 0.3) },
								{ string = "panic: runtime error", colour = G.C.SUITS.Diamonds },
								{ string = "assertion failed", colour = G.C.RENTAL },
								{ string = "deadlock detected", colour = lighten(G.C.JOKER_GREY, 0.2) },
								{ string = "race condition", colour = lighten(G.C.PALE_GREEN, 0.4) },
								{ string = "double free", colour = lighten(G.C.RED, 0.2) },
								{ string = "use after free", colour = G.C.PERISHABLE },
								{ string = "corrupted heap", colour = G.C.BLIND.Boss },
								{ string = "invalid opcode", colour = lighten(G.C.SUITS.Spades, 0.6) },
								{ string = "bus error", colour = G.C.SECONDARY_SET.Voucher },
								{ string = "illegal instruction", colour = lighten(G.C.SUITS.Hearts, 0.3) },
								{ string = "floating point exception", colour = lighten(G.C.MONEY, 0.4) },
								{ string = "timeout exceeded", colour = G.C.SECONDARY_SET.Joker },
								{ string = "connection refused", colour = lighten(G.C.BOOSTER, 0.2) },
								{ string = "404 not found", colour = G.C.SECONDARY_SET.Tarot },
								{ string = "500 internal error", colour = G.C.RARITY[3] },
								{ string = "syntax error", colour = lighten(G.C.RARITY[4], 0.3) },
								{ string = "type error", colour = G.C.SECONDARY_SET.Planet },
								{ string = "permission denied", colour = lighten(G.C.ETERNAL, 0.2) },
								{ string = "file not found", colour = lighten(G.C.VOUCHER, 0.3) },
								{ string = "disk full", colour = G.C.HAND_LEVELS[4] },
								{ string = "network unreachable", colour = lighten(G.C.GREY, 0.4) },
								{ string = "broken pipe", colour = G.C.HAND_LEVELS[6] },
								{ string = "killed by signal 9", colour = G.C.SO_1.Hearts },
								{ string = "zombie process", colour = lighten(G.C.L_BLACK, 0.5) },
								{ string = "thread pool exhausted", colour = G.C.HAND_LEVELS[7] },
								{
									string = "0x" .. string.format("%08X", math.random(0, 0xFFFFFFFF)),
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
				main_end = main_end,
				-- modified localization key trickery to ensure we always use this localization, thanks toneblock
				key = "j_mp_error_sandbox",
			}
		end,

		atlas = "error_sandbox",
		no_collection = MP.sandbox_no_collection,
		unlocked = true,
		discovered = true,
		in_pool = false,
		mp_credits = { art = { "aura?" } },
	})
end
