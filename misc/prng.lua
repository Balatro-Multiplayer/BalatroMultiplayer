-- Bloodstone PRNG Implementation Testing
-- Uses persistent bias that gets easier after misses

-- Bloodstone PRNG state - persistent across calls
local BloodstonePRNG = {}
BloodstonePRNG.__index = BloodstonePRNG

-- Create new Bloodstone PRNG instance
function BloodstonePRNG:new(actual_odds)
	local instance = {}
	setmetatable(instance, BloodstonePRNG)

	instance.actual_odds = actual_odds
	instance.starting_bias = 0.2 -- Starting bias (20%)
	instance.current_bias = instance.starting_bias
	instance.step = -0.25 -- How much easier (30%) for each successive roll
	instance.seed_counter = 0 -- For pseudorandom seed variation

	return instance
end

-- Simple pseudorandom implementation (mimics game's pseudorandom)
function BloodstonePRNG:pseudorandom()
	self.seed_counter = self.seed_counter + 1
	-- Simple LCG for consistent results
	local a, c, m = 1664525, 1013904223, 2 ^ 32
	local seed = (a * (1000 + self.seed_counter) + c) % m
	return seed / m
end

-- Roll for success using Bloodstone logic
function BloodstonePRNG:roll()
	if self.actual_odds >= 1 then
		return true
	end

	local roll = self:pseudorandom() + self.current_bias

	if roll < self.actual_odds then
		-- Success - reset bias
		self.current_bias = self.starting_bias
		return true
	else
		-- Failure - make it easier next time
		self.current_bias = self.current_bias + self.step
		return false
	end
end

-- Get current bias (for debugging)
function BloodstonePRNG:getCurrentBias()
	return self.current_bias
end

-- Reset the bias
function BloodstonePRNG:reset()
	self.current_bias = self.starting_bias
	self.seed_counter = 0
end

-- Simulate many rolls to verify the system works
function BloodstonePRNG:simulate(trials)
	local successes = 0
	local original_bias = self.current_bias
	local original_counter = self.seed_counter

	for i = 1, trials do
		if self:roll() then
			successes = successes + 1
		end
	end

	-- Reset to original state
	self.current_bias = original_bias
	self.seed_counter = original_counter

	return successes / trials
end

-- Example usage and testing
print("=== Bloodstone PRNG Testing ===")
print()

-- Test Bloodstone with 50% odds (like 1/2 chance)
local bloodstone = BloodstonePRNG:new(0.5)

print("Bloodstone Configuration:")
print("Actual Odds: 50%")
print("Starting Bias: " .. string.format("%.1f%%", bloodstone.starting_bias * 100))
print("Step per Failure: " .. string.format("%.1f%%", math.abs(bloodstone.step) * 100) .. " easier")
print()

-- Demonstrate individual rolls
print("Individual Roll Progression:")
for i = 1, 10 do
	local currentBias = bloodstone:getCurrentBias()
	local success = bloodstone:roll()
	print(string.format("Roll %d: Bias %.1f%% -> %s", i, currentBias * 100, success and "SUCCESS" or "FAIL"))
end

print()

-- Reset and test simulation
bloodstone:reset()
print("Large-scale simulation:")
local trials = 100000
local actualRate = bloodstone:simulate(trials)
print(string.format("Trials: %d", trials))
print(string.format("Success Rate: %.2f%%", actualRate * 100))
print(string.format("Difference from 50%%: %.2f%%", (actualRate - 0.5) * 100))

print()

-- Test with Bloodstone's actual odds (G.GAME.probabilities.normal / 2)
print("=== Bloodstone Joker Simulation ===")
local bloodstone_joker = BloodstonePRNG:new(1 / 2) -- Normal: 1, Odds: 2, so 1/2 = 50%

print("Bloodstone Joker (1 in 2 chance):")
print("Expected Success Rate: 50%")

bloodstone_joker:reset()
local joker_rate = bloodstone_joker:simulate(trials)
print(string.format("Actual Success Rate: %.2f%%", joker_rate * 100))

print()

-- Compare variance with uniform random
print("=== Variance Comparison ===")

-- Bloodstone variance test
bloodstone:reset()
local bloodstoneResults = {}
local hands = 5
local simulations = 10000

for sim = 1, simulations do
	local successes = 0
	for hand = 1, hands do
		if bloodstone:roll() then
			successes = successes + 1
		end
	end
	table.insert(bloodstoneResults, successes)
	bloodstone:reset()
end

-- Calculate Bloodstone statistics
local bloodstoneSum = 0
for i = 1, #bloodstoneResults do
	bloodstoneSum = bloodstoneSum + bloodstoneResults[i]
end
local bloodstoneMean = bloodstoneSum / #bloodstoneResults

local bloodstoneVariance = 0
for i = 1, #bloodstoneResults do
	bloodstoneVariance = bloodstoneVariance + (bloodstoneResults[i] - bloodstoneMean) ^ 2
end
bloodstoneVariance = bloodstoneVariance / #bloodstoneResults

-- Uniform random (binomial) statistics for comparison
local uniformMean = hands * 0.5
local uniformVariance = hands * 0.5 * 0.5

print("Results for " .. hands .. " hands:")
print(string.format("Bloodstone Mean: %.3f, Variance: %.3f", bloodstoneMean, bloodstoneVariance))
print(string.format("Uniform Mean: %.3f, Variance: %.3f", uniformMean, uniformVariance))
print(string.format("Variance Reduction: %.1f%%", (1 - bloodstoneVariance / uniformVariance) * 100))
