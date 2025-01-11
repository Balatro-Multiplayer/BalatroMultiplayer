if SMODS.Mods["Cryptid"] and SMODS.Mods["Cryptid"].can_load then
	sendDebugMessage("Cryptid compatibility detected", "MULTIPLAYER")
	G.MULTIPLAYER.DECK.ban_card("j_cry_fleshpanopticon")
	G.MULTIPLAYER.DECK.ban_card("j_cry_candy_sticks")
	G.MULTIPLAYER.DECK.ban_card("j_cry_redeo")
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
end
