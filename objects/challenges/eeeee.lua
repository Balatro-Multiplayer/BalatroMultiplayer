SMODS.Challenge({
	key = "mp_eeeee",
	rules = {
		custom = {
			{ id = "mp_eeeee" },
		},
	},
	unlocked = function(self)
		return true
	end,
})

local pseudoseed_ref = pseudoseed
function pseudoseed(key, predict_seed)
	if G.GAME and G.GAME.modifiers and G.GAME.modifiers.mp_eeeee and not G._MP_UNSAVED_PRNG then
		G.GAME.mp_eeeee = G.GAME.mp_eeeee or {}
		local ante = G.GAME.round_resets.mp_real_ante or G.GAME.round_resets.ante
		if not G.GAME.mp_eeeee[ante.."_"..key] then
			math.randomseed(pseudohash((G.GAME.pseudorandom.seed or '')..ante.."mp_eeeee_"..key))
			G.GAME.mp_eeeee[ante.."_"..key] = {
				poll = math.random(),
				val = math.random(),
			}
		end
		if G.GAME.mp_eeeee[ante.."_"..key].poll < 0.4 then
			return G.GAME.mp_eeeee[ante.."_"..key].val
		end
	end
	return pseudoseed_ref(key, predict_seed)
end
