if SMODS.Mods["HotPotato"] and SMODS.Mods["HotPotato"].can_load then
	sendDebugMessage("HotPotato compatibility detected", "MULTIPLAYER")
	MP.DECK.ban_card("j_hpot_antidsestablishmentarianism") -- sic
	MP.DECK.ban_card("j_hpot_brainfuck")
	MP.DECK.ban_card("j_hpot_goldenchicot")
	MP.DECK.ban_card("j_hpot_lockin")
	MP.DECK.ban_card("j_hpot_lotus")
	MP.DECK.ban_card("j_hpot_c_sharp")

	local generate_special_deals_ref = hotpot_jtem_generate_special_deals
	function hotpot_jtem_generate_special_deals(deals) -- this queue is so jank, barely fixes it
		local a = G.GAME.round_resets.ante
		if MP.should_use_the_order() then
			G.GAME.round_resets.ante = 0
		end
		local ret = generate_special_deals_ref(deals)
		G.GAME.round_resets.ante = a
		return ret
	end
end
