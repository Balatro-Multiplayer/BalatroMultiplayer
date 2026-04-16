MP.Ruleset({
	key = "sandbox",
	layers = { "sandbox" },
	multiplayer_content = true,
	banned_jokers = { "j_hanging_chad" },
	banned_silent = MP.SANDBOX.get_vanilla_bans(),
	banned_consumables = { "c_ouija", "c_ectoplasm" },
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = { "tag_rare", "tag_juggle", "tag_investment" },
	banned_blinds = {},

	-- Shuffle reworked jokers to randomize the overview panel order
	-- Only show extra_credit jokers + idol jokers + error jokers in overview (hide other sandbox jokers)
	reworked_jokers = (function()
		local jokers = {}
		local idol_jokers = {}

		-- Collect extra_credit and idol jokers separately
		for _, mapping in ipairs(MP.SANDBOX.joker_mappings) do
			if mapping.active then
				if mapping.group == "extra_credit" then
					table.insert(jokers, mapping.sandbox)
				elseif mapping.sandbox:find("idol") then
					table.insert(idol_jokers, mapping.sandbox)
				end
			end
		end

		-- Add error jokers (for overview only, not in actual pool)
		for i = 1, 14 do
			table.insert(jokers, "j_mp_error_sandbox_" .. i)
		end

		-- final vanilla stuff
		table.insert(jokers, "j_mp_hanging_chad")

		-- Fisher-Yates shuffle
		for i = #jokers, 2, -1 do
			local j = math.random(1, i)
			jokers[i], jokers[j] = jokers[j], jokers[i]
		end

		-- Insert idol jokers in the middle
		local middle = math.floor(#jokers / 2) + 1
		for i, idol in ipairs(idol_jokers) do
			table.insert(jokers, middle + i - 1, idol)
		end

		return jokers
	end)(),
	reworked_consumables = { "c_mp_ouija_standard", "c_mp_ectoplasm_sandbox" },
	reworked_vouchers = {},
	reworked_enhancements = { "m_mp_sandbox_display_glass" },
	reworked_blinds = {},
	reworked_tags = { "tag_mp_gambling_sandbox", "tag_mp_juggle_sandbox", "tag_mp_investment_sandbox" },

	forced_lobby_options = true,

	force_lobby_options = function(self)
		MP.LOBBY.config.preview_disabled = true
		MP.LOBBY.config.the_order = true
		MP.LOBBY.config.starting_lives = 4
		return true
	end,
}):inject()
