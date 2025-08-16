MP.Ruleset({ -- just a copy of ranked... and every weekly ruleset in vault is intended to copy paste like this....... maybe this could be more efficient?
	key = "smallworld",
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
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass"
	},
	reworked_tags = {},
	reworked_blinds = {},
	create_info_menu = function ()
		return {
			{
				n = G.UIT.R,
				config = {
					align = "tm"
				},
				nodes = {
					MP.UI.BackgroundGrouping(localize("k_has_multiplayer_content"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_yes"),
								scale = 0.8,
								colour = G.C.GREEN,
							}
						}
					}, {col = true, text_scale = 0.6}),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1
						}
					},
					MP.UI.BackgroundGrouping(localize("k_forces_lobby_options"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							}
						}
					}, {col = true, text_scale = 0.6}),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1
						}
					},
					MP.UI.BackgroundGrouping(localize("k_forces_gamemode"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							}
						}
					}, {col = true, text_scale = 0.6})
				},
			},
			{
				n = G.UIT.R,
				config = {
					minw = 0.05,
					minh = 0.05
				}
			},
			{
				n = G.UIT.R,
				config = {
					align = "cl",
					padding = 0.1
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_smallworld_description"),
							scale = 0.6,
							colour = G.C.UI.TEXT_LIGHT,
						}
					},
				},
			},
		}
	end,
}):inject()

local apply_bans_ref = MP.ApplyBans
function MP.ApplyBans()
	local ret = apply_bans_ref()
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == 'ruleset_mp_smallworld' then
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
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == 'ruleset_mp_smallworld' then
		if name == 'Showman' and not next(find_joker_ref('Showman', non_debuff)) then
			return {{}} -- surely this doesn't break
		end
	end
	return find_joker_ref(name, non_debuff)
end
