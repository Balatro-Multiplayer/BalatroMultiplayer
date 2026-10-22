-- The private lobby's group queue panel (pvp_api/group_queue.lua): the host
-- opens the casual Find Game pillars and queues the lobby as a group; while the
-- group is queueing every member sees where it is and may cancel.

local function text_row(text, scale, colour)
	return { n = G.UIT.R, config = { align = "cm", padding = 0.03 }, nodes = {
		{ n = G.UIT.T, config = { text = text, scale = scale or 0.32, colour = colour or G.C.UI.TEXT_LIGHT, shadow = true } },
	} }
end

local function mode_display(key)
	local def = PVP.PVP_GAMEMODES[key]
	return def and def.display or tostring(key)
end

-- The panel's rows. Reads only.
function PVP.lobby.group_panel_rows(lobby)
	local Group = MPAPI.matchmaking.group
	local view = lobby and lobby.group_queue
	if type(view) == "table" then
		local rows = { text_row(localize("k_group_queue"), 0.36, G.C.UI.TEXT_INACTIVE) }
		local line = Group.status_line(lobby)
		rows[#rows + 1] = text_row((line and line.text or "") .. " " .. mode_display(view.mode), 0.36, G.C.GOLD)
		if not lobby.is_host then
			rows[#rows + 1] = text_row(localize("k_group_member_queued_by_host") .. " " .. mode_display(view.mode), 0.28)
		end
		if view.phase ~= Group.Phase.AWAY then
			rows[#rows + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
				UIBox_button({ id = "mp_pvp_group_cancel", button = "mp_pvp_group_cancel", label = { localize("b_group_cancel") }, colour = G.C.RED, minw = 2.6, minh = 0.6, scale = 0.4 }),
			} }
		end
		return rows
	end

	-- One button that opens the casual Find Game pillars to pick a mode from;
	-- only the host of a lobby of two or more may press it.
	local can_open = lobby and lobby.is_host and #lobby:get_players() >= Group.MIN_SIZE
	return { { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
		UIBox_button({ id = "mp_pvp_group_queue", button = can_open and "mp_pvp_group_queue" or "nil", label = { localize("k_group_queue") }, colour = can_open and G.C.BLUE or G.C.UI.BACKGROUND_INACTIVE, minw = 3, minh = 0.8, scale = 0.45 }),
	} } }
end

function PVP.lobby.build_group_panel()
	if not (MPAPI.matchmaking and MPAPI.matchmaking.group and MPAPI.matchmaking.group.status_line) then
		return nil
	end
	return {
		n = G.UIT.C,
		config = { align = "cm", padding = 0.08, r = 0.1, colour = G.C.BLACK, minw = 6 },
		nodes = PVP.lobby.group_panel_rows(PVP.lobby.ref),
	}
end
