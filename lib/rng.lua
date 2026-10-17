-- Stateless, keyed randomness for mod features that both clients must agree on.
--
-- Vanilla's pseudoseed(key) advances a per-key counter in G.GAME.pseudorandom, so
-- the Nth call depends on how many calls came before it. That's fine for shop
-- queues, but a feature like "roll once per (ante, blind, hand)" wants the same
-- answer for the same coordinates no matter what else either player did first.
--
-- A stream hashes (seed | part1 | part2 ...) into a number and feeds it to
-- vanilla pseudorandom(number), which is how vanilla turns a hash into a roll.
-- Nothing is stored, so the order of calls can't drift between clients.
--
--   local r = MP.rng.game()                    -- seeded from the run seed
--   if r:chance(0.2, "chaos_clock", ante, hand) then ... end
--   local suit = r:element(SUITS, "suit_storm", ante, hand)
--
--   local r = MP.rng.stream("lobby-ABCDE")     -- explicit seed (menus, tests)

MP.rng = MP.rng or {}

local Stream = {}
Stream.__index = Stream

local function key_of(seed, ...)
	local parts = { tostring(seed) }
	for i = 1, select("#", ...) do
		local part = select(i, ...)
		-- tostring(table) is an address, different on each client.
		assert(type(part) ~= "table", "MP.rng key parts must be strings or numbers")
		parts[#parts + 1] = tostring(part)
	end
	return table.concat(parts, "|")
end

-- [0, 1)
function Stream:roll(...)
	return pseudorandom(pseudohash(key_of(self.seed, ...)))
end

function Stream:chance(p, ...)
	return self:roll(...) < p
end

-- Integer in [lo, hi].
function Stream:int(lo, hi, ...)
	return lo + math.floor(self:roll(...) * (hi - lo + 1))
end

function Stream:element(list, ...)
	if #list == 0 then return nil end
	return list[self:int(1, #list, ...)]
end

-- n distinct entries, order decided by the roll (Fisher-Yates on a copy).
function Stream:pick(list, n, ...)
	local copy = {}
	for i, v in ipairs(list) do
		copy[i] = v
	end
	for i = #copy, 2, -1 do
		local j = self:int(1, i, "pick", i, ...)
		copy[i], copy[j] = copy[j], copy[i]
	end
	local out = {}
	for i = 1, math.min(n, #copy) do
		out[i] = copy[i]
	end
	return out
end

function MP.rng.stream(seed)
	return setmetatable({ seed = seed or "" }, Stream)
end

-- Stream on the current run seed. Both clients share it, so equal arguments give
-- equal rolls.
function MP.rng.game()
	local seed = G.GAME and G.GAME.pseudorandom and G.GAME.pseudorandom.seed
	assert(seed, "MP.rng.game() needs a run seed")
	return MP.rng.stream(seed)
end
