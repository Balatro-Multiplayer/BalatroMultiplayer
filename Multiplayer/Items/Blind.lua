SMODS.Atlas({
	key = "mp_player_blind_chip",
	path = "player_blind_row.png",
	atlas_table = "ANIMATION_ATLAS",
	frames = 21,
	px = 34,
	py = 34,
	prefix_config = { key = false },
})

SMODS.Blind({
	key = "bl_pvp",
	dollars = 5,
	mult = 1, -- Jen's Almanac crashes the game if the mult is 0
	boss = { min = 1, max = 10 },
	boss_colour = HEX("ac3232"),
	atlas = "mp_player_blind_chip",
	discovered = true,
	in_pool = function(self)
		return false
	end,
	prefix_config = { key = false, atlas = false },
})

--local create_UIBox_your_collection_blinds_ref = create_UIBox_your_collection_blinds
--function create_UIBox_your_collection_blinds(exit)
--	G.P_BLINDS["bl_pvp"] = nil
--	local res = create_UIBox_your_collection_blinds_ref(exit)
--	G.P_BLINDS["bl_pvp"] = bl_pvp
--	return res
--end
--
--local set_discover_tallies_ref = set_discover_tallies
--function set_discover_tallies()
--	G.P_BLINDS["bl_pvp"] = nil
--	local res = set_discover_tallies_ref()
--	G.P_BLINDS["bl_pvp"] = bl_pvp
--	return res
--end

function is_pvp_boss()
	if not G.GAME or not G.GAME.blind then
		return false
	end
	return G.GAME.blind.config.blind.key == "bl_pvp"
end
