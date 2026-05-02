MP.Ruleset({
	key = "experimental_pressure",
	layers = { "ranked", "experimental", "pressure_timer" },
	forced_gamemode = "gamemode_mp_attrition",
}):inject()

MP.Ruleset({
	key = "experimental_no_animation",
	layers = { "ranked", "experimental", "no_animation_timer" },
	forced_gamemode = "gamemode_mp_attrition",
}):inject()

MP.Ruleset({
	key = "experimental_pressure_only",
	layers = { "standard", "ranked", "pressure_timer" },
	forced_gamemode = "gamemode_mp_attrition",
}):inject()

MP.Ruleset({
	key = "experimental_no_animation_only",
	layers = { "standard", "ranked", "no_animation_timer" },
	forced_gamemode = "gamemode_mp_attrition",
}):inject()
