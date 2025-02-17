if SMODS.Mods["Cryptid"] and SMODS.Mods["Cryptid"].can_load then
	sendDebugMessage("Cryptid compatibility detected", "MULTIPLAYER")
	G.MULTIPLAYER.DECK.ban_card("j_cry_fleshpanopticon")
	G.MULTIPLAYER.DECK.ban_card("j_cry_candy_sticks")
	G.MULTIPLAYER.DECK.ban_card("j_cry_redeo")
	G.MULTIPLAYER.DECK.ban_card("j_cry_chocolate_dice")
	G.MULTIPLAYER.DECK.ban_card("v_cry_asteroglyph")
	G.MULTIPLAYER.DECK.ban_card("c_cry_semicolon")
	G.MULTIPLAYER.DECK.ban_card("c_cry_crash")
	G.MULTIPLAYER.DECK.ban_card("c_cry_revert")
	G.MULTIPLAYER.DECK.ban_card("c_cry_analog")

	local defeat_ref = Blind.defeat
	function Blind:defeat(silent)
		if self.config.blind.key == nil then
			self.config.blind.key = "bl_nil"
		end
		defeat_ref(self, silent)
	end

	local save_run_ref = save_run
	function save_run()
		if G.F_NO_SAVING then
			return
		end
		save_run_ref()
	end

	function wheel_of_fortune_the_title_card()
		return true
	end

	local get_random_consumable_ref = get_random_consumable
	function get_random_consumable(seed, excluded_flags, banned_card, pool, no_undiscovered)
		if not G.LOBBY.code then
			return get_random_consumable_ref(seed, excluded_flags, banned_card, pool, no_undiscovered)
		end
		local tries = 5
		local card = nil
		repeat
			card = get_random_consumable_ref(seed, excluded_flags, banned_card, pool, no_undiscovered)
			local is_banned = false

			for _, banned in ipairs(G.MULTIPLAYER.DECK.BANNED_CARDS) do
				if card.key == banned.id then
					sendWarnMessage("Attempted to create banned card: " .. card.key .. ", trying again", "MULTIPLAYER")
					tries = tries - 1
					is_banned = true
					if tries <= 0 then
						sendWarnMessage("Attempted to create banned cards too many times, giving up.", "MULTIPLAYER")
						return card
					end
					break
				end
			end
		until not is_banned
		return card
	end

	G.MULTIPLAYER.set_max_stake("stake_cry_emerald")
end
