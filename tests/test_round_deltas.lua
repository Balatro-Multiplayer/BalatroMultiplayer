--[[
  Layer `round_deltas` (layers/_mutators.lua), via Glass Cannon's -2 hands.

    - "on" for the run stacks with the deck: 4 -> 2, Black Deck 3 -> 1
    - the floor holds (1 hand) and "off" undoes only what was applied
    - Chaos Clock (ante window): drawn twice is applied once, not drawn restores, and
      the current round's hands_left moves too (new_round already copied
      round_resets); an On cell is skipped by the clock

  Usage (repo root):  luajit tests/test_round_deltas.lua
]]

local ROOT = "."
SMODS = { Mods = {} }
G = { FUNCS = {} }
MP = { LOBBY = { config = {} }, SP = {} }
dofile(ROOT .. "/tests/_stubs.lua")
dofile(ROOT .. "/lib/rng.lua")
dofile(ROOT .. "/layers/_layers.lua")
dofile(ROOT .. "/layers/_mutators.lua")
dofile(ROOT .. "/layers/glass_cannon.lua")
dofile(ROOT .. "/layers/chaos_clock.lua")

local failures, checks = {}, 0
local function check(cond, msg)
	checks = checks + 1
	if not cond then failures[#failures + 1] = msg end
end

MP.active_layer_chain = function()
	return MP.MODIFIERS
end
G.E_MANAGER = { add_event = function() end }
Event = function(t)
	return t
end
copy_table = function(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end
ease_hands_played = function(mod)
	G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + mod
end
ease_discard = function(mod)
	G.GAME.current_round.discards_left = G.GAME.current_round.discards_left + mod
end

local function new_run(hands)
	G.GAME = {
		modifiers = {},
		round_resets = { hands = hands, discards = 3 },
		current_round = { hands_left = 0, discards_left = 0 },
		pseudorandom = { seed = "ROUNDDELTAS" },
	}
end

-- On for the whole run.
MP.MODIFIERS = { "glass_cannon" }
new_run(4)
MP.ApplyGameModifiers()
check(G.GAME.round_resets.hands == 2, "red deck: want 2 hands, got " .. G.GAME.round_resets.hands)
check(G.GAME.modifiers.mp_glass_cannon == true, "flag set")
check(G.GAME.current_round.hands_left == 0, "run start doesn't touch the current round")

new_run(3)
MP.ApplyGameModifiers()
check(G.GAME.round_resets.hands == 1, "black deck: want 1 hand, got " .. G.GAME.round_resets.hands)

new_run(2)
MP.ApplyGameModifiers()
check(G.GAME.round_resets.hands == 1, "floor: want 1 hand, got " .. G.GAME.round_resets.hands)

-- Chaos Clock ante window: drawn at the first blind of an ante, mid-round. Force
-- the draw per ante instead of depending on the seed.
local forced = {}
local ante_rolls = 0
MP.CHAOS_CLOCK.roll = function(_, _, _, at, ante)
	if at == "ante" then ante_rolls = ante_rolls + 1 end
	return (at == "ante" and forced[ante]) and { "glass_cannon" } or {}
end

local function clock_run(hands, draws)
	MP.MODIFIERS = { "clock_normal" }
	new_run(hands)
	G.GAME.blind_on_deck = "Small"
	forced = draws
	MP.ApplyGameModifiers()
end

local function ante(n)
	-- new_round copies round_resets into the round, then set_blind ticks the clock.
	G.GAME.round_resets.ante = n
	G.GAME.blind_on_deck = "Small"
	G.GAME.current_round.hands_left = G.GAME.round_resets.hands
	MP.CHAOS_CLOCK.on_blind_start()
end

clock_run(4, { true, true, false, true })
check(G.GAME.mp_clock and G.GAME.mp_clock.preset == "normal", "clock started on Normal")
check(G.GAME.round_resets.hands == 4, "pool layer untouched before the first draw")
ante(1)
check(G.GAME.round_resets.hands == 2, "ante 1 drawn: want 2, got " .. G.GAME.round_resets.hands)
check(
	G.GAME.current_round.hands_left == 2,
	"ante 1 drawn: round hands_left follows, got " .. G.GAME.current_round.hands_left
)
G.GAME.blind_on_deck = "Big"
MP.CHAOS_CLOCK.on_blind_start() -- Big blind, same ante: no new ante draw
check(G.GAME.round_resets.hands == 2, "same ante, next blind: still 2")
ante(2)
check(G.GAME.round_resets.hands == 2, "ante 2 drawn again: no double apply, got " .. G.GAME.round_resets.hands)
check(G.GAME.current_round.hands_left == 2, "ante 2 drawn again: hands_left unchanged")
ante(3)
check(G.GAME.round_resets.hands == 4, "ante 3 not drawn: restored to 4, got " .. G.GAME.round_resets.hands)
check(G.GAME.current_round.hands_left == 4, "ante 3 not drawn: hands_left restored")
check(not G.GAME.modifiers.mp_glass_cannon, "ante 3 not drawn: flag cleared")
ante(4)
check(G.GAME.round_resets.hands == 2, "ante 4 drawn: want 2, got " .. G.GAME.round_resets.hands)

-- Floor: 2 hands -> clipped to 1, off gives back exactly 1.
clock_run(2, { true, false })
ante(1)
check(G.GAME.round_resets.hands == 1, "clock floor: want 1, got " .. G.GAME.round_resets.hands)
ante(2)
check(G.GAME.round_resets.hands == 2, "clock floor off: want 2, got " .. G.GAME.round_resets.hands)

-- Ante-up after the boss (between rounds): the ante window switches for the
-- shop without touching the finished round, and the next blind doesn't roll
-- the ante again.
clock_run(4, { true, false })
ante(1)
check(G.GAME.round_resets.hands == 2, "ante 1 drawn at blind start: want 2, got " .. G.GAME.round_resets.hands)
G.GAME.current_round.hands_left = 0 -- boss beaten
G.GAME.round_resets.ante = 2
ante_rolls = 0
check(MP.CHAOS_CLOCK.on_ante_start(false), "ante-up rolls the new ante")
check(G.GAME.round_resets.hands == 4, "ante 2 not drawn: restored to 4 before the shop")
check(G.GAME.current_round.hands_left == 0, "ante-up leaves the finished round alone")
check(not G.GAME.modifiers.mp_glass_cannon, "ante 2 not drawn: flag cleared for the shop")
G.GAME.blind_on_deck = "Small"
MP.CHAOS_CLOCK.on_blind_start()
check(ante_rolls == 1, "Small blind doesn't re-roll an ante rolled at ante-up, rolls: " .. ante_rolls)

-- On for the run: the clock skips it, so it's never switched off.
MP.MODIFIERS = { "glass_cannon", "clock_normal" }
new_run(4)
forced = { false }
MP.ApplyGameModifiers()
ante(1)
check(G.GAME.round_resets.hands == 2, "On cell skipped by the clock: stays at 2")

check(MP.is_switchable("glass_cannon"), "glass_cannon is switchable")

print(("Round deltas: %d checks, %d failed"):format(checks, #failures))
for _, f in ipairs(failures) do
	print("  FAIL " .. f)
end
os.exit(#failures == 0 and 0 or 1)
