-- Localization by @themike_71
return {
	descriptions = {
		Joker = {
			j_broken = {
				name = "ERROR :(",
				text = {
					"Esta carta está rota o no está",
					"implementada en la versión actual",
					"de un mod que estás usando.",
				},
			},
			j_mp_defensive_joker = {
				name = "Comodín defensivo", -- Personalmente prefiero "Jokers" antes que "Comodines" pero tomaré de base la traducción oficial de Balatro
				text = {
					"{C:chips}+#1#{} Fichas por cada {C:red,E:1}vida{}",
					"menos que tu {X:purple,C:white}Némesis{}",
					"{C:inactive}(Actual {C:chips}+#2#{C:inactive} Fichas)",
				},
			},
			j_mp_skip_off = {
				name = "Avioncito", -- "Skip-Off" a traducción literal sería "Saltalo"/"Saltado" pero lo cambié acorde al arte de la carta ya que pierde un poco el juego de palabras
				text = {
					"{C:blue}+#1#{} Manos y {C:red}+#2#{} descartes",
					"por {C:attention}ciega{} adicional omitida",
					"en comparación con tu {X:purple,C:white}Némesis{}",
					"{C:inactive}(Actual {C:blue}+#3#{C:inactive}/{C:red}+#4#{C:inactive}, #5#)",
				},
			},
			j_mp_lets_go_gambling = {
				name = "Let's Go Gambling", -- La traducción sería "Vamos a apostar" pero lo dejareos así para mantener el meme
				text = {
					"{C:green}#1# en #2#{} probabilidades de",
					"{X:mult,C:white}X#3#{} Multi y {C:money}$#4#{}",
					"{C:green}#5# en #6#{} probabilidades de dar",
					"{C:money}$#7# a tu {X:purple,C:white}Némesis{}",
				},
			},
			j_mp_speedrun = {
				name = "SPEEDRUN",
				text = {
					"Si llegas a la {C:attention}Ciega PvP",
					"antes que tu {X:purple,C:white}Némesis{},",
					"crea una comodín {C:spectral}Espectral{}",
					"{C:inactive}(Debe haber espacio)",
				},
			},
			j_mp_conjoined_joker = {
				name = "Comodín Siamés",
				text = {
					"Mientras estés en una {C:attention}Ciega PvP{}, ganas",
					"{X:mult,C:white}X#1#{} Multi por cada {C:blue}Mano{}",
					"que tenga tu {X:purple,C:white}Némesis{}",
					"{C:inactive}(Máximo {X:mult,C:white}X#2#{C:inactive} Multi, Actual {X:mult,C:white}X#3#{C:inactive} multi)",
				},
			},
			j_mp_penny_pincher = {
				name = "Tacaño",
				text = {
					"Al inicio de cada tienda, gana",
					"{C:money}$#1#{} por cada {C:money}$#2#{} que gastó",
					" tu {X:purple,C:white}Némesis{} en la útima tienda",
				},
			},
			j_mp_taxes = {
				name = "Impuesto", -- Pensaba poner SAT pero me aguanté las ganas
				text = {
					"Cuando tu {X:purple,C:white}Némesis{} vende",
					"una carta ganas {C:mult}+#1#{} Multi",
					"{C:inactive}(Actual {C:mult}+#2#{C:inactive} multi)",
				},
			},
			j_mp_magnet = {
				name = "Imán",
				text = {
					"Despues de {C:attention}#1#{} rondas,",
					"vende esta carta para {C:attention}copiar{}",
					"el {C:attention}comodín{} con mayor valor de venta",
					"que tenga tu {X:purple,C:white}Némesis{}",
					"{C:inactive}(Actual {C:attention}#2#{C:inactive}/#3# rondas)",
					"{C:inactive,s:0.8}(No copia estado del comodín)",
				},
			},
			j_mp_pizza = {
				name = "Pizza", -- Si esta carta es una referencia a Breaking Bad
				text = {
					"{C:red}+#1#{} Descartes para todos los jugadores",
					"{C:red}-#2#{} Descartes cuando un jugador",
					"selecciona una ciega",
					"Se consume cuando tu {X:purple,C:white}Némesis{} omite una ciega",
				},
			},
			j_mp_pacifist = {
				name = "Pacifista",
				text = {
					"{X:mult,C:white}X#1#{} Multi mientras",
					"no estés en una {C:attention}Ciega PvP{}",
				},
			},
			j_mp_hanging_chad = {
				name = "Papel perforado",
				text = {
					"Reacyiva la {C:attention}primera{} y {C:attention}segunda{}",
					"carta jugada al anotar",
					"{C:attention}#1#{} veces adicionales",
				},
			},
		},
		Planet = {
			c_mp_asteroid = {
				name = "Asteroid",
				text = {
					"Disminuye #1# nivel de la",
					"{C:legendary,E:1}mano de póker{}",
					"con mayor nivel",
					"de tu {X:purple,C:white}némesis{}",
				},
			},
		},
		Blind = {
			bl_mp_nemesis = {
				name = "Tu némesis",
				text = {
					"Tú contra tu propio némesis,",
					"quien tenga más fichas gana",
				},
			},
		},
		Edition = {
			e_mp_phantom = {
				name = "Fantasma",
				text = {
					"{C:attention}Eterno{} and {C:dark_edition}Negativo{}",
					"Creados y destruidos por tu {X:purple,C:white}némesis{}",
				},
			},
		},
		Enhanced = {
			m_mp_glass = {
				name = "Carta de vidrio",
				text = {
					"{X:mult,C:white} X#1# {} multi",
					"{C:green}#2# en #3#{} probabilidades",
					"de destruir la carta",
				},
			},
		},
		Other = {
			current_nemesis = {
				name = "Némesis",
				text = {
					"{X:purple,C:white}#1#{}",
					"Tu propio némesis",
				},
			},
		},
	},
	misc = {
		labels = {
			mp_phantom = "Fantasma",
		},
		challenge_names = {
			c_mp_standard = "Estándar",
			c_mp_badlatro = "Badlatro",
			c_mp_tournament = "Torneo",
			c_mp_weekly = "Semanal",
			c_mp_vanilla = "Vanilla",
		},
		dictionary = {
			b_singleplayer = "Un Jugador",
			b_join_lobby = "Unirse a sala",
			b_return_lobby = "Regresar a sala",
			b_reconnect = "Reconectar",
			b_create_lobby = "Crear sala",
			b_start_lobby = "Iniciar sala",
			b_ready = "Listo",
			b_unready = "No listo",
			b_leave_lobby = "Abandonar sala",
			b_mp_discord = "Balatro Multiplayer Discord Server",
			b_start = "INICIAR",
			b_wait_for_host_start = { "ESPERANDO AL", "ANFITRIÓN PARA INICIAR" },
			b_wait_for_players = { "ESPERANDO", "JUGADORES" },
			b_lobby_options = "OPCIONES DE SALA",
			b_copy_clipboard = "Copiar al portapapeles",
			b_view_code = "VER CÓDIGO",
			b_leave = "ABANDONAR",
			b_opts_cb_money = "Recibe $ al perder una vida",
			b_opts_no_gold_on_loss = "Sin recompensa al perder una ronda",
			b_opts_death_on_loss = "Pierde una vida por ronda no-PvP",
			b_opts_start_antes = "Apuestas iniciales",
			b_opts_diff_seeds = "Los jugadores estan en diferentes seeds",
			b_opts_lives = "Vidas",
			b_opts_multiplayer_jokers = "Habilitar cartas de Multiplayer",
			b_opts_player_diff_deck = "Los jugadores tienen diferentes barajas",
			b_reset = "Reiniciar",
			b_set_custom_seed = "Agregar seed",
			b_mp_kofi_button = "Donar en Ko-fi",
			b_unstuck = "Desatascar", -- No sé que quiere decir realmente "Unstuck", sé que es como "Desatascar/Destrabar" pero lo dejaré así por ahora
			b_unstuck_arcana = "Atascar en paquetes potenciadores",
			b_unstuck_blind = "Atascar fuera de PvP",
			b_misprint_display = "Muestra la siguiente carta de la baraja",
			b_players = "Jugadores",
			b_continue_singleplayer = "Continuar en Un Jugador",
			k_enemy_score = "Puntuación actual del enemigo:",
			k_enemy_hands = "Manos restantes del enemigo: ",
			k_coming_soon = "¡Próximamente!",
			k_wait_enemy = "Esperando al contrincante...",
			k_lives = "Vidas",
			k_lost_life = "-1 Vida", -- Realmente es "Perdió una vida", mucho texto, -1 tambien sirve creo yo
			k_total_lives_lost = " Vidas totales perdidas ($4 cada una)",
			k_attrition_name = "Desgaste",
			k_enter_lobby_code = "Agregar código de sala",
			k_paste = "Pegar desde el portapapeles",
			k_username = "Nombre de usuario:",
			k_enter_username = "Enter username",
			k_join_discord = "Join the ",
			k_discord_msg = "You can report any bugs and find players to play there",
			k_enter_to_save = "Agregar nombre de usuario",
			k_in_lobby = "En sala",
			k_connected = "Conectado al servidor",
			k_warn_service = "ADVERTENCIA: No se encontró el servidor multijugador",
			k_set_name = "¡Agrega tu usuario en el menú! (Mods > Multijugador > Configuración)",
			k_mod_hash_warning = "¡Los jugadores tienen diferentes mods o diferentes versiones de mods! ¡Esto puede causar problemas!",
			k_lobby_options = "Opciones del sala",
			k_connect_player = "Jugadores conectados:",
			k_opts_only_host = "Solo el anfitrión puede modificar estas opciones",
			k_opts_gm = "Opciones del juego",
			k_bl_life = "Vida",
			k_bl_or = "o",
			k_bl_death = "Muerte",
			k_current_seed = "Seed actual: ",
			k_random = "Random",
			k_standard = "Estándar",
			k_standard_description = "Reglas del modo Estandar, Agrega cartas del Multiplayer y algunos cambios del juego base para adaptarse al meta del Mod",
			k_vanilla = "Vanilla",
			k_vanilla_description = "Reglas del modo Vanilla, Sin cartas del Multiplayer y no modifica nada del juego base.",
			k_weekly = "Semanal",
			k_weekly_description = "Reglas especiales que cambia semanal o quincenalmente. ¡Supongo que tendras que descubrirlo por tu cuenta! Actual: ",
			k_tournament = "Torneo",
			k_tournament_description = "Reglas de Torneo, reglas del modo Estandar pero no se permite cambiar las opciones de la sala.",
			k_badlatro = "Badlatro",
			k_badlatro_description = "Reglas semanales diseñadas por @dr_monty_the_snek en nuestro server de discord que ha sido agregado de forma permanente.",
			k_oops_ex = "Ups!",
			k_timer = "Timer",
			k_mods_list = "Lista de Mods",
			k_enemy_jokers = "Comodines del enemigo",
			ml_enemy_loc = { "Ubicación del", "enemigo" },
			ml_mp_kofi_message = {
				"Este mod y los servidores es",
				"desarrollado y mantenido por ",
				"una sola persona, si quieres",
				"apoyar puedes considerar",
			},
			loc_ready = "Listo para el PvP",
			loc_selecting = "Seleccionando ciega",
			loc_shop = "En la tienda",
			loc_playing = "Jugando ",
		},
		v_dictionary = {
			a_mp_art = { "Arte: #1#" },
			a_mp_code = { "Codigo: #1#" },
			a_mp_idea = { "Idea: #1#" },
			a_mp_skips_ahead = { "#1# Omisiones por delante" },
			a_mp_skips_behind = { "#1# Omisiones por detrás" },
			a_mp_skips_tied = { "Empatado" },
		},
		v_text = {
			ch_c_hanging_chad_rework = { "Comodín {C:attention}Papel perforado{} está {C:dark_edition}modificado" },
			ch_c_glass_cards_rework = { "Las {C:attention}Cartas de vidrio{} están {C:dark_edition}modificadas" },
		},
	},
}
