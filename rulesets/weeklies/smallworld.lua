MP.Ruleset({ -- just a copy of ranked... and every weekly ruleset in vault is intended to copy paste like this....... maybe this could be more efficient?
	key = "weekly",
	multiplayer_content = true,
	standard = true,

	banned_jokers = {},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds ={},
	reworked_jokers = {
		"j_hanging_chad",
		"j_mp_conjoined_joker",
		"j_mp_defensive_joker",
		"j_mp_lets_go_gambling",
		"j_mp_pacifist",
		"j_mp_penny_pincher",
		"j_mp_pizza",
		"j_mp_skip_off",
		"j_mp_speedrun",
		"j_mp_taxes",
	},
	reworked_consumables = {
		"c_mp_asteroid"
	},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass"
	},
	reworked_tags = {},
	reworked_blinds = {
		"bl_mp_nemesis"
	},
	create_info_menu = function ()
		return {{
			n = G.UIT.R,
			config = {
				align = "tm"
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = MP.UTILS.wrapText(localize("k_weekly_description") .. localize("k_weekly_smallworld"), 100),
						scale = 0.4,
						colour = G.C.UI.TEXT_LIGHT,
					}
				}
			}
		}}
	end,
	forced_gamemode = "gamemode_mp_attrition",
	forced_lobby_options = true,
	is_disabled = function(self)
		local required_version = "1.0.0~BETA-0506a"
		if SMODS.version ~= required_version then
			return localize({type = "variable", key="k_ruleset_disabled_smods_version", vars = {required_version}})
		end
		if not MP.INTEGRATIONS.TheOrder then
			return localize("k_ruleset_disabled_the_order_required")
		end
		return false
	end
}):inject()

local apply_bans_ref = MP.ApplyBans
function MP.ApplyBans()
	local ret = apply_bans_ref()
	if MP.LOBBY.code and MP.UTILS.is_weekly('smallworld') then
		local tables = {}
		for k, v in pairs(G.P_CENTERS) do
			if v.set and (not G.GAME.banned_keys[k]) and not (v.requires or v.hidden) then
				local index = v.set..(v.rarity or '')
				tables[index] = tables[index] or {}
				local t = tables[index]
				t[#t+1] = k
			end
		end
		for k, v in pairs(G.P_TAGS) do -- tag exemption
			if not G.GAME.banned_keys[k] then
				tables['Tag'] = tables['Tag'] or {}
				local t = tables['Tag']
				t[#t+1] = k
			end
		end
		for k, v in pairs(tables) do
			if k ~= "Back"
			and k ~= "Edition"
			and k ~= "Enhanced"
			and k ~= "Default" then
				table.sort(v)
				pseudoshuffle(v, pseudoseed(k..'_mp_smallworld'))
				local threshold = math.floor( 0.5 + (#v*0.75) )
				local ii = 1
				for i, vv in ipairs(v) do
					if ii <= threshold then
						G.GAME.banned_keys[vv] = true
						ii = ii + 1
					else break end
				end
			end
		end
	end
	return ret
end

local find_joker_ref = find_joker
function find_joker(name, non_debuff)
	if MP.LOBBY.code and MP.UTILS.is_weekly('smallworld') then
		if name == 'Showman' and not next(find_joker_ref('Showman', non_debuff)) then
			return {{}} -- surely this doesn't break
		end
	end
	return find_joker_ref(name, non_debuff)
end
