-- Effect lives in layers/polymorph_spam.lua (via rules.custom -> mp_polymorph_spam).
SMODS.Challenge({
	key = "polymorph_spam",
	rules = {
		custom = {
			{ id = "mp_polymorph_spam" },
			{ id = "mp_polymorph_spam_EXTENDED1" },
			{ id = "mp_polymorph_spam_EXTENDED2" },
		},
	},
	restrictions = {
		banned_cards = function()
			local ret = {}
			local add = {
				j_campfire = true,
				j_invisible = true,
				j_caino = true,
				j_yorick = true,
			}
			for i, v in ipairs(G.P_CENTER_POOLS.Joker) do
				if (not v.perishable_compat) or add[v.key] then ret[#ret + 1] = { id = v.key } end
			end
			return ret
		end,
	},
	unlocked = function(self)
		return true
	end,
})
