MP.Ruleset({
	key = "smallworld",
	multiplayer_content = true,
	standard = true,

	banned_jokers = {
		"j_hanging_chad",
		"j_bloodstone",
	},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	reworked_jokers = {
		"j_mp_hanging_chad",
		"j_mp_bloodstone",
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass",
	},
	reworked_tags = {},
	reworked_blinds = {},
	create_info_menu = function()
		return {
			{
				n = G.UIT.R,
				config = {
					align = "tm",
				},
				nodes = {
					MP.UI.BackgroundGrouping(localize("k_has_multiplayer_content"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_yes"),
								scale = 0.8,
								colour = G.C.GREEN,
							},
						},
					}, { col = true, text_scale = 0.6 }),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1,
						},
					},
					MP.UI.BackgroundGrouping(localize("k_forces_lobby_options"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							},
						},
					}, { col = true, text_scale = 0.6 }),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1,
						},
					},
					MP.UI.BackgroundGrouping(localize("k_forces_gamemode"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							},
						},
					}, { col = true, text_scale = 0.6 }),
				},
			},
			{
				n = G.UIT.R,
				config = {
					minw = 0.05,
					minh = 0.05,
				},
			},
			{
				n = G.UIT.R,
				config = {
					align = "cl",
					padding = 0.1,
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_smallworld_description"),
							scale = 0.6,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
		}
	end,
}):inject()

local apply_bans_ref = MP.ApplyBans
function MP.ApplyBans()
	local ret = apply_bans_ref()
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" then
		local tables = {}
		local requires = {}
		for k, v in pairs(G.P_CENTERS) do
			if v.set and not G.GAME.banned_keys[k] and not (v.requires or v.hidden) then
				local index = v.set .. (v.rarity or "")
				tables[index] = tables[index] or {}
				local t = tables[index]
				t[#t + 1] = k
			end
			if v.set == "Voucher" and v.requires then requires[#requires + 1] = k end
		end
		for k, v in pairs(G.P_TAGS) do -- tag exemption
			if not G.GAME.banned_keys[k] then
				tables["Tag"] = tables["Tag"] or {}
				local t = tables["Tag"]
				t[#t + 1] = k
			end
		end
		for k, v in pairs(tables) do
			if k ~= "Back" and k ~= "Edition" and k ~= "Enhanced" and k ~= "Default" then
				table.sort(v)
				pseudoshuffle(v, pseudoseed(k .. "_mp_smallworld"))
				local threshold = math.floor(0.5 + (#v * 0.75))
				local ii = 1
				for i, vv in ipairs(v) do
					if ii <= threshold then
						G.GAME.banned_keys[vv] = true
						ii = ii + 1
					else
						break
					end
				end
			end
		end
		for i, v in ipairs(requires) do
			if G.GAME.banned_keys[G.P_CENTERS[v].requires[1]] then G.GAME.banned_keys[v] = true end
		end
	end
	return ret
end

local find_joker_ref = find_joker
function find_joker(name, non_debuff)
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" then
		if name == "Showman" and not next(find_joker_ref("Showman", non_debuff)) then
			return { {} } -- surely this doesn't break
		end
	end
	return find_joker_ref(name, non_debuff)
end

-- replace banned tags
local tag_init_ref = Tag.init
function Tag:init(_tag, for_collection, _blind_type)
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" then
		if G.GAME.banned_keys[_tag] then
			local a = G.GAME.round_resets.ante
			if MP.should_use_the_order() then G.GAME.round_resets.ante = 0 end
			_tag = get_next_tag_key("replace")
			G.GAME.round_resets.ante = a
		end
	end
	tag_init_ref(self, _tag, for_collection, _blind_type)
end

-- spaghetti that's meant to randomize banned vouchers but cocktail is too fucked up to work with this rn
--[[
local apply_to_run_ref = Back.apply_to_run
function Back:apply_to_run()
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" then
		if self.effect.config.voucher then
			G.E_MANAGER:add_event(Event({
				func = function()
					for k, v in pairs(G.GAME.current_round.voucher.spawn) do
						G.GAME.banned_keys[k] = true
					end
					if G.GAME.banned_keys[self.effect.config.voucher] and not G.GAME.current_round.voucher.spawn[v] then
						self.effect.config.voucher = get_next_voucher_key()
					end
					G.GAME.used_vouchers[self.effect.config.voucher] = true
					for k, v in pairs(G.GAME.current_round.voucher.spawn) do
						G.GAME.banned_keys[k] = nil
					end
					apply_to_run_ref(self)
					return true
				end,
			}))
			return
		elseif self.effect.config.vouchers or self.effect.center.key == "b_mp_cocktail" then
			G.E_MANAGER:add_event(Event({
				func = function()
					for k, v in pairs(G.GAME.current_round.voucher.spawn) do
						G.GAME.banned_keys[k] = true
					end
					if self.effect.config.vouchers then
						for i, v in ipairs(self.effect.config.vouchers) do
							if G.GAME.banned_keys[v] and not G.GAME.current_round.voucher.spawn[v] then
								self.effect.config.vouchers[i] = get_next_voucher_key()
							end
							G.GAME.used_vouchers[ self.effect.config.vouchers[i] ] = true
						end
					end
					for k, v in pairs(G.GAME.current_round.voucher.spawn) do
						G.GAME.banned_keys[k] = nil
					end
					apply_to_run_ref(self)
					return true
				end,
			}))
			return
		end
	end
	return apply_to_run_ref(self)
end
]]
