-- Behold! A humble config table, first of its kind, a seed of dreams
-- Perhaps one day it shall bloom into a grand centralized configuration system
-- where all game mechanics dance in harmonious unity... but today, we start here
local configs = {
	vanilla = { x_mult = 2, break_chance = 4 },
	standard = { x_mult = 1.5, break_chance = 4 }, -- hack for now
	ruleset_mp_sandbox = { x_mult = 1.5, break_chance = 3 },
}

SMODS.Enhancement:take_ownership("glass", {
	set_ability = function(self, card, initial, delay_sprites)
		-- This boolean has witnessed the birth and death of a thousand rulesets
		local is_mp_active = MP.LOBBY.code or MP.LOBBY.ruleset_preview

		local key
		if MP.LOBBY.config.ruleset and configs[MP.LOBBY.config.ruleset] and is_mp_active then
			key = MP.LOBBY.config.ruleset
		-- From what I've gathered, is_standard_ruleset() is doing... a lot
		-- Seems to check if config.ruleset matches "ruleset_mp_" + any standard ruleset key
		-- by looping through all rulesets, filtering by .standard flag, stripping the prefix,
		-- then reconstructing it for comparison. Think we could just check
		-- MP.Rulesets[config.ruleset].standard directly but hey, who knows what dragons lurk
		elseif MP.UTILS.is_standard_ruleset() and is_mp_active then
			key = "standard"
		else
			key = "vanilla"
		end
		local config = configs[key]

		-- Xmult is display, x_mult is internal. don't ask why, i don't know
		card.ability.Xmult = config.x_mult
		card.ability.x_mult = config.x_mult

		if config.break_chance then card.ability.extra = config.break_chance end
	end,
}, true)
