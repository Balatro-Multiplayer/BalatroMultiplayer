if MP.EXPERIMENTAL.alt_stakes then
	SMODS.Stake({
		mp_alt_stake = true,
		name = "Plastic Stake",
		key = "plastic",
		unlocked = true,
		applied_stakes = { "white" },
		prefix_config = { applied_stakes = { mod = false } },
		atlas = "alt_mp_stakes",
		pos = { x = 1, y = 0 },
		sticker_pos = { x = 3, y = 1 }, -- no sticker ig
		modifiers = function()
			G.GAME.modifiers.mp_modified_interest_rate = 10
		end,
		colour = HEX("FF9696"),
		-- shiny = true,
	})

	local evaluate_round_ref = G.FUNCS.evaluate_round
	G.FUNCS.evaluate_round = function()
		if G.GAME.modifiers.mp_modified_interest_rate then
			-- ok we're doing something really stupid to avoid jank
			-- basically our target is in the middle of the function and it's difficult to find a patchable line that keeps any possible mod compat
			-- so i'm faking no interest but having a separate variable that lets us know if we're faking no interest so we can actually run our own interest behaviour
			-- this ALSO breaks if another mod is doing the exact same thing but holy shit i do not care there's no way a mod is doing the exact same thing
			-- ...behaviour override is kinda cringe but it's better than a bunch of obsessive and fragile at patches
			G.GAME.modifiers.TRUE_no_interest = G.GAME.modifiers.no_interest
			G.GAME.modifiers.no_interest = true
			local ret = evaluate_round_ref()
			G.GAME.modifiers.no_interest = G.GAME.modifiers.TRUE_no_interest
			return ret
		end
		return evaluate_round_ref()
	end

	-- change ttm behaviour
	-- annoying
	-- yes i know this is a buff
	SMODS.Joker:take_ownership("to_the_moon", {
		loc_vars = function(self, info_queue, card)
			return {
				vars = { card.ability.extra, G.GAME.modifiers and G.GAME.modifiers.mp_modified_interest_rate or 5 },
				key = self.key .. "_mp",
			}
		end,
	}, true)

	local set_ability_ref = Card.set_ability
	function Card:set_ability(center, initial, delay_sprites)
		set_ability_ref(self, center, initial, delay_sprites)
		if center == G.P_CENTERS.j_to_the_moon then
			if G.GAME.modifiers.mp_modified_interest_rate then
				self.ability.extra = self.ability.extra / (5 / G.GAME.modifiers.mp_modified_interest_rate)
			end
		end
	end

	-- technically incorrect but for consistency purposes
	SMODS.Voucher:take_ownership("seed_money", {
		loc_vars = function(self, info_queue, card)
			return {
				vars = {
					card.ability.extra / (5 / (G.GAME.modifiers and G.GAME.modifiers.mp_modified_interest_rate or 5)),
				},
			}
		end,
	}, true)

	SMODS.Voucher:take_ownership("money_tree", {
		loc_vars = function(self, info_queue, card)
			return {
				vars = {
					card.ability.extra / (5 / (G.GAME.modifiers and G.GAME.modifiers.mp_modified_interest_rate or 5)),
				},
			}
		end,
	}, true)
end
