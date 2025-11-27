MP.Ruleset({
	key = "smallworld",
	multiplayer_content = true,
	standard = true,
	banned_silent = { "j_bloodstone", "j_hanging_chad" },
	banned_jokers = {},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	reworked_jokers = {
		"j_mp_hanging_chad",
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		"m_glass",
	},
	reworked_tags = {},
	reworked_blinds = {},
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = true,
			forced_lobby_options = false,
			description_key = "k_smallworld_description",
		})
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
				if k == "Voucher" and not MP.legacy_smallworld() then ii = ii + 1 end
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

local showman_ref = SMODS.showman
function SMODS.showman(card_key)
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" then return true end
	return showman_ref(card_key)
end

-- replace banned tags
local tag_init_ref = Tag.init
function Tag:init(_tag, for_collection, _blind_type)
	local orbital = false
	local old = G.orbital_hand -- i think this is always nil here but just to be safe
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" and not MP.legacy_smallworld() then
		if G.GAME.banned_keys[_tag] and not G.OVERLAY_MENU then
			local a = G.GAME.round_resets.ante

			if MP.should_use_the_order() then G.GAME.round_resets.ante = 10 end

			_tag = get_next_tag_key("replace")
			if _tag == "tag_orbital" then orbital = true end

			G.GAME.round_resets.ante = a
		end
	end
	if orbital then G.orbital_hand = pseudorandom_element(MP.sorted_hand_list(), pseudoseed("orbital_replace")) end
	tag_init_ref(self, _tag, for_collection, _blind_type)
	G.orbital_hand = old
end

local apply_to_run_ref = Back.apply_to_run
function Back:apply_to_run()
	if MP.LOBBY.code and MP.LOBBY.config.ruleset == "ruleset_mp_smallworld" and not MP.legacy_smallworld() then
		MP.apply_fake_back_vouchers(self)
	end
	return apply_to_run_ref(self)
end

function MP.apply_fake_back_vouchers(back)
	local vouchers = {}
	if back.effect.config.voucher then vouchers = { back.effect.config.voucher } end
	if back.effect.config.vouchers or #vouchers > 0 then
		vouchers = back.effect.config.vouchers or vouchers
		local fake_back = { effect = { config = { vouchers = copy_table(vouchers) } } }
		fake_back.effect.center = G.P_CENTERS["b_red"]
		fake_back.name = "FAKE"
		back.effect.config.vouchers = nil
		back.effect.config.voucher = nil
		G.E_MANAGER:add_event(Event({
			func = function()
				for i, v in ipairs(fake_back.effect.config.vouchers) do
					local voucher = v
					if G.GAME.banned_keys[v] or G.GAME.used_vouchers[v] then voucher = get_next_voucher_key() end
					G.GAME.used_vouchers[voucher] = true
					fake_back.effect.config.vouchers[i] = voucher
				end
				G.GAME.current_round.voucher = SMODS.get_next_vouchers() -- the extreme jank doesn't matter as long as it's synced ig
				apply_to_run_ref(fake_back)
				return true
			end,
		}))
	end
end

function MP.legacy_smallworld()
	return MP.LOBBY.code and MP.LOBBY.config and MP.LOBBY.config.legacy_smallworld
end
