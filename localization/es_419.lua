-- Localization by @themike_71
-- Corrections and further updates by ElTioRata
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
				name = "Comodín defensivo", -- themike_71: Personalmente prefiero "Jokers" antes que "Comodines" pero tomaré de base la traducción oficial de Balatro
				text = {
					"{C:chips}+#1#{} fichas por cada {C:red,E:1}vida{}",
					"menos que tu {X:purple,C:white}némesis{}",
					"{C:inactive}(Actualmente {C:chips}+#2#{C:inactive} fichas)",
				},
			},
			j_mp_skip_off = {
				name = "Avioncito", -- themike_71: "Skip-Off" a traducción literal sería "Saltalo"/"Saltado" pero lo cambié acorde al arte de la carta ya que pierde un poco el juego de palabras. | ElTioRata: Skip-Off proviene de "Take-Off" ("despegue", por eso el avión).
				text = {
					"{C:blue}+#1#{} manos y {C:red}+#2#{} descartes",
					"por {C:attention}ciega{} adicional omitida",
					"en comparación con tu {X:purple,C:white}némesis{}",
					"{C:inactive}(Actualmente {C:blue}+#3#{C:inactive}/{C:red}+#4#{C:inactive}, #5#)",
				},
			},
			j_mp_lets_go_gambling = {
				name = "Let's Go Gambling", -- themike_71: La traducción sería "Vamos a apostar" pero lo dejareos así para mantener el meme
				text = {
					"{C:green}#1# en #2#{} probabilidades de",
					"{X:mult,C:white}X#3#{} multi y {C:money}#4#${}", -- ElTioRata: Signo de dólar a la derecha para mantener consistencia con localización del juego base
					"{C:green}#5# en #6#{} probabilidades de dar",
					"{C:money}#7#$ a tu {X:purple,C:white}némesis{}",
				},
			},
			j_mp_speedrun = {
				name = "CARRERA DE VELOCIDAD", -- ElTioRata: Sé que el término queda más largo pero así suelen ponerlo en traducciones oficiales
				text = {
					"Si llegas a la {C:attention}Ciega PvP",
					"antes que tu {X:purple,C:white}Némesis{},",
					"crea una comodín {C:spectral}Espectral{}",
					"{C:inactive}(Debe haber espacio)",
				},
			},
			j_mp_conjoined_joker = {
				name = "Comodín siamés",
				text = {
					"Mientras estés en una {C:attention}ciega JcJ{}, ganas",
					"{X:mult,C:white}X#1#{} multi por cada {C:blue}mano{}",
					"que tenga tu {X:purple,C:white}némesis{}",
					"{C:inactive}(Máximo {X:mult,C:white}X#2#{C:inactive} multi, actualmente {X:mult,C:white}X#3#{C:inactive} multi)",
				},
			},
			j_mp_penny_pincher = {
				name = "Tacaño",
				text = {
					"Al inicio de cada tienda, gana",
					"{C:money}#1#${} por cada {C:money}#2#${} que gastó",
					"tu {X:purple,C:white}némesis{} en la última tienda",
				},
			},
			j_mp_taxes = {
				name = "Impuestos", -- themike_71: Pensaba poner SAT pero me aguanté las ganas
				text = {
					"Cuando tu {X:purple,C:white}némesis{} vende",
					"una carta ganas {C:mult}+#1#{} multi",
					"{C:inactive}(Actualmente {C:mult}+#2#{C:inactive} multi)",
				},
			},
			j_mp_magnet = {
				name = "Imán",
				text = {
					"Después de {C:attention}#1#{} rondas,",
					"vende esta carta para {C:attention}copiar{}",
					"el {C:attention}comodín{} con mayor valor de venta",
					"que tenga tu {X:purple,C:white}némesis{}",
					"{C:inactive}(Actualmente {C:attention}#2#{C:inactive}/#3# rondas)",
					"{C:inactive,s:0.8}(No copia estado del comodín)",
				},
			},
			j_mp_pizza = {
				name = "Pizza", -- themike_71: Sí, esta carta es una referencia a Breaking Bad
				text = {
					"{C:red}+#1#{} descartes para todos los jugadores",
					"{C:red}-#2#{} descartes cuando un jugador",
					"selecciona una ciega",
					"Se consume cuando tu {X:purple,C:white}némesis{} omite una ciega",
				},
			},
			j_mp_pacifist = {
				name = "Pacifista",
				text = {
					"{X:mult,C:white}X#1#{} multi mientras",
					"no estés en una {C:attention}ciega JcJ{}",
				},
			},
			j_mp_hanging_chad = {
				name = "Papel perforado",
				text = {
					"Reactiva la {C:attention}primera{} y {C:attention}segunda{}",
					"carta jugada al anotar",
					"{C:attention}#1#{} veces adicionales",
				},
			},
		},
		Planet = {
			c_mp_asteroid = {
				name = "Asteroide",
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
					"{C:attention}Eterno{} y {C:dark_edition}negativo{}",
					"Creado y destruido por tu {X:purple,C:white}némesis{}",
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
					"Tu único e inigualable némesis",
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
			c_mp_vanilla = "Vainilla",
		},
		dictionary = {
			b_singleplayer = "Un jugador",
			b_join_lobby = "Unirse a sala",
			b_return_lobby = "Volver a sala",
			b_reconnect = "Reconectar",
			b_create_lobby = "Crear sala",
			b_start_lobby = "Iniciar sala",
			b_ready = "Prepararse",
			b_unready = "Desprepararse", -- ElTioRata: Este término no está reconocido por la RAE pero tampoco existe un equivalente real de "Unready" así que queda como está.
			b_leave_lobby = "Abandonar sala",
			b_mp_discord = "Servidor de Discord del multijugador de Balatro",
			b_start = "INICIAR",
			b_wait_for_host_start = { "ESPERANDO AL", "ANFITRIÓN PARA INICIAR" },
			b_wait_for_players = { "ESPERANDO", "JUGADORES" },
			b_lobby_options = "OPCIONES DE SALA",
			b_copy_clipboard = "Copiar al portapapeles",
			b_view_code = "VER CÓDIGO",
			b_leave = "ABANDONAR",
			b_opts_cb_money = "Recibe $ al perder una vida",
			b_opts_no_gold_on_loss = "No obtener recompensa al perder una ronda",
			b_opts_death_on_loss = "Pierde una vida al perder en rondas no-JcJ",
			b_opts_start_antes = "Apuestas iniciales",
			b_opts_diff_seeds = "Los jugadores estan en semillas diferentes",
			b_opts_lives = "Vidas",
			b_opts_multiplayer_jokers = "Habilitar cartas de multijugador",
			b_opts_player_diff_deck = "Los jugadores tienen barajas diferentes",
			b_reset = "Reiniciar",
			b_set_custom_seed = "Agregar semilla personalizada",
			b_mp_kofi_button = "Donar en Ko-fi",
			b_unstuck = "Desatascar", -- themike_71: No sé que quiere decir realmente "Unstuck", sé que es como "Desatascar/Destrabar" pero lo dejaré así por ahora
			b_unstuck_arcana = "Atascado en paquete potenciadores",
			b_unstuck_blind = "Atascado fuera de JcJ",
			b_misprint_display = "Muestra la siguiente carta de la baraja",
			b_players = "Jugadores",
			b_continue_singleplayer = "Continuar partida individual",
			k_enemy_score = "Puntuación del enemigo:",
			k_enemy_hands = "Manos del enemigo: ", -- ElTioRata: Esta línea y la anterior se acortan para que el texto no quede tan finito
			k_coming_soon = "¡Próximamente!",
			k_wait_enemy = "Esperando que termine el enemigo...",
			k_lives = "Vidas",
			k_lost_life = "-1 vida", -- themike_71: Realmente es "Perdió una vida", mucho texto, -1 tambien sirve creo yo
			k_total_lives_lost = "Vidas perdidas en total (4 $ c/u)",
			k_attrition_name = "Atrición", -- ElTioRata: "Desgaste" sería más correcto pero es mejor dejar la palabra original para ser más preciso
			k_enter_lobby_code = "Agregar código de sala",
			k_paste = "Pegar desde portapapeles",
			k_username = "Nombre de usuario:",
			k_enter_username = "Agregar nombre de usuario",
			k_join_discord = "Unirse al ",
			k_discord_msg = "Puedes reportar cualquier error y encontrar jugadores allí",
			k_enter_to_save = "Oprime ENTER para guardar",
			k_in_lobby = "En sala",
			k_connected = "Conectado al servidor",
			k_warn_service = "ADVERTENCIA: No se encontró el servidor multijugador",
			k_set_name = "¡Agrega tu usuario en el menú pricipal! (Mods > Multijugador > Configuración)",
			k_mod_hash_warning = "¡Los jugadores tienen diferentes mods o diferentes versiones de mods! ¡Esto puede causar problemas!",
			k_lobby_options = "Opciones de sala",
			k_connect_player = "Jugadores conectados:",
			k_opts_only_host = "Solo el anfitrión puede modificar estas opciones",
			k_opts_gm = "Modificadores",
			k_bl_life = "VIDA",
			k_bl_or = "o",
			k_bl_death = "MUERTE", -- ElTioRata: En mayúsculas tiene más gancho ;)
			k_current_seed = "Semilla actual: ",
			k_random = "Al azar",
			k_standard = "Estándar",
			k_standard_description = "Reglas del modo estándar, agrega cartas del multijugador y algunos cambios del juego base para adaptarse al meta del mod.",
			k_vanilla = "Vainilla",
			k_vanilla_description = "Reglas del modo vainilla, sin cartas del multijugador y no modifica nada del juego base.",
			k_weekly = "Semanal",
			k_weekly_description = "Reglas especiales que cambian semanal o quincenalmente. ¡Supongo que tendrás que descubrirlo por tu cuenta! Actualmente: ",
			k_tournament = "Torneo",
			k_tournament_description = "Reglas de torneo, igual que las reglas del modo estándar pero no se permite cambiar las opciones de sala.",
			k_badlatro = "Badlatro",
			k_badlatro_description = "Reglas semanales diseñadas por @dr_monty_the_snek en nuestro servidor de Discord que se agregaron de forma permanente.",
			k_oops_ex = "¡Ups!",
			k_timer = "Temporizador",
			k_mods_list = "Lista de mods",
			k_enemy_jokers = "Comodínes del enemigo",
			ml_enemy_loc = { "Enemigo", "ubicación" },
			ml_mp_kofi_message = {
				"Este mod y sus servidores son",
				"desarrollados y mantenidos por ",
				"una sola persona, si te gusta",
				"puedes considerar",
			},
			ml_lobby_info = { "Sala", "Info" },
			loc_ready = "Listo para JcJ",
			loc_selecting = "Seleccionando ciega",
			loc_shop = "En la tienda",
			loc_playing = "Jugando ",
		},
		v_dictionary = {
			a_mp_art = { "Arte: #1#" },
			a_mp_code = { "Código: #1#" },
			a_mp_idea = { "Idea: #1#" },
			a_mp_skips_ahead = { "#1# omisiones por delante" },
			a_mp_skips_behind = { "#1# omisiones por detrás" },
			a_mp_skips_tied = { "empatadas" },
		},
		v_text = {
			ch_c_hanging_chad_rework = { "{C:attention}Papel perforado{} está {C:dark_edition}modificado" },
			ch_c_glass_cards_rework = { "{C:attention}Cartas de vidrio{} están {C:dark_edition}modificadas" },
		},
		challenge_names = {
			c_mp_misprint_deck = "Baraja mal impresa",
			c_mp_legendaries = "Legendarios",
			c_mp_psychosis = "Psicosis",
			c_mp_scratch = "Desde cero",
			c_mp_twin_towers = "Torres gemelas",
			c_mp_in_the_red = "Con déficit",
			c_mp_paper_money = "Papel moneda",
			c_mp_high_hand = "Mano más alta",
			c_mp_chore_list = "Lista de pendientes",
			c_mp_oops_all_jokers = "Solo comodínes", -- ElTioRata: "Oops! All 6s" se localizó como "Todos séises", saco el "¡Ups!" por consistencia aunque la referencia al cereal se pierda.
			c_mp_divination = "Divinidad",
			c_mp_skip_off = "Avioncito",
			c_mp_lets_go_gambling = "Let's Go Gambling",
			c_mp_high_hand = "Mano más alta", -- ElTioRata: Repetida por algún motivo :P
			c_mp_speed = "Velocidad",
		},
	},
}