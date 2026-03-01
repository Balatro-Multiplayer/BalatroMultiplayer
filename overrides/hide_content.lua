-- small file because it feels wrong to add it somewhere else

function MP.should_hide_mp_content()
	if (not MP.LOBBY.code) or not MP.Rulesets[MP.LOBBY.config.ruleset].multiplayer_content then -- check for vanilla context
		if SMODS.Mods["Multiplayer"].config.hide_mp_content then return true end
	end
	return false
end

local hidden_tbl = { "Stake", "Back" } -- Challenges are at bottom of file

local inject_ref = SMODS.injectItems
function SMODS.injectItems()
	local ret = inject_ref()
	for _, hidden in ipairs(hidden_tbl) do
		G.P_CENTER_POOLS[hidden .. "_non_mp"] = {}
		for i, v in ipairs(G.P_CENTER_POOLS[hidden]) do
			if not v.mod or v.mod.id ~= "Multiplayer" then table.insert(G.P_CENTER_POOLS[hidden .. "_non_mp"], v) end
		end
	end
	G.CHALLENGES_non_mp = {}
	for i, v in ipairs(G.CHALLENGES) do
		if not v.mod or v.mod.id ~= "Multiplayer" then table.insert(G.CHALLENGES_non_mp, v) end
	end
	return ret
end

local function hook(orig, type)
	return function(...)
		local temp = G.P_CENTER_POOLS[type]
		if MP.should_hide_mp_content() then G.P_CENTER_POOLS[type] = G.P_CENTER_POOLS[type .. "_non_mp"] end
		local results = orig(...)
		G.P_CENTER_POOLS[type] = temp
		return results
	end
end

local hooks = {
	Stake = {
		{ tbl = G.UIDEF, str = "deck_stake_column" },
		{ tbl = G.UIDEF, str = "current_stake" },
		{ tbl = G.UIDEF, str = "stake_option" },
		{ tbl = G.UIDEF, str = "run_setup_option" },
	},
	Back = {
		{ tbl = G.UIDEF, str = "run_setup_option" },
		{ tbl = G.FUNCS, str = "change_viewed_back" },
		{ tbl = G.FUNCS, str = "change_selected_back" },
	},
}

for k, v in pairs(hooks) do
	for i, vv in ipairs(v) do
		local orig = vv.tbl[vv.str]
		vv.tbl[vv.str] = hook(orig, k)
	end
end

-- slightly modified exception code for challenges

local ch_hooks = {
	{ tbl = G.UIDEF, str = "challenges" },
	{ tbl = G.UIDEF, str = "challenge_list" },
	{ tbl = G.UIDEF, str = "challenge_list_page" },
}

local function ch_hook(orig)
	return function(...)
		local temp = G.CHALLENGES
		if MP.should_hide_mp_content() then G.CHALLENGES = G.CHALLENGES_non_mp end
		local results = orig(...)
		G.CHALLENGES = temp
		return results
	end
end

for i, v in pairs(ch_hooks) do
	local orig = v.tbl[v.str]
	v.tbl[v.str] = ch_hook(orig)
end
