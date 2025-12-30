function MP.UTILS.save_username(text)
	MP.ACTIONS.set_username(text)
	SMODS.Mods["Multiplayer"].config.username = text
end

function MP.UTILS.get_username()
	return SMODS.Mods["Multiplayer"].config.username
end

function MP.UTILS.save_blind_col(num)
	MP.ACTIONS.set_blind_col(num)
	SMODS.Mods["Multiplayer"].config.blind_col = num
end

function MP.UTILS.get_blind_col()
	return SMODS.Mods["Multiplayer"].config.blind_col
end

function MP.UTILS.blind_col_numtokey(num)
	local keys = {
		"tooth",
		"small",
		"big",
		"hook",
		"ox",
		"house",
		"wall",
		"wheel",
		"arm",
		"club",
		"fish",
		"psychic",
		"goad",
		"water",
		"window",
		"manacle",
		"eye",
		"mouth",
		"plant",
		"serpent",
		"pillar",
		"needle",
		"head",
		"flint",
		"mark",
	}
	return "bl_" .. keys[num]
end

function MP.UTILS.get_nemesis_key() -- calling this function assumes the user is currently in a multiplayer game
	local ret =
		MP.UTILS.blind_col_numtokey((MP.LOBBY.is_host and MP.LOBBY.guest.blind_col or MP.LOBBY.host.blind_col) or 1)
	if tonumber(MP.GAME.enemy.lives) <= 1 and tonumber(MP.GAME.lives) <= 1 then
		if G.STATE ~= G.STATES.ROUND_EVAL then -- very messy fix that mostly works. breaks in a different way... but far harder to notice
			ret = "bl_final_heart"
		end
	end
	return ret
end

function MP.UTILS.save_preview(table)
	for k, v in pairs(table) do
		SMODS.Mods["Multiplayer"].config.preview[k] = v
	end
end

function MP.UTILS.get_preview_cfg(index)
	local ret = SMODS.Mods["Multiplayer"].config.preview[index]
	if not ret or #ret < 1 then
		if index == "text" then
			ret = "CALCULATING"
		else
			ret = "Calculate Score"
		end
	end
	return ret
end

function MP.UTILS.copy_to_clipboard(text)
	if G.F_LOCAL_CLIPBOARD then
		G.CLIPBOARD = text
	else
		love.system.setClipboardText(text)
	end
end

function MP.UTILS.get_from_clipboard()
	if G.F_LOCAL_CLIPBOARD then
		return G.F_LOCAL_CLIPBOARD
	else
		return love.system.getClipboardText()
	end
end

function MP.UTILS.random_message()
	local messages = {
		localize("k_message1"),
		localize("k_message2"),
		localize("k_message3"),
		localize("k_message4"),
		localize("k_message5"),
		localize("k_message6"),
		localize("k_message7"),
		localize("k_message8"),
		localize("k_message9"),
	}
	return messages[math.random(1, #messages)]
end

function MP.UTILS.add_nemesis_info(info_queue)
	if MP.LOBBY.code then
		info_queue[#info_queue + 1] = {
			set = "Other",
			key = "current_nemesis",
			vars = { MP.LOBBY.is_host and MP.LOBBY.guest.username or MP.LOBBY.host.username },
		}
	end
end
