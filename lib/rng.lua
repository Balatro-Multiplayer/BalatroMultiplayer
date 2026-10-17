-- Stateless rolls keyed by run seed and caller-supplied coordinates.
-- Unlike pseudoseed(string), this does not advance a per-key counter: repeated
-- coordinates give the same result regardless of call order or skipped blinds.
--
-- Use a feature name plus its event coordinates to separate independent rolls:
--   MP.rng.game():chance(0.2, "chaos_clock", ante, blind_slot)
-- Use MP.rng.stream(seed) when no run exists (menus or tests).
-- Key parts are joined with "|"; callers must avoid ambiguous combinations
-- such as ("a|b", "c") and ("a", "b|c").
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
