MP.SANDBOX = {}

-- Centralized allowlist for sandbox jokers (actual pool)
MP.SANDBOX.allowed_jokers = {
	"j_mp_hanging_chad",
	"j_mp_misprint_sandbox",
	"j_mp_castle_sandbox",
	"j_mp_mail_sandbox",
	"j_mp_square_sandbox",
	"j_mp_throwback_sandbox",
	"j_mp_vampire_sandbox",
	"j_mp_steel_joker_sandbox",
	"j_mp_baseball_sandbox",
	"j_mp_hit_the_road_sandbox",
	"j_mp_idol_sandbox_bw",
	"j_mp_idol_sandbox_color",
	"j_mp_idol_sandbox_fantom",
	-- Out of rotation
	-- "j_mp_bloodstone_sandbox",
	-- "j_mp_cloud_9_sandbox",
	-- "j_mp_constellation_sandbox",
	-- "j_mp_faceless_sandbox",
	-- "j_mp_hit_the_road_sandbox",
	-- "j_mp_juggler_sandbox",
	-- "j_mp_loyalty_card_sandbox",
	-- "j_mp_lucky_cat_sandbox",
	-- "j_mp_magnet_sandbox",
	-- "j_mp_order_sandbox",
	-- "j_mp_photograph_sandbox",
	-- "j_mp_ride_the_bus_sandbox",
	-- "j_mp_runner_sandbox",
	-- "j_mp_satellite_sandbox",
}

--- Centralized allowlist check for sandbox jokers
--- @param joker_key string The key of the joker to check (e.g., "j_mp_mail_sandbox")
--- @return boolean true if the joker is allowed in the sandbox ruleset and in a multiplayer lobby
function MP.SANDBOX.is_joker_allowed(joker_key)
	if not MP.LOBBY.code then return false end
	if MP.LOBBY.config.ruleset ~= "ruleset_mp_sandbox" then return false end

	for _, allowed_key in ipairs(MP.SANDBOX.allowed_jokers) do
		if allowed_key == joker_key then return true end
	end

	return false
end

MP.Ruleset({
	key = "sandbox",
	multiplayer_content = true,
	banned_jokers = {},
	banned_silent = {
		"j_hanging_chad",
		"j_misprint",
		"j_castle",
		"j_mail",
		"j_square",
		"j_throwback",
		"j_hit_the_road",
		"j_vampire",
		"j_steel_joker",
		"j_baseball",
		"j_idol",
	},
	banned_consumables = { "c_ouija", "c_ectoplasm" },
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = { "tag_rare", "tag_juggle", "tag_investment" },
	banned_blinds = {},

	-- Shuffle reworked jokers to randomize the overview panel order
	reworked_jokers = (function()
		-- Copy the allowlist
		local jokers = {}
		for _, key in ipairs(MP.SANDBOX.allowed_jokers) do
			table.insert(jokers, key)
		end

		-- Add error jokers (for overview only, not in actual pool)
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

--- Randomly selects one idol variant to be available in the sandbox ruleset
--- Bans the other two idol variants to ensure only one is available per game
--- Uses pseudorandom selection based on the lobby seed for consistency across players
--- @return nil
local function select_random_idol()
	local idol_keys = { "j_mp_idol_sandbox_bw", "j_mp_idol_sandbox_color", "j_mp_idol_sandbox_fantom" }
	table.sort(idol_keys)

	-- Pseudorandom shuffle using the lobby seed so all players get the same idol
	pseudoshuffle(idol_keys, pseudoseed("idol_selection_mp_sandbox"))

	-- Ban all idols except the first one (which is now randomly selected)
	for i = 2, #idol_keys do
		G.GAME.banned_keys[idol_keys[i]] = true
	end
end

local apply_bans_ref = MP.ApplyBans
function MP.ApplyBans()
	local ret = apply_bans_ref()

	-- Apply sandbox-specific idol selection when in sandbox ruleset
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" then select_random_idol() end

	return ret
end

-- debugging hotswitch
MP.sandbox_no_collection = false
