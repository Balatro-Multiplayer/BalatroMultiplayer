--- Original: Divvy's Simulation for Balatro - Init.lua
--
-- Global values that must be present for the rest of this mod to work.

if not FN then FN = {} end

FN.SIM = {
   JOKERS = {},
   
   running = {
      --- Table to store workings (ie. running totals):
      min   = {chips = 0, mult = 0, dollars = 0},
      exact = {chips = 0, mult = 0, dollars = 0},
      max   = {chips = 0, mult = 0, dollars = 0},
      reps = 0,
   },

   env = {
      --- Table to store data about the simulated play:
      jokers = {},        -- Derived from G.jokers.cards
      played_cards = {},  -- Derived from G.hand.highlighted
      scoring_cards = {}, -- Derived according to evaluate_play()
      held_cards = {},    -- Derived from G.hand minus G.hand.highlighted
      consumables = {},   -- Derived from G.consumeables.cards
      scoring_name = ""   -- Derived according to evaluate_play()
   },

   orig = {
      --- Table to store game data that gets modified during simulation:
      random_data = {}, -- G.GAME.pseudorandom
      hand_data = {}    -- G.GAME.hands
   },

   misc = {
      --- Table to store ancillary status variables:
      next_stone_id = -1
   }
}
