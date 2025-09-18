-- Ectoplasm
-- TODO impl change:
-- Change from (-1, -2, ... hand size)
-- to random
-- -1 hand size, -1 hand, -1 discard
-- (yes you can die...?)
SMODS.Consumable({
	key = "ectoplasm_sandbox",
	set = "Spectral",
	pos = { x = 8, y = 4 },
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
		return { vars = { G.GAME.ecto_minus or 1 }, mp_sticker_balanced = true }
	end,
	in_pool = function(self)
		return MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_sandbox"
	end,
	use = function(self, card, area, copier)
		local editionless_jokers = SMODS.Edition:get_edition_cards(G.jokers, true)
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.4,
			func = function()
				-- Randomly pick one of three negative effects
				local effect = pseudorandom("ectoplasm_sandbox", 1, 3)

				if effect == 1 then
					-- Apply hand change
					G.GAME.round_resets.hands = G.GAME.round_resets.hands - 1
					ease_hands_played(-1)
				elseif effect == 2 then
					-- Apply discard change
					G.GAME.round_resets.discards = G.GAME.round_resets.discards - 1
					ease_discard(-1)
				else
					-- Apply hand size change
					G.hand:change_size(-1)
				end

				-- TODO another effect (maybe the main one?): make a random joker perishable

				-- positive effect: negative joker
				if #editionless_jokers then
					local eligible_card = pseudorandom_element(editionless_jokers, "ectoplasm")
					eligible_card:set_edition({ negative = true })
				end

				card:juice_up(0.3, 0.5)
				return true
			end,
		}))
	end,
	can_use = function(self, card)
		return true
		-- return G.GAME.round_resets.hands >= 1 and G.GAME.round_resets.discards >= 0
		-- return next(SMODS.Edition:get_edition_cards(G.jokers, true))
	end,
	-- draw = function(self, card, layer)
	-- 	-- This is for the Spectral shader. You don't need this with `set = "Spectral"`
	-- 	-- Also look into SMODS.DrawStep if you make multiple cards that need the same shader
	-- 	if (layer == "card" or layer == "both") and card.sprite_facing == "front" then
	-- 		card.children.center:draw_shader("booster", nil, card.ARGS.send_to_shader)
	-- 	end
	-- end,
})
