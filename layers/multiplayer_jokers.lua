-- The Multiplayer Jokers (Speedrun, Taxes, Pizza, ...) as a wall cell, so a
-- base without them (Vanilla) can opt in. start_lobby copies
-- current_ruleset().multiplayer_content into MP.LOBBY.config.multiplayer_jokers,
-- which every j_mp_* joker's mp_include reads; a modifier's scalar beats the
-- base ruleset's, so this layer only has to set it. The lobby options toggle
-- still has the last word.
MP.Layer("multiplayer_jokers", {
	multiplayer_content = true,
	mutator = {
		category = "JOKERS",
		order = 1,
		label = "MP Jokers",
		desc = { "Multiplayer Jokers join the pool:", "Speedrun, Conjoined, Taxes, Pizza..." },
		implied_by = function(ruleset)
			return ruleset.multiplayer_content
		end,
	},
})
