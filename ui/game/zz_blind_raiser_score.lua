-- Loaded last in ui/game so the Blind Raiser score override is applied after
-- Multiplayer's other Blind:set_blind wrappers have finished.
if Blind and type(Blind.set_blind) == "function" then
	local blind_set_blind_ref = Blind.set_blind
	function Blind:set_blind(blind, reset, silent)
		local ret = blind_set_blind_ref(self, blind, reset, silent)
		if MP.BLIND_RAISER and MP.BLIND_RAISER.score_for_blind then
			local score_ante = G.GAME.round_resets.blind_ante or G.GAME.round_resets.ante
			self.chips = MP.BLIND_RAISER.score_for_blind(
				blind or (self.config and self.config.blind),
				G.GAME.blind_on_deck,
				self.chips,
				score_ante
			)
			self.chip_text = number_format(self.chips)
		end
		return ret
	end
end
