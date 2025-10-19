SMODS.Back({
	key = "indigo",
	config = {},
	atlas = "mp_decks",
	pos = { x = 1, y = 0 },
	mp_credits = { art = { "aura!" }, code = { "Toneblock" } },
	apply = function(self)
		G.GAME.modifiers.mp_indigo = true
	end,
})

local can_skip_ref = G.FUNCS.can_skip_booster
G.FUNCS.can_skip_booster = function(e)
	if G.GAME.modifiers.mp_indigo then
		if check then
			e.config.colour = G.C.UI.BACKGROUND_INACTIVE
			e.config.button = nil
			return
		end
	end
	return can_skip_ref(e)
end

local set_ability_ref = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
	set_ability_ref(self, center, initial, delay_sprites)
	if self.ability.set == "Booster" and G.GAME.modifiers.mp_indigo then
		self.ability.choose = self.ability.choose*2
	end
end