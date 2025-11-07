MP.SANDBOX = {}

MP.Ruleset({
	key = "sandbox",
	multiplayer_content = true,
	banned_jokers = {},
	banned_silent = {
		"j_hanging_chad",
		"j_ride_the_bus",
		"j_baseball",
		"j_bloodstone",
		"j_castle",
		"j_cloud_9",
		"j_constellation",
		"j_faceless",
		"j_hit_the_road",
		"j_juggler",
		"j_loyalty_card",
		"j_lucky_cat",
		"j_mail",
		"j_misprint",
		"j_order",
		"j_photograph",
		"j_runner",
		"j_satellite",
		"j_square",
		"j_steel_joker",
		"j_throwback",
		"j_vampire",
		"j_mp_idol",
	},
	banned_consumables = { "c_ouija", "c_ectoplasm" },
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = { "tag_rare", "tag_juggle", "tag_investment" },
	banned_blinds = {},

	-- Shuffle reworked jokers to randomize the overview panel order
	reworked_jokers = (function()
		local jokers = {
			"j_mp_hanging_chad",
			"j_mp_misprint_sandbox",
			"j_mp_castle_sandbox",
			"j_mp_mail_sandbox",
			"j_mp_square_sandbox",
			"j_mp_throwback_sandbox",
			"j_mp_vampire_sandbox",
			"j_mp_steel_joker_sandbox",
			"j_mp_baseball_sandbox",
			"j_mp_idol_sandbox_bw",
			"j_mp_idol_sandbox_color",
			"j_mp_idol_sandbox_fantom",
		}

		-- Add error jokers
		for i = 1, 14 do
			table.insert(jokers, "j_mp_error_sandbox_" .. i)
		end

		-- Fisher-Yates shuffle
		for i = #jokers, 2, -1 do
			local j = math.random(1, i)
			jokers[i], jokers[j] = jokers[j], jokers[i]
		end

		return jokers
	end)(),
	reworked_consumables = { "c_mp_ouija_sandbox", "c_mp_ectoplasm_sandbox" },
	reworked_vouchers = {},
	reworked_enhancements = {},
	reworked_blinds = {},
	reworked_tags = { "tag_mp_gambling_sandbox", "tag_mp_juggle_sandbox", "tag_mp_investment_sandbox" },

	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = true,
			description_key = "k_sandbox_description",
		})
	end,

	forced_lobby_options = true,

	force_lobby_options = function(self)
		MP.LOBBY.config.preview_disabled = true
		MP.LOBBY.config.the_order = false
		MP.LOBBY.config.starting_lives = 4
		return true
	end,
}):inject()

local apply_bans_ref = MP.ApplyBans
function MP.ApplyBans()
	local ret = apply_bans_ref()
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" then
		local idol_keys = { "j_mp_idol_sandbox_bw", "j_mp_idol_sandbox_color", "j_mp_idol_sandbox_fantom" }

		table.sort(idol_keys)
		pseudoshuffle(idol_keys, pseudoseed("idol_selection_mp_sandbox"))

		for i = 2, #idol_keys do
			G.GAME.banned_keys[idol_keys[i]] = true
		end
	end
	print(MP.UTILS.serialize_table(G.GAME.banned_keys))
	return ret
end

-- debugging hotswitch
MP.sandbox_no_collection = false
