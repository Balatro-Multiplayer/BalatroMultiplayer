--[[
  Pure-logic tests for lib/trap_utils.lua's card-manipulation helpers that don't need
  the live game engine (MP.TRAP.decrease_rank's rank-suffix arithmetic, MP.TRAP.notify_owner's
  payload shape). The plant/disguise/reveal/dispatch flow itself needs a running Balatro +
  Integration (BInt) instance to test meaningfully -- see CLAUDE.md's `bint run` workflow --
  and is out of scope for this static harness.

  Run from the repo root: luajit tests/test_trap_utils.lua
]]

local failures = 0
local function assert_eq(actual, expected, label)
	if actual ~= expected then
		failures = failures + 1
		print(string.format("FAIL %s: expected %s, got %s", label, tostring(expected), tostring(actual)))
	else
		print(string.format("ok   %s", label))
	end
end

-- ─── Minimal stubs ──────────────────────────────────────────────────────────
MP = { UI = {} }
MPAPI = {
	get_current_lobby = function() return nil end,
	ActionType = function(t) return t end,
	rebuild_card = function() return nil end,
	serialize_card = function() return "" end,
}
Card = { can_sell_card = function(self, context) return true end }
G = { P_CARDS = {} }
setmetatable(G.P_CARDS, {
	__index = function(_, key) return { key = key } end, -- identity: any suit_rank string round-trips
})

local function fake_card(suit, id)
	local self_set_base
	local card = { base = { suit = suit, id = id } }
	function card:set_base(new_base)
		self_set_base = new_base
	end
	function card:_set_base_result()
		return self_set_base
	end
	return card
end

dofile("lib/trap_utils.lua")

-- ─── MP.TRAP.decrease_rank ──────────────────────────────────────────────────
-- suit_prefix is the first letter of the (capitalised) suit name, rank_suffix maps
-- 10/J/Q/K/A, floored at 2 -- mirrors Strength's own rank+1 pattern in card.lua, inverted.
local c = fake_card("Spades", 9)
MP.TRAP.decrease_rank(c)
assert_eq(c:_set_base_result().key, "S_8", "decrease_rank 9 -> 8")

local ace = fake_card("Hearts", 14)
MP.TRAP.decrease_rank(ace)
assert_eq(ace:_set_base_result().key, "H_K", "decrease_rank Ace -> King")

local ten = fake_card("Clubs", 10)
MP.TRAP.decrease_rank(ten)
assert_eq(ten:_set_base_result().key, "C_9", "decrease_rank 10 -> 9")

local jack = fake_card("Diamonds", 11)
MP.TRAP.decrease_rank(jack)
assert_eq(jack:_set_base_result().key, "D_T", "decrease_rank Jack -> Ten")

local floor_card = fake_card("Spades", 2)
MP.TRAP.decrease_rank(floor_card)
assert_eq(floor_card:_set_base_result().key, "S_2", "decrease_rank floors at 2")

-- ─── MP.TRAP.notify_owner ───────────────────────────────────────────────────
local owner_card = { ability = { mp_trap_owner_id = "player-42" } }
local result = MP.TRAP.notify_owner(owner_card, { rerolls = 2 })
assert_eq(result.send.owner, "player-42", "notify_owner attaches owner id")
assert_eq(result.send.rerolls, 2, "notify_owner preserves caller data")

local result_no_data = MP.TRAP.notify_owner(owner_card)
assert_eq(result_no_data.send.owner, "player-42", "notify_owner handles nil data")

if failures > 0 then
	print(string.format("\n%d failure(s)", failures))
	os.exit(1)
else
	print("\nall tests passed")
end
