-- Juggle Tag
SMODS.Tag({
	key = "juggle_sandbox",
	pos = { x = 5, y = 1 },
	config = { h_size = 3 },
	loc_vars = function(self, info_queue, tag)
		return { vars = { tag.config.h_size } }
	end,
	apply = function(self, tag, context)
		if context.type == "round_start_bonus" and MP.is_pvp_boss() then
			tag:yep("+", G.C.BLUE, function()
				return true
			end)
			G.hand:change_size(tag.config.h_size)
			G.GAME.round_resets.temp_handsize = (G.GAME.round_resets.temp_handsize or 0) + tag.config.h_size
			tag.triggered = true
			return true
		end
	end,
	unlocked = true,
	discovered = true,
	no_collection = MP.sandbox_no_collection,
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
})
