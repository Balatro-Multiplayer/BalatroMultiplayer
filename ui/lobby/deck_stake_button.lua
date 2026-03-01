local Disableable_Button = MP.UI.Disableable_Button

-- Component for deck selection button in lobby
function MP.UI.create_lobby_deck_button(text_scale, back, stake)
	local deck_labels = {
		localize({
			type = "name_text",
			key = MP.UTILS.get_deck_key_from_name(back),
			set = "Back",
		}),
		localize({
			type = "name_text",
			key = SMODS.stake_from_index(type(stake) == "string" and tonumber(stake) or stake),
			set = "Stake",
		}),
	}

	if MP.LOBBY.is_host then
		return Disableable_Button({
			id = "lobby_choose_deck",
			button = "lobby_choose_deck",
			colour = G.C.PURPLE,
			minw = 2.15,
			minh = 1.35,
			label = deck_labels,
			scale = text_scale * 1.2,
			col = true,
			enabled_ref_table = MP.LOBBY,
			enabled_ref_value = "is_host",
		})
	else
		return Disableable_Button({
			id = "lobby_choose_deck",
			button = "lobby_choose_deck",
			colour = G.C.PURPLE,
			minw = 2.15,
			minh = 1.35,
			label = deck_labels,
			scale = text_scale * 1.2,
			col = true,
			enabled_ref_table = MP.LOBBY.config,
			enabled_ref_value = "different_decks",
		})
	end
end
