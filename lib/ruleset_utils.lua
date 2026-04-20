function MP.UTILS.get_weekly()
	return SMODS.Mods["Multiplayer"].config.weekly
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
