local function get_warnings()
	local warnings = {}

	-- Check the other player (guest if we're host, host if we're guest)
	local other_player = MP.LOBBY.is_host and MP.LOBBY.guest or MP.LOBBY.host

	if other_player and other_player.cached == false then
		table.insert(warnings, { localize("k_warning_cheating1"), SMODS.Gradients.warning_text, 0.4 })
		table.insert(
			warnings,
			{ string.format(localize("k_warning_cheating2"), MP.UTILS.random_message()), SMODS.Gradients.warning_text }
		)
	end

	if other_player and other_player.config and other_player.config.unlocked == false then
		table.insert(warnings, {
			localize("k_warning_nemesis_unlock"),
			SMODS.Gradients.warning_text,
			0.25,
		})
	end

	local current_player = MP.LOBBY.is_host and MP.LOBBY.host or MP.LOBBY.guest
	local current_has_order = current_player and current_player.config and current_player.config.TheOrder
	local other_has_order = other_player and other_player.config and other_player.config.TheOrder

	if (MP.LOBBY.ready_to_start or not MP.LOBBY.is_host) and current_has_order ~= other_has_order then
		table.insert(warnings, {
			localize("k_warning_no_order"),
			SMODS.Gradients.warning_text,
		})
	end

	if MP.LOBBY.ready_to_start or not MP.LOBBY.is_host then
		local hostSteamoddedVersion = MP.LOBBY.host and MP.LOBBY.host.config and MP.LOBBY.host.config.Mods["Steamodded"]
		local guestSteamoddedVersion = MP.LOBBY.guest
			and MP.LOBBY.guest.config
			and MP.LOBBY.guest.config.Mods["Steamodded"]

		if hostSteamoddedVersion ~= guestSteamoddedVersion then
			table.insert(warnings, {
				localize("k_steamodded_warning"),
				SMODS.Gradients.warning_text,
			})
		end
	end

	SMODS.Mods["Multiplayer"].config.unlocked = MP.UTILS.unlock_check()
	if not SMODS.Mods["Multiplayer"].config.unlocked then
		table.insert(warnings, {
			localize("k_warning_unlock_profile"),
			SMODS.Gradients.warning_text,
			0.25,
		})
	end

	-- ???: What is this supposed to accomplish?
	if MP.LOBBY.username == "Guest" then
		table.insert(warnings, {
			localize("k_set_name"),
			G.C.UI.TEXT_LIGHT,
		})
	end

	if #warnings == 0 then
		table.insert(warnings, {
			" ",
			G.C.UI.TEXT_LIGHT,
		})
	end

	return warnings
end

function MP.UI.lobby_status_display()
	local warnings = get_warnings()

	local warning_texts = {}
	for k, v in pairs(warnings) do
		table.insert(warning_texts, {
			n = G.UIT.R,
			config = {
				padding = -0.25,
				align = "cm",
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = v[1],
						colour = v[2],
						shadow = true,
						scale = v[3] or 0.25,
					},
				},
			},
		})
	end

	return {
		n = G.UIT.R,
		config = {
			padding = 0.35,
			align = "cm",
		},
		nodes = warning_texts,
	}
end
