-- Shared plant/disguise/reveal plumbing for Trap consumables (objects/consumables/traps.lua).
-- A Trap card is drafted by one player but belongs, face-down, in their Nemesis's own
-- G.consumeables until its trigger condition fires -- these are the pieces every one of the
-- 16 cards' use/calculate/receive triple reuses, so each card stays a small, uniform amount
-- of code. See the plan at the time of writing for the full design rationale.
MP.TRAP = MP.TRAP or {}

local function self_id()
	local lobby = MPAPI.get_current_lobby()
	return lobby and lobby.player_id
end
MP.TRAP.self_id = self_id

-- Fires from a Trap card's own use() -- the ONLY moment use() ever runs, since a Trap can only
-- be obtained by drafting it from a Trap pack (Card:use_consumeable removes the card from
-- G.pack_cards and never adds it anywhere else). Sent directly to whoever the drafter's
-- current target resolves to right now -- NOT the per-object sync bus, since there is no
-- existing card instance on the receiving side yet for `receive` to key off of.
function MP.TRAP.plant(card)
	local lobby = MPAPI.get_current_lobby()
	local target = MP.current_target_id()
	if not (lobby and target) then
		return
	end
	card.ability.mp_trap_owner_id = self_id() -- stamp before serializing; round-trips via card:save()/:load()
	lobby:action(MP.TRAP.plant_action):send(target, { card = MPAPI.serialize_card(card), owner = self_id() })
end

-- Face-down and unsellable, so a planted trap always eventually fires -- it can't be
-- discarded away by the holder. Consumables normally CAN be sold in this game (G.consumeables'
-- CardArea uses the same config.type='joker' selling gate jokers do -- see the can_sell_card
-- wrap below), so this needs an explicit block, not just a worthless sell_cost.
function MP.TRAP.disguise(card)
	card.facing = "back"
	card.ability.mp_trap_hidden = true
end

local can_sell_card_ref = Card.can_sell_card
function Card:can_sell_card(context)
	if self.ability and self.ability.mp_trap_hidden then
		return false
	end
	return can_sell_card_ref(self, context)
end

-- Runs on the HOLDER's client (wherever the card physically, disguised, sits): flip face-up
-- with a reveal animation, then remove the spent card. The effect notification to the
-- original owner happens via the card's own calculate return (MP.TRAP.notify_owner), not here.
function MP.TRAP.reveal_and_consume(card)
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.1,
		blockable = false,
		func = function()
			card.facing = "front"
			card:flip()
			card:juice_up(0.8, 0.5)
			play_sound("tarot2")
			return true
		end,
	}))
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.9,
		blockable = false,
		func = function()
			G.consumeables:remove_card(card)
			card:remove()
			return true
		end,
	}))
end

-- Every trap's calculate replies with this exact shape. `send` is the only thing that goes out
-- on the wire (see BalatroMultiplayerAPI's synced_mixin.calculate). The owner id is carried
-- explicitly -- NOT resolved via MP.current_target_id() at fire time, since a trap's rightful
-- owner was fixed at draft time and the drafter's live nemesis pairing may have since rotated
-- to someone else. Every trap's receive must gate on `context.data.owner == MP.TRAP.self_id()`.
function MP.TRAP.notify_owner(card, data)
	data = data or {}
	data.owner = card.ability.mp_trap_owner_id
	return { send = data }
end

-- The "use" animation played on the ORIGINAL OWNER's own screen when their planted trap
-- fires remotely -- they never see the opponent's reveal directly, just this local flourish.
function MP.UI.show_trap_fired_animation(name)
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.1,
		blockable = false,
		func = function()
			attention_text({
				text = name .. " Triggered!",
				scale = 0.8,
				colour = MP.COLOURS.DARK_PINK,
				pos = { x = G.consumeables.T.x + G.consumeables.T.w / 2, y = G.consumeables.T.y },
				align = "cm",
				hold = 1.2,
			})
			play_sound("tarot2")
			return true
		end,
	}))
end

MP.TRAP.plant_action = MPAPI.ActionType({
	key = "mp_trap_plant",
	parameters = {
		{ key = "card", type = "string", required = true },
		{ key = "owner", type = "string", required = true },
	},
	on_receive = function(_at, from, params)
		local card = MPAPI.rebuild_card(params.card, G.consumeables)
		if not card then
			return
		end
		card.ability.mp_trap_owner_id = params.owner
		MP.TRAP.disguise(card)
	end,
})
