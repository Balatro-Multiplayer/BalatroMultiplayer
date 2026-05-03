function MP.UTILS.get_weekly()
	return SMODS.Mods["Multiplayer"].config.weekly
end

-- Base timer in seconds, accounting for the active context's timer_base_multiplier
-- (set by layers like pressure_timer). The multiplier is applied at timer-init sites,
-- so the lobby UI keeps showing the unmultiplied base.
function MP.UTILS.timer_base()
	local base = MP.LOBBY.config.timer_base_seconds or 150
	local mult = MP.current_ruleset and MP.current_ruleset().timer_base_multiplier or 1
	return base * mult
end

-- Base PvP timer in seconds, accounting for the active ruleset's pvp_timer_base_multiplier
-- (set by layers like pvp_timer). The multiplier is applied at timer-init sites,
-- so the lobby UI keeps showing the unmultiplied base.
function MP.UTILS.pvp_timer_base()
    if not MP.is_layer_active("pvp_timer") then return MP.UTILS.timer_base() end
	local base = MP.LOBBY.config.pvp_timer_base_seconds or 90
	local ruleset_key = MP.LOBBY.config.ruleset
	local ruleset = MP.Rulesets and ruleset_key and MP.Rulesets[ruleset_key]
	local mult = (ruleset and ruleset.pvp_timer_base_multiplier) or 1
	return base * mult
end

function MP.UTILS.is_weekly(arg)
	return MP.UTILS.get_weekly() == arg and MP.LOBBY.config.ruleset == "ruleset_mp_weekly"
end

function MP.UTILS.check_smods_version()
	if SMODS.version ~= MP.SMODS_VERSION then
		return localize({ type = "variable", key = "k_ruleset_disabled_smods_version", vars = { MP.SMODS_VERSION } })
	end
	return false
end

function MP.UTILS.check_lovely_version()
	local lovely_ver = SMODS.Mods["Lovely"] and SMODS.Mods["Lovely"].version or ""
	if not lovely_ver:match("^" .. MP.REQUIRED_LOVELY_VERSION:gsub("%.", "%%.")) then
		return localize({
			type = "variable",
			key = "k_ruleset_disabled_lovely_version",
			vars = { MP.REQUIRED_LOVELY_VERSION },
		})
	end
	return false
end
