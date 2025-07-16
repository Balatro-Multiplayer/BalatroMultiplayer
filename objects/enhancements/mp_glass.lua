SMODS.Enhancement:take_ownership("glass", {
	set_ability = function(self, card, initial, delay_sprites)
		local x = MP.UTILS.is_standard_ruleset() and (MP.LOBBY.code or MP.LOBBY.ruleset_preview) and 1.5 or 2
		-- Xmult is display, x_mult is internal. don't ask why, i don't know
		card.ability.Xmult = x
		card.ability.x_mult = x
	end,
}, true)