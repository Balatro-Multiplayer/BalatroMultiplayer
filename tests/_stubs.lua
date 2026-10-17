--[[
  Hook-target stubs for loading layers/*.lua outside the game.

  Layer files wrap vanilla functions at load time (`local ref = Card.set_seal`),
  so those globals have to exist before dofile. Everything here is `x = x or ...`
  so a test's own, more specific stubs win. Load after the test's SMODS / G / MP
  stubs:

    dofile("tests/_stubs.lua")
]]

local noop = function() end

SMODS = SMODS or {}
SMODS.calculate_context = SMODS.calculate_context or noop
SMODS.showman = SMODS.showman or function()
	return false
end
SMODS.Mods = SMODS.Mods or {}
SMODS.Joker = SMODS.Joker or {
	register = function(self)
		return self
	end,
}
SMODS.Consumable = SMODS.Consumable or {
	register = function(self)
		return self
	end,
}
SMODS.Tag = SMODS.Tag or {
	register = function(self)
		return self
	end,
}

G = G or {}
G.C = G.C or setmetatable({}, {
	__index = function()
		return { 1, 1, 1, 1 }
	end,
})
G.FUNCS = G.FUNCS or {}

CardArea = CardArea or { update = noop }
UIElement = UIElement or { update_text = noop }
Card = Card or {}
Card.set_seal = Card.set_seal or noop
Card.set_ability = Card.set_ability or noop
Card.apply_to_run = Card.apply_to_run or noop
Back = Back or {}
Back.trigger_effect = Back.trigger_effect or noop
Back.apply_to_run = Back.apply_to_run or noop
Tag = Tag or { init = noop }
Blind = Blind or { set_blind = noop }
Game = Game or { update = noop }

generate_card_ui = generate_card_ui or noop
localize = localize or function(k)
	return k
end
add_joker = add_joker or noop
new_round = new_round or noop
end_round = end_round or noop
sendDebugMessage = sendDebugMessage or noop
pseudoshuffle = pseudoshuffle or noop
pseudoseed = pseudoseed or function()
	return 0
end
pseudorandom_element = pseudorandom_element or function(t)
	return t[1]
end

-- Vanilla's own hash + seeded roll (functions/misc_functions.lua), copied so
-- MP.rng gives the same numbers here as in game. math.randomseed with a
-- fractional seed needs LuaJIT, which is also what LÖVE runs.
pseudohash = pseudohash
	or function(str)
		local num = 1
		for i = #str, 1, -1 do
			num = ((1.1239285023 / num) * string.byte(str, i) * math.pi + math.pi * i) % 1
		end
		return num
	end
pseudorandom = pseudorandom
	or function(seed, min, max)
		math.randomseed(seed)
		if min and max then return math.random(min, max) end
		return math.random()
	end
