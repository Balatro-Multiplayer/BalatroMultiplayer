if SMODS.Mods["Distro"] and SMODS.Mods["Distro"].can_load then
	function get_multiplayer_details()
		local enemy_username = G.LOBBY.is_host and G.LOBBY.guest.username or G.LOBBY.host.username

		return "Multiplayer Versus " .. enemy_username .. " | " .. tostring(G.MULTIPLAYER_GAME.lives) .. " Lives Left"
	end

	local start_run_ref = Game.start_run
	function Game:start_run(args)
		start_run_ref(self, args)

		if G.LOBBY.code then
			local back_key, back_name = Distro.get_back_name()
			local stake_key, stake_name = Distro.get_stake_name()

			DiscordIPC.activity = {
				details = get_multiplayer_details(),
				state = "Selecting Blind",
				timestamps = {
					start = os.time() * 1000,
				},
				assets = {
					large_image = back_key,
					large_text = back_name,
					small_image = stake_key,
					small_text = stake_name,
				},
			}

			DiscordIPC.send_activity()
		end
	end

	local update_selecting_hand_ref = Game.update_selecting_hand
	function Game:update_selecting_hand(dt)
		local updating = false
		if not G.STATE_COMPLETE then
			updating = true
		end

		update_selecting_hand_ref(self, dt)

		if updating then
			updating = false
			if G.LOBBY.code then
				DiscordIPC.activity.details = get_multiplayer_details()
				DiscordIPC.activity.state = G.GAME.current_round.hands_left
					.. " Hands, "
					.. G.GAME.current_round.discards_left
					.. " Discards left"
				DiscordIPC.send_activity()
			end
		end
	end

	local update_shop_ref = Game.update_shop
	function Game:update_shop(dt)
		local updating = false
		if not G.STATE_COMPLETE then
			updating = true
		end

		update_shop_ref(self, dt)

		if updating then
			updating = false
			if G.LOBBY.code then
				DiscordIPC.activity.details = get_multiplayer_details()
				DiscordIPC.activity.state = "Shopping"
				DiscordIPC.send_activity()
			end
		end
	end

	local main_menu_ref = Game.main_menu
	function Game:main_menu(change_context)
		main_menu_ref(self, change_context)

		if G.LOBBY.code then
			local enemy_username = nil
			if G.LOBBY.is_host then
				if G.LOBBY.guest then
					enemy_username = G.LOBBY.guest.username
				end
			else
				enemy_username = G.LOBBY.host.username
			end

			DiscordIPC.activity = {
				details = enemy_username and "In Multiplayer Lobby with " .. enemy_username or "In Multiplayer Lobby",
				timestamps = {
					start = os.time() * 1000,
				},
				assets = {
					large_image = "default",
				},
			}
			DiscordIPC.send_activity()
		end
	end
end
