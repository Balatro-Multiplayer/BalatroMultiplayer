-- The private lobby's group queue panel (pvp_api/group_queue.lua): the host
-- picks a casual mode this lobby fits and queues it as a group; while the
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
	local rows = { text_row(localize("k_group_queue"), 0.36, G.C.UI.TEXT_INACTIVE) }
	if not lobby then
		return rows
	end
	local view = lobby.group_queue
	if type(view) == "table" then
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

	local last = Group.status_line(lobby)
	if last and last.text then
		rows[#rows + 1] = text_row(last.text, 0.28, G.C.UI.TEXT_INACTIVE)
	end
	if not lobby.is_host then
		rows[#rows + 1] = text_row(localize("k_group_member_hint"), 0.28)
		local refused = Group.member_standing_refusal(Group.facts_from_lobby(lobby))
		if refused then
			rows[#rows + 1] = text_row(Group.refusal_text(refused), 0.28, G.C.RED)
		end
		return rows
	end
	local eligible, refusal = PVP.group_queue_options(lobby)
	-- A member's standing greys the button but leaves it pressable: the
	-- server's refusal names the mods (MPAPI api/matchmaking/group/queue.lua).
	local standing_refused = refusal and refusal.code == Group.Refusal.MEMBER_REFUSED
	if refusal and not standing_refused then
		rows[#rows + 1] = text_row(Group.refusal_text(refusal), 0.28, G.C.UI.TEXT_INACTIVE)
		return rows
	end
	if #eligible == 0 then
		rows[#rows + 1] = text_row(localize("k_group_no_modes"), 0.28, G.C.UI.TEXT_INACTIVE)
		return rows
	end
	if standing_refused then
		rows[#rows + 1] = text_row(Group.refusal_text(refusal), 0.28, G.C.RED)
	end
	local names = {}
	for i, mode in ipairs(eligible) do
		names[i] = mode.display
	end
	PVP._group_mode_choice = math.max(1, math.min(PVP._group_mode_choice or 1, #eligible))
	rows[#rows + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
		create_option_cycle({
			id = "mp_pvp_group_mode",
			label = localize("k_group_mode"),
			options = names,
			current_option = PVP._group_mode_choice,
			opt_callback = "mp_pvp_group_mode_cycle",
			w = 3,
			scale = 0.7,
			colour = G.C.ORANGE,
		}),
		UIBox_button({ id = "mp_pvp_group_queue", button = "mp_pvp_group_queue", label = { localize("b_group_queue") }, colour = standing_refused and G.C.UI.BACKGROUND_INACTIVE or G.C.BLUE, minw = 2.6, minh = 0.8, scale = 0.45 }),
	} }
	return rows
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
