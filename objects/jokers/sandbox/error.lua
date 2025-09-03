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
								{ string = "NullPointerException", colour = G.C.ORANGE },
								{ string = "undefined is not a function", colour = G.C.PURPLE },
								{ string = "malloc(): corrupted top size", colour = G.C.RED },
								{ string = "stack overflow", colour = G.C.ORANGE },
								{ string = "memory leak detected", colour = G.C.YELLOW },
								{ string = "FATAL ERROR", colour = G.C.RED },
								{ string = "core dumped", colour = G.C.JOKER_GREY },
								{ string = "buffer overflow", colour = G.C.ORANGE },
								{ string = "access violation", colour = G.C.RED },
								{ string = "cannot read property of null", colour = G.C.PURPLE },
								{ string = "division by zero", colour = G.C.YELLOW },
								{ string = "infinite recursion", colour = G.C.ORANGE },
								{ string = "out of memory", colour = G.C.RED },
								{ string = "reference before assignment", colour = G.C.PURPLE },
								{ string = "index out of bounds", colour = G.C.YELLOW },
								{ string = "panic: runtime error", colour = G.C.RED },
								{ string = "assertion failed", colour = G.C.ORANGE },
								{ string = "deadlock detected", colour = G.C.JOKER_GREY },
								{ string = "race condition", colour = G.C.YELLOW },
								{ string = "double free", colour = G.C.RED },
								{ string = "use after free", colour = G.C.ORANGE },
								{ string = "corrupted heap", colour = G.C.RED },
								{ string = "invalid opcode", colour = G.C.PURPLE },
								{ string = "bus error", colour = G.C.ORANGE },
								{ string = "illegal instruction", colour = G.C.RED },
								{ string = "floating point exception", colour = G.C.YELLOW },
								{ string = "timeout exceeded", colour = G.C.JOKER_GREY },
								{ string = "connection refused", colour = G.C.PURPLE },
								{ string = "404 not found", colour = G.C.ORANGE },
								{ string = "500 internal error", colour = G.C.RED },
								{ string = "syntax error", colour = G.C.PURPLE },
								{ string = "type error", colour = G.C.YELLOW },
								{ string = "permission denied", colour = G.C.RED },
								{ string = "file not found", colour = G.C.ORANGE },
								{ string = "disk full", colour = G.C.YELLOW },
								{ string = "network unreachable", colour = G.C.JOKER_GREY },
								{ string = "broken pipe", colour = G.C.ORANGE },
								{ string = "killed by signal 9", colour = G.C.RED },
								{ string = "zombie process", colour = G.C.JOKER_GREY },
								{ string = "thread pool exhausted", colour = G.C.PURPLE },
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
