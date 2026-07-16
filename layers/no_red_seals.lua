-- No Red Seals: red seals never get applied — pack polls, Certificate, copies, etc.
-- Deja Vu does nothing but apply a Red Seal, so ban it outright rather than leave a
-- dead spectral in the pool
MP.Layer("no_red_seals", {
	banned_consumables = { "c_deja_vu" },
	calculate = function(self, context)
		if context.apply_bans then
			G.GAME.modifiers.mp_no_red_seals = true
		end
	end,
})

-- the "clean" way is to yank Red out of the seal pool. sure. except deja vu hardcodes
-- a red seal, certificate flings random ones, copied cards drag their seal along... and
-- i am not lovely patching every single one of those. no thank you.
-- returning instead of passing nil so it doesn't nuke a seal that was already sitting there
local set_seal_ref = Card.set_seal
function Card:set_seal(_seal, silent, immediate)
	if _seal == "Red" and G.GAME and G.GAME.modifiers and G.GAME.modifiers.mp_no_red_seals then
		return -- not today
	end
	return set_seal_ref(self, _seal, silent, immediate)
end
