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

MP.Ruleset({
	key = "experimental_pvp_timer",
	layers = { "standard", "ranked", "pvp_timer" },
	forced_gamemode = "gamemode_mp_attrition",
}):inject()

-- TODO: instead of forking experimental into N rulesets per timer/balance combo,
-- expose toggles in lobby options (e.g. timer variant: pressure | no_animation,
-- experimental balance: on | off) and let one ruleset cover the matrix.
