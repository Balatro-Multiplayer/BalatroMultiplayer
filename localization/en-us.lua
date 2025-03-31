return {
	descriptions = {
		Joker = {
			j_broken = {
				name = "BROKEN",
				text = {
					"This card is either broken or",
					"not implemented in the current",
					"version of a mod you are using.",
				},
			},
			j_mp_defensive_joker = {
				name = "Defensive Joker",
				text = {
					"{C:chips}+#1#{} Chips for every {C:red,E:1}life{}",
					"less than your {X:purple,C:white}Nemesis{}",
					"{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
				},
			},
			j_mp_skip_off = {
				name = "Skip-Off",
				text = {
					"{C:blue}+#1#{} Hands and {C:red}+#2#{} Discards",
					"per additional {C:attention}Blind{} skipped",
					"compared to your {X:purple,C:white}Nemesis{}",
					"{C:inactive}(Currently {C:blue}+#3#{C:inactive}/{C:red}+#4#{C:inactive}, #5#)",
				},
			},
			j_mp_lets_go_gambling = {
				name = "Let's Go Gambling",
				text = {
					"{C:green}#1# in #2#{} chance for",
					"{X:mult,C:white}X#3#{} Mult and {C:money}$#4#{}",
					"{C:green}#5# in #6#{} chance to give",
					"your {X:purple,C:white}Nemesis{} {C:money}$#7#",
				},
			},
			j_mp_speedrun = {
				name = "SPEEDRUN",
				text = {
					"If you reach a {C:attention}PvP Blind",
					"before your {X:purple,C:white}Nemesis{},",
					"create a random {C:spectral}Spectral{} card",
					"{C:inactive}(Must have room)",
				},
			},
			j_mp_conjoined_joker = {
				name = "Conjoined Joker",
				text = {
					"While in a {C:attention}PvP Blind{}, gain",
					"{X:mult,C:white}X#1#{} Mult for every {C:blue}Hand{}",
					"your {X:purple,C:white}Nemesis{} has left",
					"{C:inactive}(Max {X:mult,C:white}X#2#{C:inactive} Mult, Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
				},
			},
			j_mp_penny_pincher = {
				name = "Penny Pincher",
				text = {
					"At start of shop, gain",
					"{C:money}$#1#{} for every {C:money}$#2#{}",
					"your {X:purple,C:white}Nemesis{} spent last shop",
				},
			},
			j_mp_taxes = {
				name = "Taxes",
				text = {
					"When your {X:purple,C:white}Nemesis'{} sells",
					"a card gain {C:mult}+#1#{} Mult",
					"{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
				},
			},
			j_mp_magnet = {
				name = "Magnet",
				text = {
					"After {C:attention}#1#{} rounds,",
					"sell this card to {C:attention}Copy{}",
					"your {X:purple,C:white}Nemesis'{} highest ",
					"sell cost {C:attention}Joker{}",
					"{C:inactive}(Currently {C:attention}#2#{C:inactive}/#3# rounds)",
					"{C:inactive,s:0.8}(Does not copy Joker state)",
				},
			},
			j_mp_pizza = {
				name = "Pizza",
				text = {
					"{C:red}+#1#{} Discards for all players",
					"{C:red}-#2#{} Discard when any player",
					"selects a blind",
					"Eaten when your {X:purple,C:white}Nemesis{} skips",
				},
			},
			j_mp_pacifist = {
				name = "Pacifist",
				text = {
					"{X:mult,C:white}X#1#{} Mult while",
					"not in a {C:attention}PvP Blind{}",
				},
			},
			j_mp_hanging_chad = {
				name = "Hanging Chad",
				text = {
					"Retrigger {C:attention}first{} and {C:attention}second{}",
					"played card used in scoring",
					"{C:attention}#1#{} additional time",
				},
			},
		},
		Planet = {
			c_mp_asteroid = {
				name = "Asteroid",
				text = {
					"Remove #1# level from",
					"your {X:purple,C:white}Nemesis'{}",
					"highest level",
					"{C:legendary,E:1}poker hand{}",
				},
			},
		},
		Blind = {
			bl_mp_nemesis = {
				name = "Your Nemesis",
				text = {
					"Face another player,",
					"most chips wins",
				},
			},
		},
		Edition = {
			e_mp_phantom = {
				name = "Phantom",
				text = {
					"{C:attention}Eternal{} and {C:dark_edition}Negative{}",
					"Created and destroyed by your {X:purple,C:white}Nemesis{}",
				},
			},
		},
		Enhanced = {
			m_mp_glass = {
				name = "Glass Card",
				text = {
					"{X:mult,C:white} X#1# {} Mult",
					"{C:green}#2# in #3#{} chance to",
					"destroy card",
				},
			},
		},
		Other = {
			current_nemesis = {
				name = "Nemesis",
				text = {
					"{X:purple,C:white}#1#{}",
					"Your one and only Nemesis",
				},
			},
		},
	},
	misc = {
		labels = {
			mp_phantom = "Phantom",
		},
		challenge_names = {
			c_mp_standard = "Standard",
			c_mp_badlatro = "Badlatro",
			c_mp_tournament = "Tournament",
			c_mp_weekly = "Weekly",
			c_mp_vanilla = "Vanilla",
		},
		dictionary = {
			b_singleplayer = "Singleplayer",
			b_join_lobby = "Join Lobby",
			b_return_lobby = "Return to Lobby",
			b_reconnect = "Reconnect",
			b_create_lobby = "Create Lobby",
			b_start_lobby = "Start Lobby",
			b_ready = "Ready",
			b_unready = "Unready",
			b_leave_lobby = "Leave Lobby",
			b_mp_discord = "Balatro Multiplayer Discord Server",
			b_start = "START",
			b_wait_for_host_start = { "WAITING FOR", "HOST TO START" },
			b_wait_for_players = { "WAITING FOR", "PLAYERS" },
			b_lobby_options = "LOBBY OPTIONS",
			b_copy_clipboard = "Copy to clipboard",
			b_view_code = "VIEW CODE",
			b_leave = "LEAVE",
			b_opts_cb_money = "Give comeback $ on life loss",
			b_opts_no_gold_on_loss = "Don't get blind rewards on round loss",
			b_opts_death_on_loss = "Lose a life on non-PvP round loss",
			b_opts_start_antes = "Starting Antes",
			b_opts_diff_seeds = "Players have different seeds",
			b_opts_lives = "Lives",
			b_opts_multiplayer_jokers = "Enable Multiplayer Cards",
			b_opts_player_diff_deck = "Players have different decks",
			b_reset = "Reset",
			b_set_custom_seed = "Set Custom Seed",
			b_mp_kofi_button = "Supporting me on Ko-fi",
			b_unstuck = "Unstuck",
			b_unstuck_blind = "Stuck Outside PvP",
			b_misprint_display = "Display the next card in the deck",
			b_players = "Players",
			b_continue_singleplayer = "Continue in Singleplayer",
			k_enemy_score = "Current Enemy score",
			k_enemy_hands = "Enemy hands left: ",
			k_coming_soon = "Coming Soon!",
			k_wait_enemy = "Waiting for enemy to finish...",
			k_lives = "Lives",
			k_lost_life = "Lost a life",
			k_total_lives_lost = " Total Lives Lost ($4 each)",
			k_attrition_name = "Attrition",
			k_enter_lobby_code = "Enter Lobby Code",
			k_paste = "Paste From Clipboard",
			k_username = "Username:",
			k_enter_username = "Enter username",
			k_join_discord = "Join the ",
			k_discord_msg = "You can report any bugs and find players to play there",
			k_enter_to_save = "Press enter to save",
			k_in_lobby = "In the lobby",
			k_connected = "Connected to Service",
			k_warn_service = "WARN: Cannot Find Multiplayer Service",
			k_set_name = "Set your username in the main menu! (Mods > Multiplayer > Config)",
			k_mod_hash_warning = "Players have different mods or mod versions! This can cause problems!",
			k_lobby_options = "Lobby Options",
			k_connect_player = "Connected Players:",
			k_opts_only_host = "Only the Lobby Host can change these options",
			k_opts_gm = "Gamemode Modifiers",
			k_bl_life = "Life",
			k_bl_or = "or",
			k_bl_death = "Death",
			k_current_seed = "Current seed: ",
			k_random = "Random",
			k_standard = "Standard",
			k_standard_description = "The standard ruleset, includes Multiplayer cards and changes to the base game to fit the Multiplayer meta.",
			k_vanilla = "Vanilla",
			k_vanilla_description = "The vanilla ruleset, no Multiplayer cards, no modifications to base game content.",
			k_weekly = "Weekly",
			k_weekly_description = "A special ruleset that changes weekly or bi-weekly. I guess you'll have to find out what it is! Currently: ",
			k_tournament = "Tournament",
			k_tournament_description = "The tournament ruleset, this is the same as the standard ruleset but doesn't allow changing the lobby options.",
			k_badlatro = "Badlatro",
			k_badlatro_description = "A weekly ruleset designed by @dr_monty_the_snek on the discord server that has been added to the mod permanently.",
			k_oops_ex = "Oops!",
			k_timer = "Timer",
			k_mods_list = "Mods List",
			k_enemy_jokers = "Enemy Jokers",
			ml_enemy_loc = { "Enemy", "location" },
			ml_mp_kofi_message = {
				"This mod and game server is",
				"developed and maintained by ",
				"one person, if",
				"you like it consider",
			},
			loc_ready = "Ready for PvP",
			loc_selecting = "Selecting a Blind",
			loc_shop = "Shopping",
			loc_playing = "Playing ",
		},
		v_dictionary = {
			a_mp_art = { "Art: #1#" },
			a_mp_code = { "Code: #1#" },
			a_mp_idea = { "Idea: #1#" },
			a_mp_skips_ahead = { "#1# Skips Ahead" },
			a_mp_skips_behind = { "#1# Skips Behind" },
			a_mp_skips_tied = { "Tied" },
		},
		v_text = {
			ch_c_hanging_chad_rework = { "{C:attention}Hanging Chad{} is {C:dark_edition}reworked" },
			ch_c_glass_cards_rework = { "{C:attention}Glass Cards{} are {C:dark_edition}reworked" },
		},
		challenge_names = {
			c_mp_misprint_deck = "Misprint Deck",
			c_mp_legendaries = "Legendaries",
			c_mp_psychosis = "Psychosis",
			c_mp_scratch = "From Scratch",
			c_mp_twin_towers = "Twin Towers",
			c_mp_in_the_red = "In the Red",
			c_mp_paper_money = "Paper Money",
			c_mp_high_hand = "High Hand",
			c_mp_chore_list = "Chore List",
			c_mp_oops_all_jokers = "Oops! All Jokers",
			c_mp_divination = "Divination",
			c_mp_skip_off = "Skip-Off",
			c_mp_lets_go_gambling = "Let's Go Gambling",
			c_mp_high_hand = "High Hand",
			c_mp_speed = "Speed",
		},
	},
}
