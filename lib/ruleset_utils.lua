function MP.UTILS.get_standard_rulesets(add)
	local ret = {}
	for k, v in pairs(MP.Rulesets) do
		if v.standard then ret[#ret + 1] = string.sub(v.key, 12, #v.key) end
	end
	if add then
		if type(add) == "string" then add = { add } end
		for i, v in ipairs(add) do
			ret[#ret + 1] = v
		end
	end
	return ret
end

function MP.UTILS.is_standard_ruleset()
	local active = MP.get_active_ruleset()
	if active == nil then return false end
	for _, ruleset in ipairs(MP.UTILS.get_standard_rulesets()) do
		if active == "ruleset_mp_" .. ruleset then return true end
	end
	return false
end

function MP.UTILS.get_weekly()
	return SMODS.Mods["Multiplayer"].config.weekly
end

function MP.UTILS.is_weekly(arg)
	return MP.UTILS.get_weekly() == arg and MP.LOBBY.config.ruleset == "ruleset_mp_weekly"
end
